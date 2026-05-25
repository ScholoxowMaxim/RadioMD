import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/features/home/domain/station.dart';
import 'package:radiomd/features/home/data/stations_mock.dart';
import 'package:radiomd/core/services/player_service.dart';
import 'package:radiomd/features/player/presentation/full_player_screen.dart';
import 'package:radiomd/core/services/favorites_service.dart';

class FavoritesScreen extends StatelessWidget {
  final Set<String> favoriteIds;
  final VoidCallback? onFavoritesChanged;

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

    await player.play(station);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullPlayerScreen(favoritesService: favoritesService),
      ),
    );

    if (result == true && onFavoritesChanged != null) {
      onFavoritesChanged!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color.fromARGB(47, 255, 255, 255) : Colors.black54;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    final favoriteStations = mockStations
        .where((station) => favoriteIds.contains(station.id))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Избранное',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 20),
            if (favoriteStations.isEmpty)
              Expanded(
                child: Center(
                  child: Text('Нет избранных станций', style: TextStyle(color: subtitleColor)),
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                station.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.radio, color: textColor),
                              ),
                            ),
                            title: Text(station.name, style: TextStyle(color: textColor)),
                            subtitle: isCurrentStation
                                ? Text(
                                    isPlaying ? 'Сейчас играет' : 'На паузе',
                                    style: TextStyle(color: subtitleColor, fontSize: 12),
                                  )
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