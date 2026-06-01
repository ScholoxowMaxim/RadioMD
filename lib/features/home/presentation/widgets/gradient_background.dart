import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/core/services/player_service.dart';

class GradientBackground extends StatefulWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground> {
  // Храним текущий градиент
  Gradient _currentGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
  );
  
  // Следим, чтобы не дёргать анализатор слишком часто
  String _lastImageUrl = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateGradient();
  }

  Future<void> _updateGradient() async {
    final player = context.read<PlayerService>();
    final station = player.currentStation;
    
    if (station == null || station.imageUrl.isEmpty) return;
    if (_lastImageUrl == station.imageUrl) return;
    
    _lastImageUrl = station.imageUrl;
    
    try {
      // Анализируем картинку, ищем яркие и темные цвета
      final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        NetworkImage(station.imageUrl),
        maximumColorCount: 5, // Ищем до 5 цветов
      );

      final List<Color> colors = [];
      
      // 1. Самый "живой" цвет (Vibrant)
      if (generator.vibrantColor != null) {
        colors.add(generator.vibrantColor!.color);
      }
      
      // 2. Тёмный цвет для глубины
      if (generator.darkVibrantColor != null) {
        colors.add(generator.darkVibrantColor!.color);
      } 
      // Если нет темного, берем muted
      else if (generator.darkMutedColor != null) {
        colors.add(generator.darkMutedColor!.color);
      }
      
      // 3. Если найдено мало цветов, добавляем красивые дефолтные оттенки
      if (colors.length < 2) {
        if (generator.lightVibrantColor != null) colors.add(generator.lightVibrantColor!.color);
        if (generator.mutedColor != null) colors.add(generator.mutedColor!.color);
      }
      
      // 4. Финальный градиент (минимум 2 цвета)
      if (colors.length >= 2) {
        setState(() {
          _currentGradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors[0], colors[1]],
          );
        });
      } else if (colors.isNotEmpty) {
        // Если нашли только 1 цвет — создаем плавный переход к черному
        setState(() {
          _currentGradient = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.first, Colors.black87],
          );
        });
      }
    } catch (e) {
      print('Ошибка генерации градиента: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Слушаем изменения станции
    return Consumer<PlayerService>(
      builder: (context, player, _) {
        // Если станция поменялась — пересчитываем градиент
        if (player.currentStation?.imageUrl != _lastImageUrl) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _updateGradient());
        }
        return Container(
          decoration: BoxDecoration(
            gradient: _currentGradient,
          ),
          child: widget.child,
        );
      },
    );
  }
}