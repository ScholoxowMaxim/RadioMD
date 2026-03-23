import 'package:just_audio/just_audio.dart';
import 'dart:async';
import '../../features/home/domain/station.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  final StreamController<Station?> _stationController =
      StreamController<Station?>.broadcast();

  Station? _currentStation;

  Station? get currentStation => _currentStation;

  Stream<Station?> get stationStream => _stationController.stream;

  bool get isPlaying => _player.playing;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> play(Station station) async {
    _currentStation = station;
    _stationController.add(station);
    await _player.setUrl(station.streamUrl);
    await _player.play();
  }

  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else if (_currentStation != null) {
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentStation = null;
    _stationController.add(null);
  }

  void dispose() {
    _stationController.close();
    _player.dispose();
  }
}