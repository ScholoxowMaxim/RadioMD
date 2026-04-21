// Импорт пакета Flutter Material Design для работы с темами
import 'package:flutter/material.dart';

// Класс для хранения и настройки тем приложения
class AppTheme {
  // Статическое поле с настройками светлой темы
  static ThemeData lightTheme = ThemeData(
    // Использовать Material Design 3 (Material You)
    useMaterial3: true,
    
    // Устанавливаем светлую цветовую схему
    brightness: Brightness.light,
    
    // Генерация цветовой схемы на основе базового цвета
    colorScheme: ColorScheme.fromSeed(
      // Базовый (основной) цвет для генерации всей палитры
      seedColor: Colors.deepPurple,
    ),
  );
}