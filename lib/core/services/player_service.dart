import 'dart:async';

import 'package:flutter/material.dart';
import 'package:radiomd/features/home/domain/station.dart';
import 'package:audio_service/audio_service.dart';
import 'audio_player_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // Недавние станции
  final List<Station> _recentStations = [];
  List<Station> get recentStations => _recentStations;
  
  // Флаги для предотвращения дублирования
  bool _isLoadingRecent = false;
  String _lastUserId = '';
  
  // Для отписки от слушателей
  StreamSubscription? _favoritesSubscription;

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
    
    // Загружаем историю при создании
    _loadRecentStations();
    
    // Слушаем изменения авторизации с защитой от дублирования
    FirebaseAuth.instance.authStateChanges().listen((user) {
      final userId = user?.uid ?? '';
      
      // Защита от множественных вызовов
      if (_lastUserId == userId) {
        print('Пропуск дублирующего события для пользователя: $userId');
        return;
      }
      _lastUserId = userId;
      
      print('Обработка смены пользователя: ${user?.uid ?? "null"}');
      
      if (user != null) {
        // Пользователь вошел - загружаем его историю и избранное
        _setupFavoritesListener(); // Пересоздаем слушатель
        _loadRecentStations();
        loadFavorites();
      } else {
        // Пользователь вышел - очищаем и отписываемся
        _cleanupFavoritesListener();
        _recentStations.clear();
        _favoriteIds.clear();
        notifyListeners();
      }
    });
  }

  void setAllStations(List<Station> stations) {
    _allStations = stations;
    
    // Обновляем историю актуальными данными
    for (int i = 0; i < _recentStations.length; i++) {
      final freshStation = _allStations.firstWhere(
        (s) => s.id == _recentStations[i].id,
        orElse: () => _recentStations[i],
      );
      _recentStations[i] = freshStation;
    }
    
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
      station.listenCount++;
      await _incrementListenCount(station.id);
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
    
    // Добавляем в недавние
    _addToRecent(station);

    final mediaItem = MediaItem(
      id: station.id,
      album: 'RadioMD',
      title: station.name,
      artUri: Uri.parse(station.imageUrl),
    );

    await _audioHandler.updateMediaItem(mediaItem);
    await _audioHandler.playStation(mediaItem, station.streamUrl);
    notifyListeners();
  }

  Future<void> _incrementListenCount(String stationId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final docRef = _firestore.collection('listen_stats').doc(stationId);
    await docRef.set({
      'count': FieldValue.increment(1),
      'lastListenedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    print('Ошибка сохранения статистики: $e');
  }
}

// Получение популярных станций
Future<List<Station>> getPopularStations() async {
  try {
    final snapshot = await _firestore
        .collection('listen_stats')
        .orderBy('count', descending: true)
        .limit(10)
        .get();
    
    final popularIds = snapshot.docs.map((doc) => doc.id).toList();
    
    return _allStations
        .where((station) => popularIds.contains(station.id))
        .toList();
  } catch (e) {
    print('Ошибка загрузки популярных: $e');
    // Возвращаем локально отсортированные
    final sorted = List<Station>.from(_allStations);
    sorted.sort((a, b) => b.listenCount.compareTo(a.listenCount));
    return sorted.take(10).toList();
  }
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

  /// Очищает текущую станцию (закрывает мини-плеер)
  void clearCurrentStation() {
    _currentStation = null;
    _isPlaying = false;
    notifyListeners();
  }

  void updateFavoriteStatus(String stationId, bool isFavorite) {
    for (final station in _allStations) {
      if (station.id == stationId) {
        station.isFavorite = isFavorite;
      }
    }
    if (_currentStation?.id == stationId) {
      _currentStation!.isFavorite = isFavorite;
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

  /// Слушаем изменения избранного в реальном времени из Firestore
  void _setupFavoritesListener() {
    // Отписываемся от старого слушателя
    _cleanupFavoritesListener();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _favoritesSubscription = _firestore
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
    }, onError: (error) {
      print('Ошибка слушателя избранного: $error');
    });
  }
  
  /// Отписываемся от слушателя избранного
  void _cleanupFavoritesListener() {
    if (_favoritesSubscription != null) {
      _favoritesSubscription!.cancel();
      _favoritesSubscription = null;
    }
  }

  // ==================== МЕТОДЫ ДЛЯ НЕДАВНИХ СТАНЦИЙ ====================

  /// Добавление станции в недавние
  void _addToRecent(Station station) {
    // Удаляем если уже есть
    _recentStations.removeWhere((s) => s.id == station.id);
    // Добавляем в начало
    _recentStations.insert(0, station);
    // Оставляем только 10 последних
    if (_recentStations.length > 10) {
      _recentStations.removeLast();
    }
    // Сохраняем историю для конкретного пользователя
    _saveRecentStations();
    notifyListeners();
  }

  /// Очистить историю (для текущего пользователя)
  Future<void> clearRecentStations() async {
    _recentStations.clear();
    await _saveRecentStations();
    notifyListeners();
  }

  /// Очистить историю для конкретного пользователя при выходе
  Future<void> clearRecentStationsForUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    _recentStations.clear();
    final prefs = await SharedPreferences.getInstance();
    final String userKey = 'recent_stations_${user.uid}';
    await prefs.remove('${userKey}_ids');
    await prefs.remove('${userKey}_names');
    await prefs.remove('${userKey}_images');
    notifyListeners();
  }

  /// Принудительно загрузить историю для текущего пользователя
  Future<void> reloadRecentStationsForCurrentUser() async {
    if (_isLoadingRecent) {
      print('Уже загружается история, пропускаем');
      return;
    }
    print('Перезагрузка истории для текущего пользователя');
    await _loadRecentStations();
  }

  /// Сохранение истории в SharedPreferences
  Future<void> _saveRecentStations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Пользователь не авторизован, история не сохранена');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final String userKey = 'recent_stations_${user.uid}';
      
      final List<String> ids = _recentStations.map((s) => s.id).toList();
      final List<String> names = _recentStations.map((s) => s.name).toList();
      final List<String> images = _recentStations.map((s) => s.imageUrl).toList();
      
      await prefs.setStringList('${userKey}_ids', ids);
      await prefs.setStringList('${userKey}_names', names);
      await prefs.setStringList('${userKey}_images', images);
      
      print('История сохранена для пользователя ${user.uid}: ${ids.length} станций');
    } catch (e) {
      print('Ошибка сохранения истории: $e');
    }
  }

  /// Загрузка истории из SharedPreferences
  Future<void> _loadRecentStations() async {
    if (_isLoadingRecent) {
      print('Уже загружается история, пропускаем');
      return;
    }
    
    _isLoadingRecent = true;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Пользователь не авторизован, история не загружена');
        _recentStations.clear();
        notifyListeners();
        _isLoadingRecent = false;
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final String userKey = 'recent_stations_${user.uid}';
      
      final List<String>? ids = prefs.getStringList('${userKey}_ids');
      final List<String>? names = prefs.getStringList('${userKey}_names');
      final List<String>? images = prefs.getStringList('${userKey}_images');
      
      _recentStations.clear();
      
      if (ids != null && ids.isNotEmpty) {
        for (int i = 0; i < ids.length; i++) {
          final id = ids[i];
          final name = names != null && i < names.length ? names[i] : '';
          final imageUrl = images != null && i < images.length ? images[i] : '';
          
          // Ищем станцию в общем списке
          Station? foundStation;
          if (_allStations.isNotEmpty) {
            foundStation = _allStations.firstWhere(
              (s) => s.id == id,
              orElse: () => Station(
                id: id,
                name: name,
                streamUrl: '',
                imageUrl: imageUrl,
              ),
            );
          } else {
            foundStation = Station(
              id: id,
              name: name,
              streamUrl: '',
              imageUrl: imageUrl,
            );
          }
          
          _recentStations.add(foundStation);
        }
        print('История загружена для пользователя ${user.uid}: ${_recentStations.length} станций');
        notifyListeners();
      } else {
        print('История пуста для пользователя ${user.uid}');
      }
    } catch (e) {
      print('Ошибка загрузки истории: $e');
    } finally {
      _isLoadingRecent = false;
    }
  }
  
  @override
  void dispose() {
    _cleanupFavoritesListener();
    super.dispose();
  }
}