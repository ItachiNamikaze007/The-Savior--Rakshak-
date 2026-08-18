import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sosquad/core/constants/app_theme.dart';
import 'package:sosquad/features/hq/presentation/screens/hq_dashboard_screen.dart';
import 'package:sosquad/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:sosquad/features/sos/domain/entities/emergency_type.dart';
import 'package:sosquad/features/sos/domain/entities/sos_request.dart';
import 'package:sosquad/features/sos/domain/entities/sos_status.dart';
import 'package:sosquad/features/sos/domain/repositories/i_sos_repository.dart';

void main() {
  testWidgets('HqDashboardScreen renders 2026 tactical dark command center layout', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400 * 1.5, 950 * 1.5);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(() => tester.view.resetPhysicalSize());

    final sosRepository = SosRepositoryImpl(simulationDelay: Duration.zero);

    // Seed mock incident
    await sosRepository.dispatchSos(
      SosRequest(
        sosId: 'RAK-TEST-0001',
        emergencyType: EmergencyType.medical,
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        status: SosStatus.transmitting,
        deviceId: 'NODE-001',
        peopleCount: 2,
        injuredCount: 1,
        isSimulatedGps: false,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ISosRepository>.value(value: sosRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HqDashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Verify Left Sidebar Navigation & SOS Broadcast button
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Live SOS'), findsOneWidget);
    expect(find.text('Map View'), findsOneWidget);
    expect(find.text('Incidents'), findsOneWidget);
    expect(find.text('Teams'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('Communication'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('SOS BROADCAST'), findsOneWidget);

    // 2. Verify Header Branding & Clocks & Operator Profile
    expect(find.text('SoSquad HQ'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Live Emergency Operations'), findsOneWidget);
    expect(find.text('System Online'), findsOneWidget);
    expect(find.text('HQ Operator'), findsOneWidget);
    expect(find.text('Cdr. S. Sharma'), findsOneWidget);
    expect(find.text('LOC'), findsOneWidget);
    expect(find.text('UTC'), findsOneWidget);

    // 3. Verify KPI Row
    expect(find.text('TOTAL SOS'), findsOneWidget);
    expect(find.text('ACTIVE INCIDENTS'), findsOneWidget);
    expect(find.text('DISPATCHED'), findsWidgets);
    expect(find.text('RESOLVED'), findsOneWidget);
    expect(find.text('AVG RESPONSE TIME'), findsOneWidget);
    expect(find.text('ONLINE UNITS'), findsOneWidget);

    // 4. Verify Live Distress Queue & Map Overview
    expect(find.text('LIVE DISTRESS QUEUE (1)'), findsOneWidget);
    expect(find.text('RAK-TEST-0001'), findsOneWidget);

    // 5. Verify Bottom Operations Strip Tabs
    expect(find.text('TEAM STATUS'), findsOneWidget);
    expect(find.text('RECENT ACTIVITY'), findsOneWidget);
    expect(find.text('CURRENT ASSIGNMENTS'), findsOneWidget);
    expect(find.text('RESPONSE ANALYTICS'), findsOneWidget);

    // 6. Select the incident to open Incident Dossier Panel
    await tester.tap(find.text('RAK-TEST-0001'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Dossier Panel is displayed with details, GPS, and 6 quick actions
    expect(find.text('INCIDENT DOSSIER'), findsOneWidget);
    expect(find.text('RESPONSE LIFECYCLE'), findsOneWidget);
    expect(find.text('LIVE GPS TRACKING'), findsOneWidget);
    expect(find.text('Acknowledge'), findsOneWidget);
    expect(find.text('Assign Team'), findsOneWidget);
    expect(find.text('Dispatch Unit'), findsOneWidget);
    expect(find.text('Contact User'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Escalate'), findsOneWidget);

    sosRepository.dispose();
  });
}
