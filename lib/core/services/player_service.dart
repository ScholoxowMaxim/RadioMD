import 'package:flutter/material.dart';
import 'package:radiomd/features/home/domain/station.dart';
import 'package:just_audio/just_audio.dart';

class PlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  
  Station? _currentStation;
  bool _isPlaying = false;
  
  // История прослушанных станций
  final List<Station> _history = [];
  int _historyIndex = -1;
  
  // 👇 ДОБАВЬТЕ ЭТО: список всех доступных станций
  List<Station> _allStations = [];
  
  void setAllStations(List<Station> stations) {
    _allStations = stations;
    notifyListeners();
  }

  Station? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;
  bool get hasNext => _historyIndex < _history.length - 1;
  bool get hasPrevious => _historyIndex > 0;
  
  // 👇 НОВЫЕ ГЕТТЕРЫ для навигации по всем станциям
  bool get hasNextStation {
    if (_allStations.isEmpty || _currentStation == null) return false;
    final currentIndex = _allStations.indexWhere((s) => s.id == _currentStation!.id);
    return currentIndex < _allStations.length - 1;
  }
  
  bool get hasPreviousStation {
    if (_allStations.isEmpty || _currentStation == null) return false;
    final currentIndex = _allStations.indexWhere((s) => s.id == _currentStation!.id);
    return currentIndex > 0;
  }
  
  // 👇 НОВЫЙ МЕТОД: следующая станция из списка
  void nextStation() {
    if (_allStations.isEmpty || _currentStation == null) return;
    final currentIndex = _allStations.indexWhere((s) => s.id == _currentStation!.id);
    if (currentIndex < _allStations.length - 1) {
      final nextStation = _allStations[currentIndex + 1];
      play(nextStation);
    }
  }
  
  // 👇 НОВЫЙ МЕТОД: предыдущая станция из списка
  void previousStation() {
    if (_allStations.isEmpty || _currentStation == null) return;
    final currentIndex = _allStations.indexWhere((s) => s.id == _currentStation!.id);
    if (currentIndex > 0) {
      final previousStation = _allStations[currentIndex - 1];
      play(previousStation);
    }
  }

  Future<void> play(Station station) async {
    // Если нажали на ту же станцию — переключаем play/pause
    if (_currentStation?.id == station.id) {
      togglePlayPause();
      return;
    }

    _currentStation = station;
    
    // Добавляем в историю
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(station);
    _historyIndex = _history.length - 1;
    
    try {
      await _player.setUrl(station.streamUrl);
      await _player.play();
      _isPlaying = true;
    } catch (e) {
      print('Ошибка воспроизведения: $e');
      _isPlaying = false;
    }
    
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void stop() {
    _player.stop();
    _isPlaying = false;
    _currentStation = null;
    notifyListeners();
  }

  // Старые методы (работают по истории)
  void next() {
    if (hasNext) {
      _historyIndex++;
      _currentStation = _history[_historyIndex];
      play(_currentStation!);
    }
  }

  void previous() {
    if (hasPrevious) {
      _historyIndex--;
      _currentStation = _history[_historyIndex];
      play(_currentStation!);
    }
  }

  final List<String> _favoriteIds = [];
  List<String> get favoriteIds => _favoriteIds;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
  // Добавьте этот метод в класс PlayerService
void updateFavoriteStatus(String stationId, bool isFavorite) {
  // Обновляем текущую станцию
  if (_currentStation?.id == stationId) {
    _currentStation?.isFavorite = isFavorite;
  }
  
  // Обновляем в истории
  for (var station in _history) {
    if (station.id == stationId) {
      station.isFavorite = isFavorite;
    }
  }
  
  // Обновляем в списке всех станций
  for (var station in _allStations) {
    if (station.id == stationId) {
      station.isFavorite = isFavorite;
    }
  }
  
  notifyListeners();
}
}