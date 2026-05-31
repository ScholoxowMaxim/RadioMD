import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

Future<AudioPlayerHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.radiomd.radiomd2.channel.audio',
      androidNotificationChannelName: 'RadioMD Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  Function()? onNext;
  Function()? onPrevious;
 AudioPlayerHandler() {
    _player.playbackEventStream
        .map(_transformEvent)
        .pipe(playbackState);
  }

  Future<void> playStation(
    MediaItem item,
    String url,
  ) async {

    mediaItem.add(item);

    await _player.setUrl(url);

    await _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
Future<void> skipToNext() async {

  if (onNext != null) {
    onNext!();
  }
}

@override
Future<void> skipToPrevious() async {

  if (onPrevious != null) {
    onPrevious!();
  }
}

  @override
  Future<void> seek(Duration position) =>
      _player.seek(position);

  PlaybackState _transformEvent(
    PlaybackEvent event,
  ) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing)
          MediaControl.pause
        else
          MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.playPause,
      },
      androidCompactActionIndices:
          const [0, 1, 3],
      processingState: const {
        ProcessingState.idle:
            AudioProcessingState.idle,
        ProcessingState.loading:
            AudioProcessingState.loading,
        ProcessingState.buffering:
            AudioProcessingState.buffering,
        ProcessingState.ready:
            AudioProcessingState.ready,
        ProcessingState.completed:
            AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition:
          _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  Future<void> updateMediaItem(
    MediaItem item,
  ) async {
    mediaItem.add(item);
  }
}