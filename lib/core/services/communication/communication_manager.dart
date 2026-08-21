import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../features/sos/domain/entities/emergency_type.dart';
import '../../../features/sos/domain/entities/sos_request.dart';
import '../../../features/sos/domain/entities/sos_status.dart';
import '../../../features/sos/domain/repositories/i_sos_repository.dart';
import 'ble_mesh_transport.dart';
import 'internet_transport.dart';
import 'lora_transport.dart';
import 'network_connectivity_service.dart';
import 'offline_message_queue.dart';
import 'pending_message.dart';
import 'transport.dart';

class CommunicationManager extends ChangeNotifier {
  final ISosRepository _repository;
  final InternetTransport _internetTransport;
  final BleMeshTransport _bleMeshTransport;
  final LoRaTransport _loraTransport;
  final OfflineMessageQueue _offlineQueue;
  final NetworkConnectivityService _networkService;

  CommunicationMode _mode = CommunicationMode.hybrid;
  String _activeRelayStatus = 'System Ready';

  CommunicationManager({
    required ISosRepository repository,
    BleMeshTransport? bleMeshTransport,
    LoRaTransport? loraTransport,
    OfflineMessageQueue? offlineQueue,
    NetworkConnectivityService? networkService,
  })  : _repository = repository,
        _internetTransport = InternetTransport(repository: repository),
        _bleMeshTransport = bleMeshTransport ??
            BleMeshTransport(cloudRepository: repository),
        _loraTransport = loraTransport ?? LoRaTransport(),
        _offlineQueue = offlineQueue ?? OfflineMessageQueue(),
        _networkService = networkService ?? NetworkConnectivityService() {
    // Listen to transports
    _internetTransport.availabilityStream.listen((_) => _onConnectivityChanged());
    _bleMeshTransport.availabilityStream.listen((_) => notifyListeners());
    _loraTransport.availabilityStream.listen((_) => notifyListeners());
    _offlineQueue.queueStream.listen((_) => notifyListeners());

    // Listen to automatic network reachability changes
    _networkService.onStatusChange.listen((status) {
      final isOnline = status == NetworkStatus.online;
      _internetTransport.setOnlineStatus(isOnline);
      _bleMeshTransport.setLocalGatewayStatus(isOnline);
      _onConnectivityChanged();
    });

    // Listen to mesh logs
    _bleMeshTransport.logStream.listen((log) {
      _activeRelayStatus = log.message;
      notifyListeners();
    });

    // Initialize local gateway state based on initial connectivity
    _bleMeshTransport.setLocalGatewayStatus(_internetTransport.isAvailable);
  }

  // Getters
  CommunicationMode get mode => _mode;
  InternetTransport get internetTransport => _internetTransport;
  BleMeshTransport get bleMeshTransport => _bleMeshTransport;
  LoRaTransport get loraTransport => _loraTransport;
  OfflineMessageQueue get offlineQueue => _offlineQueue;
  NetworkConnectivityService get networkService => _networkService;

  bool get isInternetAvailable => _internetTransport.isAvailable;
  bool get isBleMeshAvailable => _bleMeshTransport.isAvailable;
  bool get isLoraAvailable => _loraTransport.isAvailable;
  int get queuedMessagesCount => _offlineQueue.queueSize;
  String get activeRelayStatus => _activeRelayStatus;

  String get activePrimaryTransportLabel => isInternetAvailable
      ? 'Internet / Cloud (DIRECT)'
      : 'BLE Mobile Mesh (OFFLINE MULTI-HOP)';

  String get activeSecondaryTransportLabel => isLoraAvailable
      ? 'LoRa Mesh (RADIO BACKUP)'
      : 'Store-and-Forward (DTN QUEUE)';

  void setCommunicationMode(CommunicationMode newMode) {
    _mode = newMode;
    notifyListeners();
  }

  void _onConnectivityChanged() {
    if (isInternetAvailable) {
      // Automatic Reconnection Sync: Flush offline queued messages to cloud
      _flushOfflineQueue();
    }
    notifyListeners();
  }

  Future<void> _flushOfflineQueue() async {
    if (_offlineQueue.queueSize == 0 || !isInternetAvailable) return;

    final pending = List<PendingMessage>.from(_offlineQueue.pendingMessages);
    for (final message in pending) {
      try {
        final payload = message.payload;
        final sosReq = SosRequest(
          sosId: payload['sosId'] as String,
          timestamp: DateTime.tryParse(payload['timestamp'] as String? ?? '') ?? DateTime.now(),
          latitude: (payload['latitude'] as num).toDouble(),
          longitude: (payload['longitude'] as num).toDouble(),
          accuracy: (payload['accuracy'] as num?)?.toDouble() ?? 0.0,
          emergencyType: EmergencyType.values.firstWhere(
            (e) => e.name == payload['emergencyType'],
            orElse: () => EmergencyType.other,
          ),
          peopleCount: payload['peopleCount'] as int? ?? 1,
          injuredCount: payload['injuredCount'] as int? ?? 0,
          status: SosStatus.values.firstWhere(
            (s) => s.name == payload['status'],
            orElse: () => SosStatus.transmitting,
          ),
          deviceId: payload['deviceId'] as String? ?? 'NODE-AND-01',
        );

        await _repository.dispatchSos(sosReq);
        _offlineQueue.markDelivered(message.id);
      } catch (e) {
        _offlineQueue.markFailed(message.id, e.toString());
      }
    }
  }

  /// Dispatches an SOS beacon using intelligent fallback:
  /// 1. If Internet is available -> Dispatch directly to Cloud Firestore / HQ
  /// 2. If Internet is down / offline -> Automatically broadcast through BLE Mobile Mesh (Multi-hop relay)
  /// 3. If hardware LoRa is available -> Broadcast over LoRa radio
  /// 4. Store-and-Forward: Enqueue into OfflineMessageQueue to guarantee zero data loss
  Future<bool> dispatchEmergencySignal(SosRequest request) async {
    bool delivered = false;

    if (_mode == CommunicationMode.loraOnly) {
      delivered = await _loraTransport.sendSos(request);
    } else if (_mode == CommunicationMode.internetOnly) {
      delivered = await _internetTransport.sendSos(request);
    } else if (_mode == CommunicationMode.meshOnly) {
      delivered = await _bleMeshTransport.sendSos(request);
    } else {
      // Smart Hybrid Auto-Failover:
      if (_internetTransport.isAvailable) {
        delivered = await _internetTransport.sendSos(request);
      }

      // If internet failed or offline, trigger automatic BLE Mesh Multi-Hop
      if (!delivered && _bleMeshTransport.isAvailable) {
        delivered = await _bleMeshTransport.sendSos(request);
      }

      // If LoRa hardware attached, broadcast as well
      if (_loraTransport.isAvailable) {
        await _loraTransport.sendSos(request);
      }
    }

    // If zero immediate direct connection, save in Store-and-Forward DTN queue
    if (!isInternetAvailable) {
      _offlineQueue.enqueue(
        PendingMessage(
          id: request.sosId,
          type: 'SOS_DISPATCH',
          payload: {
            'sosId': request.sosId,
            'timestamp': request.timestamp.toIso8601String(),
            'latitude': request.latitude,
            'longitude': request.longitude,
            'accuracy': request.accuracy,
            'emergencyType': request.emergencyType.name,
            'peopleCount': request.peopleCount,
            'injuredCount': request.injuredCount,
            'status': request.status.name,
            'deviceId': request.deviceId,
          },
          createdAt: DateTime.now(),
          priority: MessagePriority.critical,
        ),
      );
    }

    return delivered;
  }

  @override
  void dispose() {
    _internetTransport.dispose();
    _bleMeshTransport.dispose();
    _loraTransport.dispose();
    _offlineQueue.dispose();
    _networkService.dispose();
    super.dispose();
  }
}
