import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/core/services/player_service.dart';
import 'package:radiomd/features/player/presentation/animated_play_button.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;

  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Добавьте проверку наличия провайдера
    try {
      final player = context.watch<PlayerService>();
      final station = player.currentStation;

      if (station == null) return const SizedBox.shrink();

      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: 64,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[900],
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
                    errorBuilder: (_, __, ___) => const Icon(Icons.radio, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    station.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedPlayButton(
                  isPlaying: player.isPlaying,
                  onPressed: () => player.togglePlayPause(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // Если провайдера нет, ничего не показываем
      return const SizedBox.shrink();
    }
  }
}