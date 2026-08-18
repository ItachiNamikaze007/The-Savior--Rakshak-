import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../features/sos/domain/entities/sos_request.dart';
import '../../../features/sos/domain/repositories/i_sos_repository.dart';
import 'internet_transport.dart';
import 'lora_transport.dart';
import 'offline_message_queue.dart';
import 'pending_message.dart';
import 'transport.dart';

class CommunicationManager extends ChangeNotifier {
  final InternetTransport _internetTransport;
  final LoRaTransport _loraTransport;
  final OfflineMessageQueue _offlineQueue;

  CommunicationMode _mode = CommunicationMode.hybrid;

  CommunicationManager({
    required ISosRepository repository,
    OfflineMessageQueue? offlineQueue,
  })  : _internetTransport = InternetTransport(repository: repository),
        _loraTransport = LoRaTransport(),
        _offlineQueue = offlineQueue ?? OfflineMessageQueue() {
    _internetTransport.availabilityStream.listen((_) => notifyListeners());
    _loraTransport.availabilityStream.listen((_) => notifyListeners());
    _offlineQueue.queueStream.listen((_) => notifyListeners());
  }

  // Getters
  CommunicationMode get mode => _mode;
  InternetTransport get internetTransport => _internetTransport;
  LoRaTransport get loraTransport => _loraTransport;
  OfflineMessageQueue get offlineQueue => _offlineQueue;

  bool get isInternetAvailable => _internetTransport.isAvailable;
  bool get isLoraAvailable => _loraTransport.isAvailable;
  int get queuedMessagesCount => _offlineQueue.queueSize;

  String get activePrimaryTransportLabel => 'LoRa Mesh (PRIMARY)';
  String get activeSecondaryTransportLabel => 'Internet / Cloud (SECONDARY)';

  void setCommunicationMode(CommunicationMode newMode) {
    _mode = newMode;
    notifyListeners();
  }

  /// Dispatches an SOS beacon using the layered fallback transport:
  /// 1. Try LoRa Mesh (if available/hardware attached)
  /// 2. Try Internet / Cloud Firestore
  /// 3. If both unavailable, enqueue into OfflineMessageQueue for automated sync
  Future<bool> dispatchEmergencySignal(SosRequest request) async {
    bool delivered = false;

    if (_mode == CommunicationMode.loraOnly) {
      delivered = await _loraTransport.sendSos(request);
    } else if (_mode == CommunicationMode.internetOnly) {
      delivered = await _internetTransport.sendSos(request);
    } else {
      // Hybrid Mode: Preferred LoRa Mesh first, then Internet
      if (_loraTransport.isAvailable) {
        delivered = await _loraTransport.sendSos(request);
      }
      if (!delivered && _internetTransport.isAvailable) {
        delivered = await _internetTransport.sendSos(request);
      }
    }

    if (!delivered) {
      // Enqueue to offline buffer
      _offlineQueue.enqueue(
        PendingMessage(
          id: request.sosId,
          type: 'SOS_DISPATCH',
          payload: {
            'sosId': request.sosId,
            'timestamp': request.timestamp.toIso8601String(),
            'latitude': request.latitude,
            'longitude': request.longitude,
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
    _loraTransport.dispose();
    _offlineQueue.dispose();
    super.dispose();
  }
}
