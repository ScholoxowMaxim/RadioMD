import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:radiomd/features/auth/presentation/login_screen.dart';
import 'package:radiomd/features/home/presentation/home_screen.dart';

/// Конфигурация маршрутизации приложения
/// Перенаправляет неавторизованных пользователей на экран входа
GoRouter createRouter(User? initialUser) {
  return GoRouter(
    initialLocation: initialUser != null ? '/' : '/login',

    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isOnLogin = state.matchedLocation == '/login';

      // Не авторизован и не на странице входа → на вход
      if (user == null && !isOnLogin) return '/login';
      // Авторизован и на странице входа → на главную
      if (user != null && isOnLogin) return '/';
      
      return null; // Всё корректно
    },

    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
}