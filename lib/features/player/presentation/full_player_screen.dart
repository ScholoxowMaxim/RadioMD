import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/core/services/player_service.dart';
import 'package:radiomd/features/home/presentation/widgets/gradient_background.dart';
import 'package:radiomd/features/home/presentation/widgets/pulsing_image.dart';
import 'package:radiomd/features/home/presentation/widgets/visualizer.dart';
import 'package:radiomd/features/player/presentation/animated_play_button.dart';

/// Полноэкранный плеер с градиентным фоном, пульсирующим изображением и визуализатором
/// Поддерживает свайп вниз для закрытия (только если свайп больше половины экрана)
class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  double _dragOffset = 0;
  bool _isClosing = false;
  bool _isReloading = false;
  
  // Высота экрана для определения порога закрытия
  late double _screenHeight;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Закрытие плеера с анимацией свайпа
  void _closePlayer() {
    if (_isClosing) return;
    _isClosing = true;
    _animationController.forward().then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _reloadRadio(PlayerService player) async {
    if (_isReloading) return;
    _isReloading = true;
    
    final station = player.currentStation;
    if (station == null) {
      _isReloading = false;
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Перезагрузка радио...'),
        ]),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    player.stop();
    await Future.delayed(const Duration(milliseconds: 100));
    await player.play(station);
    
    _isReloading = false;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Радио перезагружено!', style: TextStyle(color: Colors.green)),
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Получаем высоту экрана
    _screenHeight = MediaQuery.of(context).size.height;
    
    return Consumer<PlayerService>(
      builder: (context, player, _) {
        final station = player.currentStation;
        
        if (station == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final iconColor = isDark ? Colors.white : const Color.fromARGB(221, 0, 0, 0);
        final textColor = isDark ? Colors.white : const Color.fromARGB(221, 0, 0, 0);
        final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
        
        return GestureDetector(
          onVerticalDragDown: (_) {
            if (_isClosing) return;
            _dragOffset = 0;
            _animationController.stop();
          },
          onVerticalDragUpdate: (details) {
            if (_isClosing) return;
            // Только свайп вниз
            if (details.delta.dy > 0) {
              _dragOffset += details.delta.dy;
              // Ограничиваем максимальное смещение
              if (_dragOffset > _screenHeight) {
                _dragOffset = _screenHeight;
              }
              setState(() {});
            }
          },
          onVerticalDragEnd: (details) {
            if (_isClosing) return;
            // Закрываем только если свайпнули больше чем на половину экрана
            if (_dragOffset > _screenHeight / 2) {
              _closePlayer();
            } else {
              // Возвращаем на место
              setState(() {
                _dragOffset = 0;
              });
            }
          },
          child: Scaffold(
            body: GradientBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    // Верхняя панель
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Только стрелка вниз (без полоски)
                          IconButton(
                            icon: Icon(Icons.keyboard_arrow_down, color: iconColor, size: 32),
                            onPressed: _closePlayer,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.refresh, color: iconColor, size: 28),
                            onPressed: () => _reloadRadio(player),
                            tooltip: 'Перезагрузить радио',
                          ),
                          IconButton(
                            icon: Icon(
                              station.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: station.isFavorite ? Colors.red : iconColor,
                              size: 28,
                            ),
                            onPressed: () => player.toggleFavorite(station.id),
                          ),
                        ],
                      ),
                    ),
                    
                    // Изображение станции с пульсацией (смещается при свайпе)
                    Expanded(
                      flex: 3,
                      child: Transform.translate(
                        offset: Offset(0, _dragOffset * 0.5),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PulsingImage(imageUrl: station.imageUrl, size: player.isPlaying ? 220 : 250),
                              const SizedBox(height: 20),
                              if (player.isPlaying) const AudioVisualizer(height: 60, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Информация и кнопки управления (смещается при свайпе)
                    Expanded(
                      flex: 2,
                      child: Transform.translate(
                        offset: Offset(0, _dragOffset * 0.3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                                    child: Text(
                                      station.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                            const SizedBox(height: 8),
                            AnimatedOpacity(
                              opacity: player.isPlaying ? 1.0 : 0.5,
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                player.isPlaying ? 'Сейчас играет 🎵' : 'На паузе ⏸',
                                style: TextStyle(color: subtitleColor, fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            // Кнопки управления
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: IconButton(
                                      icon: Icon(Icons.skip_previous, color: iconColor, size: 36),
                                      onPressed: player.hasPreviousStation ? () => player.previousStation() : null,
                                    ),
                                  ),
                                  AnimatedPlayButton(
                                    isPlaying: player.isPlaying,
                                    onPressed: () => player.togglePlayPause(),
                                    size: 48,
                                  ),
                                  Expanded(
                                    child: IconButton(
                                      icon: Icon(Icons.skip_next, color: iconColor, size: 36),
                                      onPressed: player.hasNextStation ? () => player.nextStation() : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Подсказка для свайпа (показывается только при перетаскивании)
                            if (_dragOffset > 10)
                              AnimatedOpacity(
                                opacity: (_dragOffset / 100).clamp(0.0, 0.8),
                                duration: const Duration(milliseconds: 50),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Отпустите, чтобы закрыть',
                                        style: TextStyle(color: subtitleColor, fontSize: 12),
                                      ),
                                      LinearProgressIndicator(
                                        value: (_dragOffset / (_screenHeight / 2)).clamp(0.0, 1.0),
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}