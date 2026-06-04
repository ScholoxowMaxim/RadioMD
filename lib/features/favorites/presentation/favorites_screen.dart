import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/features/home/domain/station.dart';
import 'package:radiomd/core/services/player_service.dart';
import 'package:radiomd/features/player/presentation/full_player_screen.dart';

/// Экран избранных станций
/// Использует данные из PlayerService, а не загружает их повторно
class FavoritesScreen extends StatelessWidget {
  final Set<String> favoriteIds;

  const FavoritesScreen({
    super.key,
    required this.favoriteIds,
  });

  void _playStation(BuildContext context, Station station) {
    context.read<PlayerService>().play(station);
  }

  void _openFullPlayer(BuildContext context, Station station) async {
    final player = context.read<PlayerService>();
    await player.play(station);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final favoriteStations = player.getFavoriteStations(); // Берем из сервиса
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Избранное', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 20),
            if (favoriteStations.isEmpty)
              Expanded(
                child: Center(child: Text('Нет избранных станций', style: TextStyle(color: subtitleColor))),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: favoriteStations.length,
                  itemBuilder: (context, index) {
                    final station = favoriteStations[index];
                    final isCurrentStation = player.currentStation?.id == station.id;
                    final isPlaying = isCurrentStation && player.isPlaying;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(imageUrl: station.imageUrl,
                          placeholder: (context, url) => CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Icon(Icons.radio),
                          )
                        ),
                        title: Text(station.name, style: TextStyle(color: textColor)),
                        subtitle: isCurrentStation
                            ? Text(isPlaying ? 'Сейчас играет' : 'На паузе', style: TextStyle(color: subtitleColor, fontSize: 12))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: textColor),
                              onPressed: () => _playStation(context, station),
                            ),
                            IconButton(
                              icon: Icon(Icons.playlist_play, color: textColor),
                              onPressed: () => _openFullPlayer(context, station),
                            ),
                          ],
                        ),
                        onTap: () => _openFullPlayer(context, station),
                      ),
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