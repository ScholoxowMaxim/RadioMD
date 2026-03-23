import 'package:flutter/material.dart';
import 'package:radiomd/features/home/domain/station.dart';
import '../../../core/services/player_service.dart';


class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final _playerService = PlayerService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Station?>(
      stream: _playerService.stationStream,
      builder: (context, snapshot) {
        final station = snapshot.data;

        if (station == null) return const SizedBox();

        return Container(
          height: 70,
          color: Colors.grey[900],
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  station.name,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              StreamBuilder(
                stream: _playerService.playerStateStream,
                builder: (context, _) {
                  return IconButton(
                    icon: Icon(
                      _playerService.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      await _playerService.toggle();
                    },
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }
}