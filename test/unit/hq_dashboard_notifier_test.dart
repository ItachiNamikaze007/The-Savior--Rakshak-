import 'package:flutter_test/flutter_test.dart';
import 'package:sosquad/features/hq/presentation/providers/hq_dashboard_notifier.dart';
import 'package:sosquad/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:sosquad/features/sos/domain/entities/emergency_type.dart';
import 'package:sosquad/features/sos/domain/entities/sos_request.dart';
import 'package:sosquad/features/sos/domain/entities/sos_status.dart';

void main() {
  late SosRepositoryImpl repository;
  late HqDashboardNotifier notifier;

  setUp(() {
    repository = SosRepositoryImpl(simulationDelay: Duration.zero);
    notifier = HqDashboardNotifier(sosRepository: repository);
  });

  tearDown(() {
    notifier.dispose();
    repository.dispose();
  });

  test('HqDashboardNotifier listens to realtime repository stream and computes metrics', () async {
    final req1 = SosRequest(
      sosId: 'RAK-HQ-001',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      latitude: 28.6139,
      longitude: 77.2090,
      emergencyType: EmergencyType.flood,
      peopleCount: 10,
      injuredCount: 3,
      status: SosStatus.pending,
    );

    final req2 = SosRequest(
      sosId: 'RAK-HQ-002',
      timestamp: DateTime.now(),
      latitude: 19.0760,
      longitude: 72.8777,
      emergencyType: EmergencyType.medical,
      peopleCount: 4,
      injuredCount: 2,
      status: SosStatus.transmitting,
    );

    // Initial state is empty
    expect(notifier.totalCount, equals(0));

    // Dispatch incidents
    await repository.dispatchSos(req1);
    await repository.dispatchSos(req2);
    await pumpEventQueue();

    expect(notifier.totalCount, equals(2));
    expect(notifier.totalPeopleAffected, equals(14));
    expect(notifier.totalInjured, equals(5));

    // Update status to dispatched
    await notifier.updateIncidentStatus('RAK-HQ-001', SosStatus.dispatched);
    await pumpEventQueue();

    expect(notifier.dispatchedCount, equals(1));
  });

  test('HqDashboardNotifier filters by status, category, and search query correctly', () async {
    final req1 = SosRequest(
      sosId: 'RAK-HQ-101',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      latitude: 28.6139,
      longitude: 77.2090,
      emergencyType: EmergencyType.fire,
      peopleCount: 6,
      injuredCount: 1,
      status: SosStatus.transmitting,
    );

    final req2 = SosRequest(
      sosId: 'RAK-HQ-102',
      timestamp: DateTime.now(),
      latitude: 12.9716,
      longitude: 77.5946,
      emergencyType: EmergencyType.earthquake,
      peopleCount: 2,
      injuredCount: 0,
      status: SosStatus.acknowledged,
    );

    await repository.dispatchSos(req1);
    await repository.dispatchSos(req2);
    await pumpEventQueue();

    // 1. Status Filter
    notifier.setStatusFilter(HqStatusFilter.active);
    expect(notifier.filteredIncidents.length, equals(0)); // dispatchSos in mock transitions to acknowledged

    notifier.setStatusFilter(HqStatusFilter.acknowledged);
    expect(notifier.filteredIncidents.length, equals(2));

    // 2. Emergency Type Filter
    notifier.setStatusFilter(HqStatusFilter.all);
    notifier.setEmergencyTypeFilter(EmergencyType.fire);
    expect(notifier.filteredIncidents.length, equals(1));
    expect(notifier.filteredIncidents.first.sosId, equals('RAK-HQ-101'));

    // 3. Search Query Filter
    notifier.setEmergencyTypeFilter(null);
    notifier.setSearchQuery('102');
    expect(notifier.filteredIncidents.length, equals(1));
    expect(notifier.filteredIncidents.first.sosId, equals('RAK-HQ-102'));
  });

  test('Incident selection and detail inspection works', () {
    notifier.selectIncident('RAK-HQ-999');
    expect(notifier.selectedSosId, equals('RAK-HQ-999'));

    notifier.selectIncident(null);
    expect(notifier.selectedSosId, isNull);
  });
}
