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

/// Точка входа в приложение
/// Инициализирует Firebase, аудио-сервис и запускает приложение
void main() async {
  // Обеспечиваем привязку Widgets (необходимо для Flutter)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Загружаем переменные окружения из файла .env
  await dotenv.load(fileName: ".env");

  // Инициализируем аудио-сервис для фонового воспроизведения
  // AudioHandler позволяет играть музыку даже когда приложение свернуто
  final audioHandler = await initAudioService();

  // Настройка Firebase в зависимости от платформы (Web, Android, iOS, etc.)
  final projectId = dotenv.env['FIREBASE_PROJECT_ID']!;
  final storageBucket = dotenv.env['FIREBASE_WEB_STORAGE_BUCKET']!;

  // Выбираем правильные Firebase настройки в зависимости от платформы
  FirebaseOptions options;
  if (kIsWeb) {
    // Настройки для Web
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
    // Настройки для мобильных платформ (Android, iOS, macOS, Windows)
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
      // ... другие платформы
      default:
        throw UnsupportedError('Платформа не поддерживается');
    }
  }

  // Инициализируем Firebase с выбранными настройками
  await Firebase.initializeApp(options: options);
  
  // Запускаем приложение
  runApp(RadioMDApp(audioHandler: audioHandler));

  // Инициализируем уведомления в фоне
  final notificationService = NotificationService();
  notificationService.initialize();
}

/// Главный виджет приложения
class RadioMDApp extends StatefulWidget {
  final AudioPlayerHandler audioHandler;
  const RadioMDApp({super.key, required this.audioHandler});

  @override
  State<RadioMDApp> createState() => _RadioMDAppState();
}

class _RadioMDAppState extends State<RadioMDApp> {
  late GoRouter _router;           // Маршрутизатор для навигации
  late PlayerService _playerService; // Сервис плеера
  final ThemeService _themeService = ThemeService(); // Сервис тем

  @override
  void initState() {
    super.initState();
    // Создаем сервис плеера с переданным аудио-хендлером
    _playerService = PlayerService(widget.audioHandler);
    
    // Создаем начальный роутер с текущим пользователем
    _router = createRouter(FirebaseAuth.instance.currentUser);
    
    // Подписываемся на изменения статуса авторизации
    // Если пользователь вошел/вышел - обновляем роутинг
    String? lastUserId;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      final userId = user?.uid;
      if (lastUserId == userId) return; // Защита от дублирования
      lastUserId = userId;
      
      // Обновляем роутер с новым пользователем
      setState(() => _router = createRouter(user));
    });
  }

  @override
  Widget build(BuildContext context) {
    // MultiProvider - провайдеры для DI (внедрения зависимостей)
    return MultiProvider(
      providers: [
        // PlayerService будет доступен во всем приложении
        ChangeNotifierProvider(create: (_) => _playerService),
        // ThemeService тоже глобально
        ChangeNotifierProvider(create: (_) => _themeService)
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          // MaterialApp - корневой виджет приложения
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'RadioMD',
            theme: AppTheme.lightTheme,     // Светлая тема
            darkTheme: AppTheme.darkTheme,   // Тёмная тема
            themeMode: themeService.themeMode, // Текущая тема
            routerConfig: _router,           // Настройки роутинга
          );
        },
      ),
    );
  }
}