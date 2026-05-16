import 'package:flutter/material.dart';
import 'package:radiomd/features/home/domain/station.dart';
import 'package:radiomd/features/player/presentation/mini_player.dart';
import 'package:radiomd/features/player/presentation/full_player_screen.dart';
import '../data/stations_mock.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/favorites_service.dart';
import 'package:radiomd/features/favorites/presentation/favorites_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final FavoritesService _favoritesService = FavoritesService();

  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _favoriteIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _listenToFavoritesChanges(); 
    
WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {  // 👈 ДОБАВЬТЕ ЭТУ ПРОВЕРКУ
      try {
        final player = context.read<PlayerService>();
        player.setAllStations(mockStations);
      } catch (e) {
        print('Ошибка инициализации плеера: $e');
      }
    }
  });

  }

void _listenToFavoritesChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    FirebaseFirestore.instance
        .collection('favorites')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      final data = snapshot.data();
      final stationIds = List<String>.from(data?['stationIds'] ?? []);
      
      setState(() {
        _favoriteIds = stationIds.toSet();
        for (final station in mockStations) {
          station.isFavorite = _favoriteIds.contains(station.id);
        }
      });
    });
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      final ids = await _favoritesService.getFavoriteIds();
      if (!mounted) return;
      setState(() {
        _favoriteIds = ids.toSet();
        for (final station in mockStations) {
          station.isFavorite = _favoriteIds.contains(station.id);
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки избранного: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite(Station station) async {
    final newState = await _favoritesService.toggleFavorite(station.id);
    setState(() {
      station.isFavorite = newState;
      if (newState) {
        _favoriteIds.add(station.id);
      } else {
        _favoriteIds.remove(station.id);
      }
    });
  }

  List<Station> get _filteredStations {
    if (_searchQuery.isEmpty) return mockStations;
    return mockStations.where((station) =>
        station.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  /// Воспроизведение станции
  Future<void> _playStation(Station station) async {
    // ✅ Используем PlayerService из провайдера
    final player = context.read<PlayerService>();
    await player.play(station);
    // Не нужно setState, Consumer сам обновится
  }

  /// Открыть полный плеер
/// Открыть полный плеер
  void _openFullPlayer() async {
    // Ждем результат от FullPlayerScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullPlayerScreen(favoritesService: _favoritesService),
      ),
    );
    
    // Если вернулись с изменениями (добавили/удалили избранное)
    if (result == true) {
      // Перезагружаем список избранного
      _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
body: _currentIndex == 0
    ? _buildContent()
    : FavoritesScreen(
        favoriteIds: _favoriteIds,
        onFavoritesChanged: () {
          // Обновляем список избранного при изменениях
          _loadFavorites();
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(onTap: _openFullPlayer),
          BottomNavigationBar(
            backgroundColor: Colors.black,
            elevation: 0,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home, size: 28), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.favorite, size: 28), label: ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RadioMD',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  tooltip: 'Выйти',
                  onPressed: () => FirebaseAuth.instance.signOut(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Поиск',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Популярные станции", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: mockStations.length,
                itemBuilder: (context, index) {
                  final station = mockStations[index];
                  return GestureDetector(
                    onTap: () => _playStation(station),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(station.imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.radio, color: Colors.white, size: 28)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(station.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text("Все станции", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredStations.isEmpty
                  ? Center(child: Text("Ничего не найдено", style: TextStyle(color: Colors.white.withOpacity(0.5))))
                  : ListView.builder(
                      itemCount: _filteredStations.length,
                      itemBuilder: (context, index) {
                        final station = _filteredStations[index];
                        return GestureDetector(
                          onTap: () => _playStation(station),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(station.imageUrl, width: 44, height: 44, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.radio, color: Colors.white, size: 24)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Text(station.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(station.isFavorite ? Icons.favorite : Icons.favorite_border, color: station.isFavorite ? Colors.red : Colors.white, size: 22),
                                      onPressed: () => _toggleFavorite(station),
                                    ),
                                    const SizedBox(width: 16),
                                    // ✅ Consumer уже есть - он будет обновляться автоматически
                                    Consumer<PlayerService>(
                                      builder: (context, player, _) {
                                        final isCurrentStation = player.currentStation?.id == station.id;
                                        return Icon(
                                          isCurrentStation && player.isPlaying ? Icons.pause : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 22,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}