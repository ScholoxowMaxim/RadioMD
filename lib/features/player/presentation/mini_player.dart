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
    // Отслеживаем текущую воспроизводимую станцию
    return StreamBuilder<Station?>(
      stream: _playerService.stationStream,
      builder: (context, snapshot) {
        final station = snapshot.data;

        // Если ничего не играет - не показываем мини-плеер
        if (station == null) return const SizedBox();

        return Container(
          height: 70,
          color: Colors.grey[900],
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Название текущей станции
              Expanded(
                child: Text(
                  station.name,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              // Кнопка play/pause с отслеживанием состояния плеера
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