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

  test('CommunicationManager dispatches through active Internet transport and queues offline if needed', () async {
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

    // Initial state: Internet active, LoRa pending hardware
    expect(manager.isInternetAvailable, isTrue);
    expect(manager.isLoraAvailable, isFalse);
    expect(manager.mode, equals(CommunicationMode.hybrid));

    // Dispatch SOS
    final success = await manager.dispatchEmergencySignal(req);
    expect(success, isTrue);
    expect(manager.queuedMessagesCount, equals(0));

    // When offline, enqueues to offline message queue
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
    expect(offlineResult, isFalse);
    expect(manager.queuedMessagesCount, equals(1));
    expect(manager.offlineQueue.pendingMessages.first.id, equals('RAK-COMM-002'));
    expect(manager.offlineQueue.pendingMessages.first.priority, equals(MessagePriority.critical));
  });
}
