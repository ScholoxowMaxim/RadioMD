import 'package:flutter/material.dart';
import 'package:radiomd/features/home/domain/station.dart';
import 'package:audio_service/audio_service.dart';
import 'audio_player_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlayerService extends ChangeNotifier {
  
  final AudioPlayerHandler _audioHandler;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Station? _currentStation;
  bool _isPlaying = false;
  final List<Station> _history = [];
  int _historyIndex = -1;
  List<Station> _allStations = [];
  
  // Избранное
  Set<String> _favoriteIds = {};
  Set<String> get favoriteIds => _favoriteIds;

  PlayerService(this._audioHandler) {
      _audioHandler.onNext = nextStation;
  _audioHandler.onPrevious = previousStation;
    _audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

_audioHandler.mediaItem.listen((item) {

  if (item == null) return;

  final station = _allStations.firstWhere(
    (s) => s.name == item.title,
    orElse: () => _currentStation!,
  );

  _currentStation = station;

  notifyListeners();
});
    
    // Загружаем избранное при создании
    loadFavorites();
  }

  void setAllStations(List<Station> stations) {
    _allStations = stations;
    notifyListeners();
  }

  Station? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;
  bool get hasNext => _historyIndex < _history.length - 1;
  bool get hasPrevious => _historyIndex > 0;

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

  void nextStation() {
    if (_allStations.isEmpty || _currentStation == null) return;
    final currentIndex = _allStations.indexWhere((s) => s.id == _currentStation!.id);
    if (currentIndex < _allStations.length - 1) {
      final nextStation = _allStations[currentIndex + 1];
      play(nextStation);
    }
  }

  void previousStation() {
    if (_allStations.isEmpty || _currentStation == null) return;
    final currentIndex = _allStations.indexWhere((s) => s.id == _currentStation!.id);
    if (currentIndex > 0) {
      final prevStation = _allStations[currentIndex - 1];
      play(prevStation);
    }
  }

Future<void> play(Station station) async {

  // Если нажали на текущую станцию
  if (_currentStation?.id == station.id) {
    togglePlayPause();
    return;
  }

  // Сохраняем текущую станцию
  _currentStation = station;

  // История
  if (_historyIndex < _history.length - 1) {
    _history.removeRange(
      _historyIndex + 1,
      _history.length,
    );
  }

  _history.add(station);
  _historyIndex = _history.length - 1;

  // ВАЖНО:
  // тут должен быть station.id
  final mediaItem = MediaItem(
    id: station.id,
    album: 'RadioMD',
    title: station.name,
    artUri: Uri.parse(station.imageUrl),
  );

  // Обновляем media item
  await _audioHandler.updateMediaItem(
    mediaItem,
  );

  await _audioHandler.playStation(
    mediaItem,
    station.streamUrl,
  );

  // Обновляем UI
  notifyListeners();
}

void togglePlayPause() {

  if (_isPlaying) {
    _audioHandler.pause();
  } else {
    _audioHandler.play();
  }

  notifyListeners();
}

  void next() {
    if (hasNext) {
      _historyIndex++;
      final station = _history[_historyIndex];
      play(station);
    }
  }

  void previous() {
    if (hasPrevious) {
      _historyIndex--;
      final station = _history[_historyIndex];
      play(station);
    }
  }

  void stop() {
    _audioHandler.stop();
  }

void updateFavoriteStatus(
  String stationId,
  bool isFavorite,
) {
  for (final station in _allStations) {
    if (station.id == stationId) {
      station.isFavorite = isFavorite;
    }
  }

  if (_currentStation?.id == stationId) {
    _currentStation!.isFavorite =
        isFavorite;
  }

  notifyListeners();
}

  // ==================== МЕТОДЫ ДЛЯ ИЗБРАННОГО ====================

  Future<void> loadFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _favoriteIds.clear();
        notifyListeners();
        return;
      }

      final doc = await _firestore
          .collection('favorites')
          .doc(user.uid)
          .get();

      final data = doc.data();
      final ids = List<String>.from(data?['stationIds'] ?? []);
      _favoriteIds = ids.toSet();

      // Обновляем статус во всех станциях
      for (final station in _allStations) {
        station.isFavorite = _favoriteIds.contains(station.id);
      }
      
      notifyListeners();
    } catch (e) {
      print('Ошибка загрузки избранного: $e');
    }
  }

  Future<void> toggleFavorite(String stationId) async {
    final bool newState = !_favoriteIds.contains(stationId);
    
    if (newState) {
      _favoriteIds.add(stationId);
    } else {
      _favoriteIds.remove(stationId);
    }

    // Обновляем статус в станции
    final station = _allStations.firstWhere(
      (s) => s.id == stationId,
      orElse: () => Station(
        id: stationId,
        name: '',
        streamUrl: '',
        imageUrl: '',
      ),
    );
    station.isFavorite = newState;

    notifyListeners();

    // Сохраняем в Firestore
    await _saveFavoritesToFirestore();
  }

  bool isFavorite(String stationId) {
    return _favoriteIds.contains(stationId);
  }

  List<Station> getFavoriteStations() {
    return _allStations
        .where((station) => _favoriteIds.contains(station.id))
        .toList();
  }

  Future<void> _saveFavoritesToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('favorites').doc(user.uid).set({
        'stationIds': _favoriteIds.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка сохранения избранного: $e');
    }
  }

  // Слушаем изменения избранного в реальном времени из Firestore
  void listenToFavoritesChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _firestore
        .collection('favorites')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      final ids = List<String>.from(data?['stationIds'] ?? []);
      _favoriteIds = ids.toSet();

      for (final station in _allStations) {
        station.isFavorite = _favoriteIds.contains(station.id);
      }
      
      notifyListeners();
    });
  }
}