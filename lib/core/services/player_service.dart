import 'package:just_audio/just_audio.dart';

class PlayerService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String url) async {
    await _player.setUrl(url);
    _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  void dispose() {
    _player.dispose();
  }
}