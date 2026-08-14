import 'package:flutter_test/flutter_test.dart';
import 'package:sosquad/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:sosquad/features/sos/domain/entities/emergency_type.dart';
import 'package:sosquad/features/sos/domain/entities/sos_request.dart';
import 'package:sosquad/features/sos/domain/entities/sos_status.dart';

void main() {
  late SosRepositoryImpl repository;

  setUp(() {
    repository = SosRepositoryImpl();
  });

  tearDown(() {
    repository.dispose();
  });

  test('dispatchSos transitions to acknowledged status', () async {
    final request = SosRequest(
      sosId: 'RAK-TEST-001',
      timestamp: DateTime.now(),
      latitude: 28.6139,
      longitude: 77.2090,
      emergencyType: EmergencyType.earthquake,
      peopleCount: 4,
      injuredCount: 1,
      status: SosStatus.pending,
    );

    // Listens for stream updates
    final statusEvents = <SosStatus>[];
    final sub = repository.watchSosStatus('RAK-TEST-001').listen((req) {
      statusEvents.add(req.status);
    });

    final result = await repository.dispatchSos(request);
    await pumpEventQueue();

    expect(result.status, equals(SosStatus.acknowledged));
    expect(statusEvents, contains(SosStatus.transmitting));
    expect(statusEvents, contains(SosStatus.acknowledged));

    await sub.cancel();
  });

  test('cancelSos transitions status to cancelled', () async {
    final request = SosRequest(
      sosId: 'RAK-TEST-002',
      timestamp: DateTime.now(),
      latitude: 28.6139,
      longitude: 77.2090,
      emergencyType: EmergencyType.medical,
      peopleCount: 2,
      injuredCount: 2,
      status: SosStatus.pending,
    );

    // Start dispatch without awaiting immediately
    final dispatchFuture = repository.dispatchSos(request);

    // Cancel while in flight
    final cancelled = await repository.cancelSos('RAK-TEST-002');
    expect(cancelled.status, equals(SosStatus.cancelled));

    await dispatchFuture;

    final finalStatus = await repository.getSosStatus('RAK-TEST-002');
    expect(finalStatus?.status, equals(SosStatus.cancelled));
  });
}
