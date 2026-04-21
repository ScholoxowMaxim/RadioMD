import 'package:go_router/go_router.dart'; 
import 'package:radiomd/features/home/presentation/home_screen.dart';

// Создание и конфигурация главного роутера приложения
final GoRouter appRouter = GoRouter(
  // Начальный маршрут при запуске приложения - корневой путь
  initialLocation: '/',
  
  // Список всех доступных маршрутов в приложении
  routes: [
    // Определение маршрута для корневого пути
    GoRoute(
      // URL-путь для этого маршрута
      path: '/',
      
      // Функция построения виджета для данного маршрута
      // context - контекст сборки, state - состояние маршрута
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);