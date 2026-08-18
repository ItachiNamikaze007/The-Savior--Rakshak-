import 'dart:async';
import '../../../features/sos/domain/entities/sos_request.dart';
import '../../../features/sos/domain/repositories/i_sos_repository.dart';
import 'transport.dart';

class InternetTransport implements ITransport {
  final ISosRepository _repository;
  final StreamController<bool> _availabilityController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;

  InternetTransport({required ISosRepository repository})
      : _repository = repository;

  @override
  TransportType get type => TransportType.internet;

  @override
  bool get isAvailable => _isOnline;

  @override
  String get statusDescription =>
      _isOnline ? 'Online (Firebase Cloud Active)' : 'Offline (No Internet)';

  @override
  Stream<bool> get availabilityStream => _availabilityController.stream;

  void setOnlineStatus(bool online) {
    _isOnline = online;
    _availabilityController.add(_isOnline);
  }

  @override
  Future<bool> sendSos(SosRequest request) async {
    try {
      await _repository.dispatchSos(request);
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _availabilityController.close();
  }
}
