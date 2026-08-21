import 'package:flutter_test/flutter_test.dart';
import 'package:sosquad/core/services/mesh/emergency_mesh_packet.dart';
import 'package:sosquad/features/sos/domain/entities/emergency_type.dart';
import 'package:sosquad/features/sos/domain/entities/sos_request.dart';
import 'package:sosquad/features/sos/domain/entities/sos_status.dart';

void main() {
  group('EmergencyMeshPacket Tests', () {
    test('Encodes and decodes accurately over JSON/BLE wire format', () {
      final req = SosRequest(
        sosId: 'SOS_FIELD_999',
        timestamp: DateTime.now(),
        latitude: 28.5355,
        longitude: 77.3910,
        accuracy: 4.2,
        emergencyType: EmergencyType.flood,
        peopleCount: 4,
        injuredCount: 2,
        status: SosStatus.transmitting,
        deviceId: 'NODE-AND-01',
      );

      final packet = EmergencyMeshPacket.fromSosRequest(req, maxTtl: 7);
      expect(packet.hopCount, equals(0));
      expect(packet.ttl, equals(7));
      expect(packet.originDeviceId, equals('NODE-AND-01'));
      expect(packet.peopleCount, equals(4));
      expect(packet.injuredCount, equals(2));

      final serialized = packet.encode();
      final decoded = EmergencyMeshPacket.decode(serialized);

      expect(decoded.packetId, equals(packet.packetId));
      expect(decoded.latitude, closeTo(28.5355, 0.0001));
      expect(decoded.longitude, closeTo(77.3910, 0.0001));
      expect(decoded.emergencyType, equals(EmergencyType.flood));
      expect(decoded.hopCount, equals(0));
      expect(decoded.ttl, equals(7));
    });

    test('Relay copy increments hops, decrements TTL, and appends relay node audit trail', () {
      final original = EmergencyMeshPacket(
        packetId: 'PKT_ABC_123',
        originDeviceId: 'NODE-AND-01',
        latitude: 19.0760,
        longitude: 72.8777,
        accuracy: 3.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        emergencyType: EmergencyType.fire,
        peopleCount: 2,
        injuredCount: 0,
        hopCount: 0,
        ttl: 5,
        relayedByNodes: ['NODE-AND-01'],
      );

      final hop1 = original.createRelayCopy('NODE-AND-02');
      expect(hop1.hopCount, equals(1));
      expect(hop1.ttl, equals(4));
      expect(hop1.relayedByNodes, containsAll(['NODE-AND-01', 'NODE-AND-02']));

      final hop2 = hop1.createRelayCopy('GW-DELHI-01');
      expect(hop2.hopCount, equals(2));
      expect(hop2.ttl, equals(3));
      expect(hop2.relayedByNodes, containsAll(['NODE-AND-01', 'NODE-AND-02', 'GW-DELHI-01']));
    });
  });
}
