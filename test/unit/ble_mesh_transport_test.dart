import 'package:flutter_test/flutter_test.dart';
import 'package:sosquad/core/services/communication/ble_mesh_transport.dart';
import 'package:sosquad/core/services/mesh/emergency_mesh_packet.dart';
import 'package:sosquad/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:sosquad/features/sos/domain/entities/emergency_type.dart';
import 'package:sosquad/features/sos/domain/entities/sos_request.dart';
import 'package:sosquad/features/sos/domain/entities/sos_status.dart';

void main() {
  group('BleMeshTransport Engine Tests', () {
    late SosRepositoryImpl repo;
    late BleMeshTransport transport;

    setUp(() {
      repo = SosRepositoryImpl();
      transport = BleMeshTransport(
        localNodeId: 'NODE-AND-01',
        cloudRepository: repo,
      );
    });

    tearDown(() {
      transport.dispose();
      repo.dispose();
    });

    test('sendSos broadcasts packet, records TX telemetry and initial hop log', () async {
      final req = SosRequest(
        sosId: 'SOS_DIRECT_01',
        timestamp: DateTime.now(),
        latitude: 28.6139,
        longitude: 77.2090,
        emergencyType: EmergencyType.medical,
        peopleCount: 1,
        injuredCount: 0,
        status: SosStatus.pending,
      );

      final success = await transport.sendSos(req);
      expect(success, isTrue);
      expect(transport.statistics.txPackets, equals(1));
      expect(transport.logs.isNotEmpty, isTrue);
      expect(transport.logs.first.hopCount, equals(0));
    });

    test('receiveMeshPacket filters duplicates and expired TTL packets (loop prevention)', () async {
      final packet = EmergencyMeshPacket(
        packetId: 'PKT_LOOP_TEST_01',
        originDeviceId: 'NODE-AND-03',
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        emergencyType: EmergencyType.other,
        peopleCount: 1,
        injuredCount: 0,
        hopCount: 1,
        ttl: 4,
        relayedByNodes: ['NODE-AND-03'],
      );

      // First receipt: Accepted & Relayed
      await transport.receiveMeshPacket(packet);
      expect(transport.statistics.rxPackets, equals(1));
      expect(transport.statistics.relayedPackets, equals(1));

      // Duplicate receipt: Dropped by deduplication cache
      await transport.receiveMeshPacket(packet);
      expect(transport.statistics.droppedPackets, equals(1));

      // Expired packet: Dropped due to TTL 0
      final expiredPacket = EmergencyMeshPacket(
        packetId: 'PKT_EXPIRED_01',
        originDeviceId: 'NODE-AND-04',
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        emergencyType: EmergencyType.other,
        peopleCount: 1,
        injuredCount: 0,
        hopCount: 7,
        ttl: 0,
        relayedByNodes: ['NODE-AND-04'],
      );
      await transport.receiveMeshPacket(expiredPacket);
      expect(transport.statistics.droppedPackets, equals(2));
    });

    test('Gateway Node automatically bridges incoming peer SOS to Cloud Repository', () async {
      transport.setLocalGatewayStatus(true);
      expect(transport.isLocalGateway, isTrue);

      final peerPacket = EmergencyMeshPacket(
        packetId: 'PKT_GW_SYNC_01',
        originDeviceId: 'NODE-AND-09',
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 4.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        emergencyType: EmergencyType.flood,
        peopleCount: 3,
        injuredCount: 1,
        hopCount: 2,
        ttl: 3,
        relayedByNodes: ['NODE-AND-09', 'NODE-REP-01'],
      );

      await transport.receiveMeshPacket(peerPacket);

      // Verify that cloud repo has received the bridged SOS
      final dispatchedList = await repo.getSosHistory();
      expect(dispatchedList.any((r) => r.sosId == 'SOS_PKT_GW_SYNC_01'), isTrue);

      // Verify Gateway uplink log was recorded
      expect(transport.logs.any((l) => l.isGatewayAction), isTrue);
    });
  });
}
