import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_theme.dart';
import 'core/services/location_service.dart';
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

  // Set immersive dark status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0F19),
      systemNavigationBarIconBrightness: Brightness.light,
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

        // Repositories (Cloud Firestore for Phase 2, with customizable injection)
        Provider<ISosRepository>(
          create: (_) => repository ?? FirestoreSosRepositoryImpl(),
          dispose: (_, repo) {
            if (repo is SosRepositoryImpl) {
              repo.dispose();
            }
          },
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
        theme: AppTheme.darkTheme,
        home: const HomeSosScreen(),
      ),
    );
  }
}

