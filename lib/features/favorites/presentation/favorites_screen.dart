import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/features/home/domain/station.dart';
import 'package:radiomd/features/home/data/stations_mock.dart';
import 'package:radiomd/core/services/player_service.dart';
import 'package:radiomd/features/player/presentation/full_player_screen.dart';
import 'package:radiomd/core/services/favorites_service.dart';

class FavoritesScreen extends StatelessWidget {
  final Set<String> favoriteIds;
  final VoidCallback? onFavoritesChanged; // Добавляем callback для обновления

  const FavoritesScreen({
    super.key, 
    required this.favoriteIds,
    this.onFavoritesChanged,
  });

  void _playStation(BuildContext context, Station station) {
    final player = context.read<PlayerService>();
    player.play(station);
  }

  void _openFullPlayer(BuildContext context, Station station) async {
    final player = context.read<PlayerService>();
    final favoritesService = FavoritesService();
    
    // Сначала запускаем станцию
    await player.play(station);
    
    // Открываем полный плеер
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullPlayerScreen(
          favoritesService: favoritesService,
        ),
      ),
    );
    
    // Если избранное изменилось, обновляем
    if (result == true && onFavoritesChanged != null) {
      onFavoritesChanged!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteStations = mockStations
        .where((station) => favoriteIds.contains(station.id))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Избранное',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (favoriteStations.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Нет избранных станций',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: favoriteStations.length,
                  itemBuilder: (context, index) {
                    final station = favoriteStations[index];
                    return Consumer<PlayerService>(
                      builder: (context, player, _) {
                        final isCurrentStation = player.currentStation?.id == station.id;
                        final isPlaying = isCurrentStation && player.isPlaying;
                        
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              station.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.radio,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          title: Text(
                            station.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: isCurrentStation
                              ? Text(
                                  isPlaying ? 'Сейчас играет' : 'На паузе',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                onPressed: () => _playStation(context, station),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.playlist_play,
                                  color: Colors.white,
                                ),
                                onPressed: () => _openFullPlayer(context, station),
                              ),
                            ],
                          ),
                          onTap: () => _openFullPlayer(context, station),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}