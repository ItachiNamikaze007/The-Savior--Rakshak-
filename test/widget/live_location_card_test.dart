import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sosquad/core/constants/app_theme.dart';
import 'package:sosquad/core/services/location_service.dart';
import 'package:sosquad/features/home/presentation/widgets/live_location_card.dart';
import 'package:sosquad/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:sosquad/features/sos/presentation/providers/sos_state_notifier.dart';

void main() {
  testWidgets('LiveLocationCard renders without RenderFlex overflow on 360dp and 320dp devices', (WidgetTester tester) async {
    final locationService = LocationService();
    final sosRepository = SosRepositoryImpl(simulationDelay: Duration.zero);
    final notifier = SosStateNotifier(
      sosRepository: sosRepository,
      locationService: locationService,
    );

    // Force real/simulated location to populate the full coordinate and sub-telemetry rows
    await notifier.fetchLocation(forceSimulated: true);

    // Test on 360dp width screen (Standard Android small screen)
    tester.view.physicalSize = const Size(360 * 2.0, 800 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: LiveLocationCard(
              notifier: notifier,
              onViewOnMap: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all telemetry labels render without throwing overflow exceptions
    expect(find.text('LIVE GPS TELEMETRY'), findsOneWidget);
    expect(find.text('LATITUDE'), findsOneWidget);
    expect(find.text('LONGITUDE'), findsOneWidget);
    expect(find.text('ACCURACY'), findsOneWidget);
    expect(find.text('VIEW ON LIVE MAP'), findsOneWidget);

    // Test even on ultra-narrow 320dp width
    tester.view.physicalSize = const Size(320 * 2.0, 600 * 2.0);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('VIEW ON LIVE MAP'), findsOneWidget);

    sosRepository.dispose();
  });
}
