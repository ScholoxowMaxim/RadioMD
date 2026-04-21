import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const RadioMDApp()); // Точка входа в приложение
}

class RadioMDApp extends StatelessWidget {
  const RadioMDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false, // Убираем баннер "DEBUG"
      theme: AppTheme.lightTheme,         // Применяем светлую тему
      routerConfig: appRouter,            // Подключаем маршрутизацию
    );
  }
}