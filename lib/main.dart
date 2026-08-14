import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_theme.dart';
import 'core/services/location_service.dart';
import 'features/sos/data/repositories/sos_repository_impl.dart';
import 'features/sos/domain/repositories/i_sos_repository.dart';
import 'features/sos/presentation/providers/sos_state_notifier.dart';
import 'features/sos/presentation/screens/home_sos_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
  const SoSquadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<LocationService>(
          create: (_) => LocationService(),
        ),

        // Repositories (Interface bound to mock implementation for Phase 1)
        Provider<ISosRepository>(
          create: (_) => SosRepositoryImpl(),
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
