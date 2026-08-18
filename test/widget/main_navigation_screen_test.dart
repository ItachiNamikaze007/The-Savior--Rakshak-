import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sosquad/core/constants/app_theme.dart';
import 'package:sosquad/core/services/communication/communication_manager.dart';
import 'package:sosquad/core/services/location_service.dart';
import 'package:sosquad/features/navigation/presentation/screens/main_navigation_screen.dart';
import 'package:sosquad/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:sosquad/features/sos/domain/repositories/i_sos_repository.dart';
import 'package:sosquad/features/sos/presentation/providers/sos_state_notifier.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}
  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  void close({bool force = false}) {}
  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  // 1x1 transparent PNG
  static final List<int> _transparentPng = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
  ];

  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => _transparentPng.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  testWidgets('MainNavigationScreen renders 4 bottom tabs (Home, Mesh, Rescue, Profile) and switches views', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 2.0, 800 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final locationService = LocationService();
    final sosRepository = SosRepositoryImpl(simulationDelay: Duration.zero);
    final commManager = CommunicationManager(repository: sosRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocationService>.value(value: locationService),
          Provider<ISosRepository>.value(value: sosRepository),
          ChangeNotifierProvider<CommunicationManager>.value(value: commManager),
          ChangeNotifierProvider<SosStateNotifier>(
            create: (_) => SosStateNotifier(
              sosRepository: sosRepository,
              locationService: locationService,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );

    await tester.pump();

    // 1. Verify Home Tab is active & Strict SOS dominates
    expect(find.text('SoSquad'), findsOneWidget);
    expect(find.text('STRICT SOS'), findsOneWidget);
    expect(find.text('DETAILED SOS'), findsOneWidget);
    expect(find.text('OFFLINE COMMS'), findsOneWidget);

    // 2. Tap on Mesh Tab
    await tester.tap(find.byIcon(Icons.hub_outlined));
    await tester.pump();
    expect(find.text('LoRa Mesh Network'), findsOneWidget);
    expect(find.text('READY FOR HARDWARE'), findsOneWidget);

    // 3. Tap on Rescue Tab (User-scoped rescue status)
    await tester.tap(find.byIcon(Icons.emergency_outlined));
    await tester.pump();
    expect(find.text('My Rescue Status'), findsOneWidget);

    // 4. Tap on Profile Tab
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump();
    expect(find.text('User Profile & Device'), findsOneWidget);
    expect(find.text('USR-NDRF-8821'), findsOneWidget);

    sosRepository.dispose();
    commManager.dispose();
  });

  testWidgets('Home content scrolls independently while bottom navigation stays fixed at the bottom', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 2.0, 640 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final locationService = LocationService();
    final sosRepository = SosRepositoryImpl(simulationDelay: Duration.zero);
    final commManager = CommunicationManager(repository: sosRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocationService>.value(value: locationService),
          Provider<ISosRepository>.value(value: sosRepository),
          ChangeNotifierProvider<CommunicationManager>.value(value: commManager),
          ChangeNotifierProvider<SosStateNotifier>(
            create: (_) => SosStateNotifier(
              sosRepository: sosRepository,
              locationService: locationService,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify NavigationBar is present
    expect(find.byType(NavigationBar), findsOneWidget);
    final navBarInitialRect = tester.getRect(find.byType(NavigationBar));

    // Drag / scroll the Home screen
    await tester.drag(find.text('STRICT SOS'), const Offset(0, -300));
    await tester.pump();

    // Verify NavigationBar position remains exactly fixed at the bottom
    final navBarAfterScrollRect = tester.getRect(find.byType(NavigationBar));
    expect(navBarAfterScrollRect, equals(navBarInitialRect));

    // Verify all 4 tab destinations remain present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Mesh'), findsOneWidget);
    expect(find.text('Rescue'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    sosRepository.dispose();
    commManager.dispose();
  });

  testWidgets('Bottom navigation is responsive without overflow on 320dp and 360dp screens', (WidgetTester tester) async {
    for (final width in [320.0, 360.0, 412.0]) {
      tester.view.physicalSize = Size(width * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      final locationService = LocationService();
      final sosRepository = SosRepositoryImpl(simulationDelay: Duration.zero);
      final commManager = CommunicationManager(repository: sosRepository);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<LocationService>.value(value: locationService),
            Provider<ISosRepository>.value(value: sosRepository),
            ChangeNotifierProvider<CommunicationManager>.value(value: commManager),
            ChangeNotifierProvider<SosStateNotifier>(
              create: (_) => SosStateNotifier(
                sosRepository: sosRepository,
                locationService: locationService,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainNavigationScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Must not overflow on ${width}dp width');

      sosRepository.dispose();
      commManager.dispose();
    }
  });

  testWidgets('ProfileScreen renders readable text for all preferences and options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 2.0, 800 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final locationService = LocationService();
    final sosRepository = SosRepositoryImpl(simulationDelay: Duration.zero);
    final commManager = CommunicationManager(repository: sosRepository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocationService>.value(value: locationService),
          Provider<ISosRepository>.value(value: sosRepository),
          ChangeNotifierProvider<CommunicationManager>.value(value: commManager),
          ChangeNotifierProvider<SosStateNotifier>(
            create: (_) => SosStateNotifier(
              sosRepository: sosRepository,
              locationService: locationService,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );

    await tester.pump();

    // Switch to Profile Tab
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump();

    expect(find.text('Distress Notifications'), findsOneWidget);
    expect(find.text('Receive status updates when HQ responds'), findsOneWidget);
    expect(find.text('Haptic Emergency Feedback'), findsOneWidget);
    expect(find.text('Vibrate during 3s hold and SOS confirmation'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Location Permissions'), findsOneWidget);

    sosRepository.dispose();
    commManager.dispose();
  });
}
