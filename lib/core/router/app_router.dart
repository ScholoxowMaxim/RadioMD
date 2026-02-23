import 'package:go_router/go_router.dart'; // Убрали material, т.к. он не используется
import 'package:radiomd/features/home/presentation/home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);