import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/player_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/audio_player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Audio Service
  final audioHandler = await initAudioService();

  final projectId = dotenv.env['FIREBASE_PROJECT_ID']!;
  final storageBucket = dotenv.env['FIREBASE_WEB_STORAGE_BUCKET']!;

  FirebaseOptions options;
  if (kIsWeb) {
    options = FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_WEB_API_KEY']!,
      appId: dotenv.env['FIREBASE_WEB_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID']!,
      projectId: projectId,
      authDomain: dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'],
      storageBucket: storageBucket,
      measurementId: dotenv.env['FIREBASE_WEB_MEASUREMENT_ID'],
    );
  } else {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        options = FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY']!,
          appId: dotenv.env['FIREBASE_ANDROID_APP_ID']!,
          messagingSenderId: dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID']!,
          projectId: projectId,
          storageBucket: storageBucket,
        );
        break;
      case TargetPlatform.iOS:
        options = FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_IOS_API_KEY']!,
          appId: dotenv.env['FIREBASE_IOS_APP_ID']!,
          messagingSenderId: dotenv.env['FIREBASE_IOS_MESSAGING_SENDER_ID']!,
          projectId: projectId,
          storageBucket: storageBucket,
          iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID']!,
        );
        break;
      case TargetPlatform.macOS:
        options = FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_MACOS_API_KEY']!,
          appId: dotenv.env['FIREBASE_MACOS_APP_ID']!,
          messagingSenderId: dotenv.env['FIREBASE_MACOS_MESSAGING_SENDER_ID']!,
          projectId: projectId,
          storageBucket: storageBucket,
          iosBundleId: dotenv.env['FIREBASE_MACOS_BUNDLE_ID']!,
        );
        break;
      case TargetPlatform.windows:
        options = FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_WINDOWS_API_KEY']!,
          appId: dotenv.env['FIREBASE_WINDOWS_APP_ID']!,
          messagingSenderId: dotenv.env['FIREBASE_WINDOWS_MESSAGING_SENDER_ID']!,
          projectId: projectId,
          authDomain: dotenv.env['FIREBASE_WINDOWS_AUTH_DOMAIN'],
          storageBucket: storageBucket,
          measurementId: dotenv.env['FIREBASE_WINDOWS_MEASUREMENT_ID'],
        );
        break;
      default:
        throw UnsupportedError('Платформа не поддерживается');
    }
  }

  // 1. Сначала Firebase
  await Firebase.initializeApp(options: options);

  // 2. Запуск приложения
  runApp(RadioMDApp(audioHandler: audioHandler));

  // 3. Уведомления после запуска (Activity готова)
  final notificationService = NotificationService();
  notificationService.initialize();
}

class RadioMDApp extends StatefulWidget {
  final AudioPlayerHandler audioHandler;
  const RadioMDApp({super.key, required this.audioHandler});

  @override
  State<RadioMDApp> createState() => _RadioMDAppState();
}

class _RadioMDAppState extends State<RadioMDApp> {
  late GoRouter _router;
  late PlayerService _playerService;
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _playerService = PlayerService(widget.audioHandler);
    _router = createRouter(FirebaseAuth.instance.currentUser);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() => _router = createRouter(user));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _playerService),
        ChangeNotifierProvider(create: (_) => _themeService)
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}