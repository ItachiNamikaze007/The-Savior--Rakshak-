import '../../../features/sos/domain/entities/sos_request.dart';

enum CommunicationMode {
  hybrid('HYBRID (LoRa + Cloud)'),
  loraOnly('LoRa MESH ONLY (Offline)'),
  internetOnly('INTERNET ONLY (Cloud)');

  final String label;
  const CommunicationMode(this.label);
}

enum TransportType {
  internet('Internet / Cloud Firestore'),
  loraMesh('LoRa Mesh (Hardware)');

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
