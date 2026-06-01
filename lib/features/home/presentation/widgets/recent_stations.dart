import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/core/services/player_service.dart';
import 'package:radiomd/features/home/domain/station.dart';

class RecentStations extends StatelessWidget {
  const RecentStations({super.key});

  void _playStation(BuildContext context, Station station) {
    final player = context.read<PlayerService>();
    player.play(station);
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final recentStations = player.recentStations;
    
    if (recentStations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🕐 Недавние',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Очистить историю'),
                    content: const Text('Вы уверены, что хотите очистить список недавних станций?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () {
                          player.clearRecentStations();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Очистить', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.delete_outline, color: subtitleColor, size: 16),
              label: Text(
                'Очистить',
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(60, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110, // Увеличил высоту
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentStations.length,
            itemBuilder: (context, index) {
              final station = recentStations[index];
              final isCurrentStation = player.currentStation?.id == station.id;
              
              return GestureDetector(
                onTap: () => _playStation(context, station),
                child: Container(
                  width: 90, // Увеличил ширину
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.only(bottom: 4), // Добавил отступ снизу
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Важно!
                    children: [
                      // Иконка станции
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                station.imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.radio,
                                  color: textColor,
                                  size: 30,
                                ),
                              ),
                            ),
                            if (isCurrentStation && player.isPlaying)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Название станции - исправлено
                      Container(
                        width: 80,
                        constraints: const BoxConstraints(
                          maxHeight: 32, // Максимум 2 строки по 16px
                        ),
                        child: Text(
                          station.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                            height: 1.2, // Уменьшил межстрочный интервал
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}