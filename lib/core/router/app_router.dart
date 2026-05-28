import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:radiomd/features/auth/presentation/login_screen.dart';
import 'package:radiomd/features/home/presentation/home_screen.dart';
import 'package:radiomd/features/home/presentation/home_screen.dart';
// Обёртка, которая перестраивает роутер при изменении состояния аутентификации
GoRouter createRouter(User? initialUser) {
  return GoRouter(
    initialLocation: initialUser != null ? '/' : '/login',

    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isOnLogin = state.matchedLocation == '/login';

      // Если не вошёл и не на логине → на логин
      if (user == null && !isOnLogin) return '/login';
      // Если вошёл и на логине → на главную
      if (user != null && isOnLogin) return '/';
      // Всё ок
      return null;
    },

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
}