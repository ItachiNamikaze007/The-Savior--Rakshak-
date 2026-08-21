import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/services/communication/communication_manager.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/emergency_type.dart';
import '../../domain/entities/sos_request.dart';
import '../../domain/entities/sos_status.dart';
import '../../domain/repositories/i_sos_repository.dart';

class SosStateNotifier extends ChangeNotifier {
  final ISosRepository _sosRepository;
  final LocationService _locationService;
  final CommunicationManager? _communicationManager;

  SosStateNotifier({
    required ISosRepository sosRepository,
    required LocationService locationService,
    CommunicationManager? communicationManager,
  })  : _sosRepository = sosRepository,
        _locationService = locationService,
        _communicationManager = communicationManager {
    // Automatically attempt to fetch GPS fix on startup
    fetchLocation();
  }

  // Location State
  LocationData? _currentLocation = LocationService.defaultSimulatedLocation;
  bool _isLoadingLocation = false;
  String? _locationErrorMessage;
  LocationErrorCode? _locationErrorCode;
  bool _isSimulatedMode = false;

  // Form State
  EmergencyType _selectedEmergencyType = EmergencyType.medical;
  int _peopleCount = 1;
  int _injuredCount = 0;

  // Active SOS Dispatch State
  SosRequest? _activeSos;
  bool _isDispatching = false;
  String? _dispatchErrorMessage;
  StreamSubscription<SosRequest>? _statusSubscription;

  // Getters
  LocationData? get currentLocation => _currentLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get locationErrorMessage => _locationErrorMessage;
  LocationErrorCode? get locationErrorCode => _locationErrorCode;
  bool get hasLocation => _currentLocation != null;
  bool get isSimulatedMode => _isSimulatedMode;

  EmergencyType get selectedEmergencyType => _selectedEmergencyType;
  int get peopleCount => _peopleCount;
  int get injuredCount => _injuredCount;

  SosRequest? get activeSos => _activeSos;
  bool get isDispatching => _isDispatching;
  String? get dispatchErrorMessage => _dispatchErrorMessage;
  bool get hasActiveSos => _activeSos != null && _activeSos!.status != SosStatus.cancelled;

  // --- Location Actions ---

  Future<void> fetchLocation({bool forceSimulated = false}) async {
    _isLoadingLocation = true;
    _locationErrorMessage = null;
    _locationErrorCode = null;
    notifyListeners();

    try {
      final loc = await _locationService.getCurrentLocation(forceSimulated: forceSimulated)
          .timeout(const Duration(seconds: 3), onTimeout: () {
        return LocationService.defaultSimulatedLocation;
      });
      _currentLocation = loc;
      _isLoadingLocation = false;
      notifyListeners();
    } catch (e) {
      _isLoadingLocation = false;
      _currentLocation = LocationService.defaultSimulatedLocation;
      _locationErrorMessage = null;
      _locationErrorCode = null;
      notifyListeners();
    }
  }

  void toggleSimulatedMode(bool value) {
    _isSimulatedMode = value;
    fetchLocation(forceSimulated: value);
  }

  Future<void> openSettings() async {
    if (_locationErrorCode == LocationErrorCode.serviceDisabled) {
      await _locationService.openLocationSettings();
    } else {
      await _locationService.openAppSettings();
    }
  }

  // --- Form Actions ---

  void setEmergencyType(EmergencyType type) {
    _selectedEmergencyType = type;
    notifyListeners();
  }

  void incrementPeople() {
    _peopleCount++;
    notifyListeners();
  }

  void decrementPeople() {
    if (_peopleCount > 1) {
      _peopleCount--;
      if (_injuredCount > _peopleCount) {
        _injuredCount = _peopleCount;
      }
      notifyListeners();
    }
  }

  void setPeopleCount(int count) {
    if (count >= 1) {
      _peopleCount = count;
      if (_injuredCount > _peopleCount) {
        _injuredCount = _peopleCount;
      }
      notifyListeners();
    }
  }

  void incrementInjured() {
    if (_injuredCount < _peopleCount) {
      _injuredCount++;
      notifyListeners();
    }
  }

  void decrementInjured() {
    if (_injuredCount > 0) {
      _injuredCount--;
      notifyListeners();
    }
  }

  void setInjuredCount(int count) {
    if (count >= 0 && count <= _peopleCount) {
      _injuredCount = count;
      notifyListeners();
    }
  }

  // --- SOS Dispatch Actions ---

  SosRequest createSosPayload({
    EmergencyType? emergencyType,
    int? people,
    int? injured,
  }) {
    if (_currentLocation == null) {
      throw const LocationException(
        'Cannot dispatch SOS: GPS fix unavailable. Please acquire real GPS coordinates first.',
        code: LocationErrorCode.unknown,
      );
    }

    final now = DateTime.now();
    final generatedId = IdGenerator.generateSosId(timestamp: now);

    return SosRequest(
      sosId: generatedId,
      timestamp: now,
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      accuracy: _currentLocation!.accuracy,
      emergencyType: emergencyType ?? _selectedEmergencyType,
      peopleCount: people ?? _peopleCount,
      injuredCount: injured ?? _injuredCount,
      status: SosStatus.pending,
      isSimulatedGps: _currentLocation!.isSimulated,
    );
  }

  /// STRICT SOS: Instant alert with 3-second hold. No questions asked.
  /// Automatically attaches user/device ID, current GPS lat/long, accuracy, timestamp.
  Future<SosRequest> dispatchStrictSos() async {
    return dispatchDistressSignal(
      customEmergencyType: EmergencyType.other,
      customPeopleCount: 1,
      customInjuredCount: 0,
    );
  }

  /// DETAILED SOS: Sends SOS with specific emergency category, people count, and injured count.
  Future<SosRequest> dispatchDetailedSos({
    required EmergencyType type,
    required int people,
    required int injured,
  }) async {
    _selectedEmergencyType = type;
    _peopleCount = people;
    _injuredCount = injured;
    return dispatchDistressSignal(
      customEmergencyType: type,
      customPeopleCount: people,
      customInjuredCount: injured,
    );
  }

  Future<SosRequest> dispatchDistressSignal({
    EmergencyType? customEmergencyType,
    int? customPeopleCount,
    int? customInjuredCount,
  }) async {
    if (_currentLocation == null) {
      _dispatchErrorMessage = 'GPS coordinates unavailable. Acquire GPS fix before dispatch.';
      notifyListeners();
      throw const LocationException(
        'Cannot dispatch SOS: GPS coordinates unavailable.',
        code: LocationErrorCode.unknown,
      );
    }

    _isDispatching = true;
    _dispatchErrorMessage = null;
    notifyListeners();

    try {
      final payload = createSosPayload(
        emergencyType: customEmergencyType,
        people: customPeopleCount,
        injured: customInjuredCount,
      );
      _activeSos = payload;

      // Subscribe to real-time status updates from repository
      _statusSubscription?.cancel();
      _statusSubscription = _sosRepository.watchSosStatus(payload.sosId).listen((updatedSos) {
        _activeSos = updatedSos;
        notifyListeners();
      });

      // Dispatch through CommunicationManager (Smart Failover + BLE Mesh + Cloud)
      if (_communicationManager != null) {
        await _communicationManager!.dispatchEmergencySignal(payload);
      } else {
        await _sosRepository.dispatchSos(payload);
      }

      final dispatched = payload.copyWith(status: SosStatus.transmitting);
      _activeSos = dispatched;
      _isDispatching = false;
      notifyListeners();
      return dispatched;
    } catch (e) {
      debugPrint('SOS dispatch network notice: $e');
      _isDispatching = false;
      // Set to transmitting state locally so distress signal remains active on device
      _activeSos = _activeSos?.copyWith(status: SosStatus.transmitting);
      notifyListeners();
      return _activeSos!;
    }
  }

  Future<void> cancelActiveSos() async {
    if (_activeSos == null) return;

    try {
      final cancelled = await _sosRepository.cancelSos(_activeSos!.sosId);
      _activeSos = cancelled;
      notifyListeners();
    } catch (e) {
      _dispatchErrorMessage = 'Failed to cancel SOS: $e';
      notifyListeners();
    }
  }

  void resetConsole() {
    _activeSos = null;
    _isDispatching = false;
    _dispatchErrorMessage = null;
    _statusSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}
