import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../home/domain/station.dart';
import 'animated_play_button.dart';

class PlayerScreen extends StatefulWidget {
  final Station station;
  final FavoritesService favoritesService;

  const PlayerScreen({
    super.key,
    required this.station,
    required this.favoritesService,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.station.isFavorite;
    
    // Запускаем воспроизведение
    final player = context.read<PlayerService>();
    player.play(widget.station);
  }

  Future<void> _toggleFavorite() async {
    final newState = await widget.favoritesService.toggleFavorite(widget.station.id);
    setState(() {
      _isFavorite = newState;
      widget.station.isFavorite = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, player, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Верхняя панель
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.white,
                          size: 28,
                        ),
                        onPressed: _toggleFavorite,
                      ),
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
                          widget.station.imageUrl,
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

                // Название и кнопки
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.station.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        player.currentStation?.id == widget.station.id && player.isPlaying
                            ? 'Сейчас играет'
                            : 'На паузе',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      const SizedBox(height: 40),

                      // Кнопки управления
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                            onPressed: player.hasPrevious ? () => player.previous() : null,
                          ),
                          const SizedBox(width: 30),

                          AnimatedPlayButton(
                            isPlaying: player.isPlaying,
                            onPressed: () => player.togglePlayPause(),
                            size: 48,
                          ),
                          const SizedBox(width: 30),

                          IconButton(
                            icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                            onPressed: player.hasNext ? () => player.next() : null,
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