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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Загружаем .env файл
  await dotenv.load(fileName: ".env");

  // Получаем общие настройки
  final projectId = dotenv.env['FIREBASE_PROJECT_ID']!;
  final storageBucket = dotenv.env['FIREBASE_WEB_STORAGE_BUCKET']!;

  // Определяем платформу и подставляем нужные ключи
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

  await Firebase.initializeApp(options: options);

  runApp(const RadioMDApp());
}

class RadioMDApp extends StatefulWidget {
  const RadioMDApp({super.key});

  @override
  State<RadioMDApp> createState() => _RadioMDAppState();
}

class _RadioMDAppState extends State<RadioMDApp> {
  late GoRouter _router;
  final PlayerService _playerService = PlayerService();

  @override
  void initState() {
    super.initState();
    _router = createRouter(FirebaseAuth.instance.currentUser);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() => _router = createRouter(user));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _playerService,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}