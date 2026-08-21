import '../../../features/sos/domain/entities/sos_request.dart';

enum CommunicationMode {
  hybrid('SMART AUTO-FAILOVER (Cloud + BLE Mesh)'),
  meshOnly('BLE MESH ONLY (Offline Multi-Hop)'),
  loraOnly('LoRa MESH ONLY (Hardware Radio)'),
  internetOnly('INTERNET ONLY (Cloud Firestore)');

  final String label;
  const CommunicationMode(this.label);
}

enum TransportType {
  internet('Internet / Cloud Firestore'),
  bleMesh('BLE Mobile Mesh (Zero Internet Multi-Hop)'),
  loraMesh('LoRa Mesh (Hardware Radio)');

  final String displayName;
  const TransportType(this.displayName);
}

abstract class ITransport {
  TransportType get type;
  bool get isAvailable;
  String get statusDescription;
  Stream<bool> get availabilityStream;

  Future<bool> sendSos(SosRequest request);
}
