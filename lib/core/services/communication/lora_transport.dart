import 'dart:async';
import '../../../features/sos/domain/entities/sos_request.dart';
import 'transport.dart';

/// LoRa Mesh Transport Implementation (Future Hardware Allocation).
///
/// Reserved for offline mesh communications via LoRa 433/868/915 MHz UART/BLE radio modules.
/// Currently marked as [isAvailable = false] with explicit integration status.
class LoRaTransport implements ITransport {
  final StreamController<bool> _availabilityController =
      StreamController<bool>.broadcast();

  final bool _isHardwareIntegrated = false;

  @override
  TransportType get type => TransportType.loraMesh;

  @override
  bool get isAvailable => _isHardwareIntegrated;

  @override
  String get statusDescription =>
      'LoRa Mesh — Ready for Integration (Hardware Integration Pending)';

  @override
  Stream<bool> get availabilityStream => _availabilityController.stream;

  @override
  Future<bool> sendSos(SosRequest request) async {
    // When LoRa hardware module is plugged in, radio packet framing occurs here.
    if (!_isHardwareIntegrated) {
      return false; // Hardware not attached yet; triggers offline queue fallback
    }
    return true;
  }

  void dispose() {
    _availabilityController.close();
  }
}
