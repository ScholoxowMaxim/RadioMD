import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/core/services/player_service.dart';
import 'package:radiomd/core/services/favorites_service.dart';
import 'package:radiomd/features/home/presentation/widgets/gradient_background.dart';
import 'package:radiomd/features/home/presentation/widgets/pulsing_image.dart';
import 'package:radiomd/features/home/presentation/widgets/visualizer.dart';
import 'package:radiomd/features/player/presentation/animated_play_button.dart';


class FullPlayerScreen extends StatefulWidget {
  final FavoritesService favoritesService;

  const FullPlayerScreen({super.key, required this.favoritesService});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late AnimationController _visualizerController;
  late Animation<double> _visualizerFadeAnimation;
  late Animation<Offset> _imageSlideAnimation;
  double _dragOffset = 0;
  bool _isClosing = false;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    
    // Анимация для закрытия
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Анимация для визуализатора (появление)
    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _visualizerFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _visualizerController,
      curve: Curves.easeOut,
    ));
    
    // Анимация для обложки (подъём вверх)
    _imageSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.05),
    ).animate(CurvedAnimation(
      parent: _visualizerController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visualizerController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _visualizerController.dispose();
    super.dispose();
  }

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
    
    // Показываем индикатор перезагрузки
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Перезагрузка радио...'),
          ],
        ),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Останавливаем текущее воспроизведение
    player.stop();
    
    // Небольшая задержка
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Запускаем заново
    await player.play(station);
    
    _isReloading = false;
    
    // Визуальный фидбек
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final iconColor = isDark ? Colors.white : Colors.black87;
    final cardBgColor = isDark ? Colors.grey[900] : Colors.grey[100];

    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (RawKeyEvent event) {
        // Проверяем что нажата клавиша 'r' (без Shift)
        if (event is RawKeyDownEvent && 
            event.logicalKey == LogicalKeyboardKey.keyR &&
            !event.isShiftPressed) {
          final player = context.read<PlayerService>();
          if (player.currentStation != null) {
            _reloadRadio(player);
          }
        }
      },
      child: GradientBackground(
        child: PopScope(
          canPop: !_isClosing,
          onPopInvoked: (didPop) {
            if (!didPop && !_isClosing) {
              _closePlayer();
            }
          },
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              final opacity = (1 - (_dragOffset / 300)).clamp(0.0, 1.0);
              final offset = _dragOffset + (_slideAnimation.value * 500);
              
              return Transform.translate(
                offset: Offset(0, offset),
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onVerticalDragDown: (_) {
                _dragOffset = 0;
                _animationController.stop();
              },
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 0) {
                  _dragOffset += details.delta.dy;
                  if (_dragOffset > 300) {
                    _closePlayer();
                  } else {
                    setState(() {});
                  }
                }
              },
              onVerticalDragEnd: (details) {
                if (_dragOffset > 150) {
                  _closePlayer();
                } else {
                  setState(() {
                    _dragOffset = 0;
                  });
                }
              },
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Consumer<PlayerService>(
                  builder: (context, player, _) {
                    final station = player.currentStation;
                    if (station == null) return const SizedBox.shrink();
                    final isFavorite = station.isFavorite;

                    return SafeArea(
                      child: Column(
                        children: [
                          // Верхняя панель
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.keyboard_arrow_down, color: iconColor, size: 32),
                                  onPressed: _closePlayer,
                                ),
                                const Spacer(),
                                // Кнопка перезагрузки (R)
                                IconButton(
                                  icon: Icon(Icons.refresh, color: iconColor, size: 28),
                                  onPressed: () => _reloadRadio(player),
                                  tooltip: 'Перезагрузить радио (R)',
                                ),
                                IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : iconColor,
                                    size: 28,
                                  ),
                                  onPressed: () async {
                                    final newState = await widget.favoritesService
                                        .toggleFavorite(station.id);

                                    setState(() {
                                      station.isFavorite = newState;
                                    });

                                    player.updateFavoriteStatus(station.id, newState);
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Картинка станции с анимацией подъёма
                          AnimatedBuilder(
                            animation: _visualizerController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: _imageSlideAnimation.value,
                                child: child,
                              );
                            },
                            child: Expanded(
                              flex: player.isPlaying ? 3 : 4,
                              child: Center(
                                child: PulsingImage(
                                  imageUrl: station.imageUrl,
                                  size: player.isPlaying ? 220 : 250,
                                ),
                              ),
                            ),
                          ),

                          // Визуализатор с анимацией появления
                          AnimatedBuilder(
                            animation: _visualizerController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _visualizerFadeAnimation.value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - _visualizerFadeAnimation.value) * 20),
                                  child: child,
                                ),
                              );
                            },
                            child: player.isPlaying
                                ? const AudioVisualizer(
                                    height: 60,
                                    color: Colors.white,
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Название и кнопки управления
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    station.name,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}