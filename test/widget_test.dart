import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sosquad/core/constants/app_theme.dart';
import 'package:sosquad/core/services/location_service.dart';
import 'package:sosquad/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:sosquad/features/sos/domain/repositories/i_sos_repository.dart';
import 'package:sosquad/features/sos/presentation/providers/sos_state_notifier.dart';
import 'package:sosquad/features/sos/presentation/screens/home_sos_screen.dart';

void main() {
  testWidgets('HomeSosScreen renders branding, emergency types and SOS button',
      (WidgetTester tester) async {
    final locationService = LocationService();
    final sosRepository = SosRepositoryImpl();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocationService>.value(value: locationService),
          Provider<ISosRepository>.value(value: sosRepository),
          ChangeNotifierProvider<SosStateNotifier>(
            create: (_) => SosStateNotifier(
              sosRepository: sosRepository,
              locationService: locationService,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeSosScreen(),
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify App Name & Product Branding
    expect(find.text('SoSquad'), findsOneWidget);
    expect(find.text('RAKSHAK-NET'), findsOneWidget);

    // Verify Emergency Types are present
    expect(find.text('Medical'), findsOneWidget);
    expect(find.text('Flood'), findsOneWidget);
    expect(find.text('Fire'), findsOneWidget);
    expect(find.text('Earthquake'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);

    // Verify SOS Button text
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('TRANSMIT'), findsOneWidget);

    // Tap on Fire emergency type
    await tester.tap(find.text('Fire'));
    await tester.pump(const Duration(milliseconds: 300));

    sosRepository.dispose();
  });
}
