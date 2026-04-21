import 'package:just_audio/just_audio.dart';
import 'dart:async';
import '../../features/home/domain/station.dart';

// Сервис для управления аудиоплеером и радиостанциями (синглтон)
class PlayerService {
  // Приватное статическое поле для хранения единственного экземпляра
  static final PlayerService _instance = PlayerService._internal();
  
  // Фабричный конструктор, возвращающий единственный экземпляр
  factory PlayerService() => _instance;
  
  // Приватный конструктор для внутреннего использования
  PlayerService._internal();

  // Экземпляр аудиоплеера
  final AudioPlayer _player = AudioPlayer();

  // Контроллер потока для уведомления о смене текущей станции
  final StreamController<Station?> _stationController =
      StreamController<Station?>.broadcast(); // broadcast - позволяет иметь несколько подписчиков

  // Текущая воспроизводимая станция
  Station? _currentStation;

  // Геттер для получения текущей станции (публичный доступ)
  Station? get currentStation => _currentStation;

  // Геттер для подписки на изменения текущей станции
  Stream<Station?> get stationStream => _stationController.stream;

  // Геттер, возвращающий статус воспроизведения
  bool get isPlaying => _player.playing;

  // Геттер для отслеживания состояния плеера
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // Метод для воспроизведения выбранной станции
  Future<void> play(Station station) async {
    _currentStation = station; // Сохраняем текущую станцию
    _stationController.add(station); // Уведомляем подписчиков о смене станции
    await _player.setUrl(station.streamUrl); // Устанавливаем URL потока
    await _player.play(); // Запускаем воспроизведение
  }

  // Метод для паузы/возобновления воспроизведения
  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause(); // Если играет - ставим на паузу
    } else if (_currentStation != null) {
      await _player.play(); // Если на паузе и есть станция - возобновляем
    }
  }

  // Метод для остановки воспроизведения
  Future<void> stop() async {
    await _player.stop(); // Останавливаем плеер
    _currentStation = null; // Сбрасываем текущую станцию
    _stationController.add(null); // Уведомляем подписчиков об остановке
  }

  // Метод для освобождения ресурсов
  void dispose() {
    _stationController.close(); // Закрываем поток, чтобы избежать утечек
    _player.dispose(); // Освобождаем ресурсы плеера
  }

  // Список избранных радиостанций
  final List<Station> _favorites = [];

  // Геттер для доступа к списку избранного (только чтение)
  List<Station> get favorites => _favorites;

  // Метод для добавления/удаления станции из избранного
  void toggleFavorite(Station station) {
    // Проверяем, есть ли уже станция в избранном
    if (_favorites.any((s) => s.id == station.id)) {
      // Если есть - удаляем
      _favorites.removeWhere((s) => s.id == station.id);
      station.isFavorite = false; // Обновляем статус у станции
    } else {
      // Если нет - добавляем
      _favorites.add(station);
      station.isFavorite = true; // Обновляем статус у станции
    }
  }
}