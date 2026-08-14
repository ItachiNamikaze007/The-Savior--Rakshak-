import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/emergency_type.dart';
import '../../domain/entities/sos_request.dart';
import '../../domain/entities/sos_status.dart';
import '../../domain/repositories/i_sos_repository.dart';

class SosStateNotifier extends ChangeNotifier {
  final ISosRepository _sosRepository;
  final LocationService _locationService;

  SosStateNotifier({
    required ISosRepository sosRepository,
    required LocationService locationService,
  })  : _sosRepository = sosRepository,
        _locationService = locationService {
    // Automatically attempt to fetch GPS fix on startup
    fetchLocation();
  }

  // Location State
  LocationData? _currentLocation;
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

  Future<void> fetchLocation({bool? overrideSimulated}) async {
    _isLoadingLocation = true;
    _locationErrorMessage = null;
    _locationErrorCode = null;
    notifyListeners();

    final useSimulated = overrideSimulated ?? _isSimulatedMode;

    try {
      final loc = await _locationService.getCurrentLocation(forceSimulated: useSimulated);
      _currentLocation = loc;
      _isLoadingLocation = false;
      notifyListeners();
    } on LocationException catch (e) {
      _isLoadingLocation = false;
      _locationErrorMessage = e.message;
      _locationErrorCode = e.code;
      notifyListeners();
    } catch (e) {
      _isLoadingLocation = false;
      _locationErrorMessage = 'Failed to fetch GPS coordinates: $e';
      _locationErrorCode = LocationErrorCode.unknown;
      notifyListeners();
    }
  }

  void toggleSimulatedMode(bool value) {
    _isSimulatedMode = value;
    fetchLocation(overrideSimulated: value);
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

  SosRequest createSosPayload() {
    final now = DateTime.now();
    final generatedId = IdGenerator.generateSosId(timestamp: now);
    final lat = _currentLocation?.latitude ?? 0.0;
    final lng = _currentLocation?.longitude ?? 0.0;
    final accuracy = _currentLocation?.accuracy ?? 0.0;

    return SosRequest(
      sosId: generatedId,
      timestamp: now,
      latitude: lat,
      longitude: lng,
      accuracy: accuracy,
      emergencyType: _selectedEmergencyType,
      peopleCount: _peopleCount,
      injuredCount: _injuredCount,
      status: SosStatus.pending,
      isSimulatedGps: _currentLocation?.isSimulated ?? _isSimulatedMode,
    );
  }

  Future<SosRequest> dispatchDistressSignal() async {
    _isDispatching = true;
    _dispatchErrorMessage = null;
    notifyListeners();

    try {
      final payload = createSosPayload();
      _activeSos = payload;

      // Subscribe to real-time status updates from repository
      _statusSubscription?.cancel();
      _statusSubscription = _sosRepository.watchSosStatus(payload.sosId).listen((updatedSos) {
        _activeSos = updatedSos;
        notifyListeners();
      });

      final dispatched = await _sosRepository.dispatchSos(payload);
      _activeSos = dispatched;
      _isDispatching = false;
      notifyListeners();
      return dispatched;
    } catch (e) {
      _isDispatching = false;
      _dispatchErrorMessage = 'Failed to transmit distress signal: $e';
      notifyListeners();
      rethrow;
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
