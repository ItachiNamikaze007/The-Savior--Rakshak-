import 'package:flutter_test/flutter_test.dart';
import 'package:sosquad/core/services/communication/communication_manager.dart';
import 'package:sosquad/core/services/communication/pending_message.dart';
import 'package:sosquad/core/services/communication/transport.dart';
import 'package:sosquad/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:sosquad/features/sos/domain/entities/emergency_type.dart';
import 'package:sosquad/features/sos/domain/entities/sos_request.dart';
import 'package:sosquad/features/sos/domain/entities/sos_status.dart';

void main() {
  late SosRepositoryImpl repository;
  late CommunicationManager manager;

  setUp(() {
    repository = SosRepositoryImpl();
    manager = CommunicationManager(repository: repository);
  });

  tearDown(() {
    manager.dispose();
    repository.dispose();
  });

  test('CommunicationManager dispatches through active Internet and falls back to BLE Mesh when offline', () async {
    final req = SosRequest(
      sosId: 'RAK-COMM-001',
      timestamp: DateTime.now(),
      latitude: 28.6139,
      longitude: 77.2090,
      emergencyType: EmergencyType.medical,
      peopleCount: 2,
      injuredCount: 0,
      status: SosStatus.pending,
    );

    // Initial state: Internet active, BLE Mesh active
    expect(manager.isInternetAvailable, isTrue);
    expect(manager.isBleMeshAvailable, isTrue);
    expect(manager.mode, equals(CommunicationMode.hybrid));

    // Dispatch SOS online
    final success = await manager.dispatchEmergencySignal(req);
    expect(success, isTrue);
    expect(manager.queuedMessagesCount, equals(0));

    // Simulate Internet drop -> BLE Mesh auto-failover
    manager.internetTransport.setOnlineStatus(false);
    expect(manager.isInternetAvailable, isFalse);

    final req2 = SosRequest(
      sosId: 'RAK-COMM-002',
      timestamp: DateTime.now(),
      latitude: 19.0760,
      longitude: 72.8777,
      emergencyType: EmergencyType.fire,
      peopleCount: 5,
      injuredCount: 1,
      status: SosStatus.pending,
    );

    final offlineResult = await manager.dispatchEmergencySignal(req2);
    // Transmitted through BLE Mesh
    expect(offlineResult, isTrue);
    expect(manager.bleMeshTransport.statistics.txPackets, greaterThanOrEqualTo(1));

    // Stored in offline DTN queue for cloud sync
    expect(manager.queuedMessagesCount, equals(1));
    expect(manager.offlineQueue.pendingMessages.first.id, equals('RAK-COMM-002'));
    expect(manager.offlineQueue.pendingMessages.first.priority, equals(MessagePriority.critical));

    // Reconnection -> Automatically flush queue to repository
    manager.internetTransport.setOnlineStatus(true);
    await Future.delayed(const Duration(milliseconds: 100));
    expect(manager.queuedMessagesCount, equals(0));
  });
}
