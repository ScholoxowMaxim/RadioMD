import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/core/services/player_service.dart';
import 'package:radiomd/features/player/presentation/animated_play_button.dart';
import 'package:radiomd/features/player/presentation/full_player_screen.dart';

/// Мини-плеер в нижней части экрана
/// Поддерживает свайп вверх для открытия полноэкранного режима
/// и свайп вниз для закрытия/остановки воспроизведения
class MiniPlayer extends StatefulWidget {
  final VoidCallback onTap;

  const MiniPlayer({super.key, required this.onTap});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  double _dragOffset = 0;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(
      begin: 0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Закрытие мини-плеера с анимацией свайпа вниз
  void _closeMiniPlayer(PlayerService player) {
    if (_isClosing) return;
    _isClosing = true;
    
    _animationController.forward().then((_) {
      player.stop();
      player.clearCurrentStation();
      _isClosing = false;
      _dragOffset = 0;
      _animationController.reset();
      if (mounted) setState(() {});
    });
  }

  /// Открытие полноэкранного плеера (без передачи favoritesService)
  void _openFullPlayer(PlayerService player) {
    if (_isClosing) return;
    
    final station = player.currentStation;
    if (station == null) return;
    
    // FullPlayerScreen больше не требует favoritesService
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FullPlayerScreen(), // Убрали favoritesService
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final player = context.watch<PlayerService>();
      final station = player.currentStation;

      if (station == null || _isClosing) return const SizedBox.shrink();

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final backgroundColor = isDark ? Colors.grey[900] : Colors.grey[200];
      final textColor = isDark ? Colors.white : Colors.black87;

      return AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          final opacity = (1 - (_dragOffset / 150)).clamp(0.0, 1.0);
          
          return Transform.translate(
            offset: Offset(0, _dragOffset + _slideAnimation.value * 80),
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
            // Свайп вниз - закрытие
            if (details.delta.dy > 0) {
              _dragOffset += details.delta.dy;
              if (_dragOffset > 200) {
                _closeMiniPlayer(player);
              } else {
                setState(() {});
              }
            }
            // Свайп вверх - открытие полноэкранного плеера
            else if (details.delta.dy < 0) {
              _dragOffset += details.delta.dy;
              if (_dragOffset < -100) {
                _openFullPlayer(player);
                _dragOffset = 0;
              } else {
                setState(() {});
              }
            }
          },
          onVerticalDragEnd: (details) {
            // Закрытие при свайпе вниз
            if (_dragOffset > 80) {
              _closeMiniPlayer(player);
            } 
            // Открытие при свайпе вверх
            else if (_dragOffset < -50) {
              _openFullPlayer(player);
              _dragOffset = 0;
            }
            else {
              setState(() {
                _dragOffset = 0;
              });
            }
          },
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: Image.network(
                    station.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.radio, color: textColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    station.name,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedPlayButton(
                  isPlaying: player.isPlaying,
                  onPressed: () => player.togglePlayPause(),
                ),
                const SizedBox(width: 8),
                // Иконка-подсказка для свайпа вверх
                Icon(
                  Icons.drag_handle,
                  color: textColor.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}