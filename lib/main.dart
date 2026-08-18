import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_theme.dart';
import 'core/services/communication/communication_manager.dart';
import 'core/services/location_service.dart';
import 'features/hq/presentation/screens/hq_dashboard_screen.dart';
import 'features/navigation/presentation/screens/main_navigation_screen.dart';
import 'features/sos/data/repositories/firestore_sos_repository_impl.dart';
import 'features/sos/data/repositories/sos_repository_impl.dart';
import 'features/sos/domain/repositories/i_sos_repository.dart';
import 'features/sos/presentation/providers/sos_state_notifier.dart';
import 'features/sos/presentation/screens/home_sos_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core with generated FlutterFire configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  // Set clean modern status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SoSquadApp());
}

class SoSquadApp extends StatelessWidget {
  final ISosRepository? repository;

  const SoSquadApp({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<LocationService>(
          create: (_) => LocationService(),
        ),

        // Repositories (Cloud Firestore for Phase 2/3, with customizable injection)
        Provider<ISosRepository>(
          create: (_) => repository ?? FirestoreSosRepositoryImpl(),
          dispose: (_, repo) {
            if (repo is SosRepositoryImpl) {
              repo.dispose();
            }
          },
        ),

        // Communication Abstraction (Internet + LoRa Mesh + Offline Queue)
        ChangeNotifierProvider<CommunicationManager>(
          create: (ctx) => CommunicationManager(
            repository: ctx.read<ISosRepository>(),
          ),
        ),

        // Presentation State Notifier
        ChangeNotifierProvider<SosStateNotifier>(
          create: (ctx) => SosStateNotifier(
            sosRepository: ctx.read<ISosRepository>(),
            locationService: ctx.read<LocationService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: '${AppStrings.appName} - ${AppStrings.productName}',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // Web defaults to HQ Command Center, Mobile defaults to 2026 Navigation App
        home: kIsWeb ? const HqDashboardScreen() : const MainNavigationScreen(),
        routes: {
          '/hq': (_) => const HqDashboardScreen(),
          '/field': (_) => const MainNavigationScreen(),
          '/field_legacy': (_) => const HomeSosScreen(),
        },
      ),
    );
  }
}



