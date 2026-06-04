import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/core/services/player_service.dart';
import 'dart:math';

/// GradientBackground - фон с красивым градиентом на основе названия станции
/// Работает на всех устройствах без исключений
class GradientBackground extends StatefulWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground> {
  Gradient _currentGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
  );
  
  String _lastStationId = '';

  /// Генерация красивого градиента на основе ID и названия станции
  Gradient _generateGradient(String stationId, String stationName) {
    // Создаём хеш из ID станции
    final hash = (stationId.hashCode).abs();
    
    // Генерируем основной цвет (яркий, насыщенный)
    final r = ((hash >> 16) & 0xFF) / 255.0;
    final g = ((hash >> 8) & 0xFF) / 255.0;
    final b = (hash & 0xFF) / 255.0;
    
    // Основной цвет (60% насыщенности для приятного вида)
    final primaryColor = Color.fromRGBO(
      100 + (r * 100).toInt(),
      50 + (g * 80).toInt(),
      80 + (b * 100).toInt(),
      1.0,
    );
    
    // Средний цвет (темнее)
    final secondaryColor = Color.fromRGBO(
      40 + (r * 60).toInt(),
      20 + (g * 50).toInt(),
      40 + (b * 60).toInt(),
      1.0,
    );
    
    // Тёмный цвет для глубины
    final darkColor = Color.fromRGBO(
      (r * 30).toInt(),
      (g * 20).toInt(),
      (b * 30).toInt(),
      1.0,
    );
    
    // Возвращаем красивый градиент
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, secondaryColor, darkColor],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, player, _) {
        final station = player.currentStation;
        
        if (station != null && _lastStationId != station.id) {
          _lastStationId = station.id;
          _currentGradient = _generateGradient(station.id, station.name);
        }
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: _currentGradient,
          ),
          child: widget.child,
        );
      },
    );
  }
}