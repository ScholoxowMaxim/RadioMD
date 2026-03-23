import 'package:flutter/material.dart';
import '../../../core/services/player_service.dart';
import '../../home/domain/station.dart';

class PlayerScreen extends StatefulWidget {
  final Station station;

  const PlayerScreen({super.key, required this.station});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final PlayerService _playerService = PlayerService();

  @override
  void initState() {
    super.initState();
    _playerService.play(widget.station);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.station.name)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            widget.station.imageUrl,
            height: 200,
          ),
          const SizedBox(height: 40),
          StreamBuilder(
            stream: _playerService.playerStateStream,
            builder: (context, snapshot) {
              final isPlaying = _playerService.isPlaying;

              return IconButton(
                iconSize: 80,
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle,
                ),
                onPressed: () {
                  _playerService.toggle();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}