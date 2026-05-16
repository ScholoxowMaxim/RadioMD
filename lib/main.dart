import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RadioMDApp());
}

class RadioMDApp extends StatelessWidget {
  const RadioMDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerService()),
        // Добавьте другие провайдеры если есть
      ],
      child: const MainApp(),
    );
  }
}

// Отдельный виджет для AppWrapper
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _updateRouter(FirebaseAuth.instance.currentUser);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _updateRouter(user);
    });
  }

  void _updateRouter(User? user) {
    setState(() {
      _router = createRouter(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}