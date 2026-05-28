import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/core/services/player_service.dart';
import 'package:radiomd/core/services/favorites_service.dart';
import 'package:radiomd/features/player/presentation/animated_play_button.dart';

class FullPlayerScreen extends StatefulWidget {
  final FavoritesService favoritesService;

  const FullPlayerScreen({super.key, required this.favoritesService});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, player, _) {
        final station = player.currentStation;
        if (station == null) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Верхняя панель с кнопкой назад
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context, true), // 👈 Возвращаем true при выходе
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Картинка станции
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          station.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[900],
                            child: const Icon(Icons.radio, color: Colors.white, size: 80),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Название и кнопки управления
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        player.isPlaying ? 'Сейчас играет' : 'На паузе',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      const SizedBox(height: 40),

                      // Кнопки управления
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Предыдущая
                          IconButton(
                            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                            onPressed: player.hasPreviousStation ? () => player.previousStation() : null,
                          ),
                          const SizedBox(width: 20),

                          // Кнопка избранного
                          FutureBuilder<bool>(
                            future: widget.favoritesService.isFavorite(station.id),
                            builder: (context, snapshot) {
                              final isFavorite = snapshot.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.white,
                                  size: 32,
                                ),
                                onPressed: () async {
                                  // Переключаем избранное
                                  await widget.favoritesService.toggleFavorite(station.id);
                                  // Обновляем локальный статус
                                  setState(() {
                                    station.isFavorite = !isFavorite;
                                  });
                                  // Обновляем в PlayerService
                                  player.updateFavoriteStatus(station.id, !isFavorite);
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 20),

                          // Play/Pause
                          AnimatedPlayButton(
                            isPlaying: player.isPlaying,
                            onPressed: () => player.togglePlayPause(),
                            size: 48,
                          ),
                          const SizedBox(width: 20),

                          // Следующая
                          IconButton(
                            icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                            onPressed: player.hasNextStation ? () => player.nextStation() : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}