import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:radiomd/features/home/domain/station.dart';
import 'package:radiomd/features/player/presentation/mini_player.dart';
import 'package:radiomd/features/player/presentation/full_player_screen.dart';
import 'package:radiomd/features/settings/presentation/settings_screen.dart';
import '../data/stations_mock.dart';
import '../../../core/services/player_service.dart';
import '../../../core/services/favorites_service.dart';
import 'package:radiomd/features/favorites/presentation/favorites_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:radiomd/features/home/presentation/widgets/recent_stations.dart';
import 'package:radiomd/features/home/presentation/genres_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FavoritesService _favoritesService = FavoritesService();

  int _currentIndex = 0;
  int _selectedTab = 0; // 0 - популярные, 1 - жанры
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _favoriteIds = {};
  bool _isLoading = true;
  List<Station> _popularStations = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _listenToFavoritesChanges();
    _loadPopularStations();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {  
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

  Future<void> _loadPopularStations() async {
    final player = context.read<PlayerService>();
    final popular = await player.getPopularStations();
    setState(() {
      _popularStations = popular.where((s) => s.isHidden != true).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      final ids = await _favoritesService.getFavoriteIds().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Таймаут загрузки избранного');
          return [];
        },
      );
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
    final player = context.read<PlayerService>();

    setState(() {
      station.isFavorite = newState;
      if (newState) {
        _favoriteIds.add(station.id);
      } else {
        _favoriteIds.remove(station.id);
      }
    });

    player.updateFavoriteStatus(station.id, newState);
  }

  List<Station> get _filteredStations {
    // Получаем все видимые станции (не скрытые)
    final visibleStations = mockStations.where((s) => s.isHidden != true).toList();
    
    // Если поиск пустой - показываем только видимые
    if (_searchQuery.isEmpty) return visibleStations;
    
    // Полное совпадение с секретным кодом
    if (_searchQuery.toLowerCase() == 'gachi') {
      final secretStations = mockStations.where((s) => s.isHidden == true).toList();
      return secretStations;
    }
    
    // Частичный ввод секретного кода - ничего не показываем
    if (_searchQuery.toLowerCase().startsWith('gach') && _searchQuery.length < 5) {
      return [];
    }
    
    // Обычный поиск по видимым станциям
    return visibleStations.where((station) =>
        station.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  /// Воспроизведение станции
  Future<void> _playStation(Station station) async { 
    final player = context.read<PlayerService>();
    await player.play(station);
    await _loadPopularStations(); // Обновляем популярные после прослушивания
  }

  /// Открыть полный плеер
  void _openFullPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullPlayerScreen(
          favoritesService: _favoritesService,
        ),
      ),
    );
  }

  void _showSecretStationFound() {
    // Проверяем есть ли секретная станция
    final secretStationExists = mockStations.any((s) => s.id == 'secret_69');
    
    if (!secretStationExists) return;
    
    // Вибрация
    HapticFeedback.heavyImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.egg_alt, color: Colors.amber, size: 40),
            SizedBox(width: 12),
            Text('СЕКРЕТ НАЙДЕН!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radio, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Вы нашли секретное радио!',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Код активирован: GACHI',
              style: TextStyle(color: Colors.amber.shade300, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _playSecretStation();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('СЛУШАТЬ СЕКРЕТНУЮ СТАНЦИЮ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playSecretStation() {
    // Безопасный поиск секретной станции
    final secretStation = mockStations.firstWhere(
      (s) => s.id == 'secret_69',
      orElse: () => Station(
        id: 'secret_69',
        name: 'GACHI RADIO',
        streamUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        imageUrl: 'https://via.placeholder.com/200/9c27b0/ffffff?text=SECRET',
        genre: 'secret',
        description: 'Секретная станция 🥚',
      ),
    );
    
    _playStation(secretStation);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎵 Секретное радио играет! Никому не рассказывай 🎵'),
        backgroundColor: Colors.deepPurple,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _currentIndex == 0
          ? _buildContent()
          : FavoritesScreen(
              favoriteIds: _favoriteIds,
              onFavoritesChanged: () => _loadFavorites(),
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(onTap: _openFullPlayer),
          BottomNavigationBar(
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            selectedItemColor: isDark ? Colors.white : Colors.black,
            unselectedItemColor: Colors.grey,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final searchBgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
    final isSecretSearch = _searchQuery.toLowerCase() == 'gachi';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Шапка с названием и кнопками
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RadioMD',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.category, color: subtitleColor),
                            tooltip: 'Жанры',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const GenresScreen()),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.settings, color: subtitleColor),
                            tooltip: 'Настройки',
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Поле поиска
                  Container(
                    decoration: BoxDecoration(
                      color: isSecretSearch ? Colors.amber.withOpacity(0.2) : searchBgColor,
                      borderRadius: BorderRadius.circular(30),
                      border: isSecretSearch
                          ? Border.all(color: Colors.amber, width: 2)
                          : null,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Поиск',
                        hintStyle: TextStyle(color: subtitleColor),
                        prefixIcon: Icon(Icons.search, color: isSecretSearch ? Colors.amber : subtitleColor),
                        suffixIcon: isSecretSearch
                            ? Icon(Icons.celebration, color: Colors.amber)
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        
                        // Пасхалка: точное совпадение с секретным кодом
                        if (value.toLowerCase() == 'gachi') {
                          _showSecretStationFound();
                        } else if (value.toLowerCase().startsWith('gach') && value.length < 5 && value.length >= 4) {
                          // Эффект "почти попал"
                          HapticFeedback.lightImpact();
                          
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🥚 Почти получилось... Попробуй "gachi" полностью!'),
                              duration: Duration(milliseconds: 1500),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Недавние станции (скрываем если секретный поиск)
                  if (!isSecretSearch) 
                    const RecentStations(),
                ],
              ),
            ),
          ),
          
          // Вкладки (скрываем если секретный поиск)
          if (!isSecretSearch)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTab('🔥 Популярные', 0),
                        const SizedBox(width: 16),
                        _buildTab('🎵 Жанры', 1),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          
          // Контент вкладок или секретный контент
          if (isSecretSearch)
            _buildSecretStationSliver()
          else if (_selectedTab == 0)
            _buildPopularStationsSliver()
          else
            _buildGenresGridSliver(),
          
          // Заголовок "Все станции" (скрываем если секретный поиск)
          if (!isSecretSearch)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text("Все станции", style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          
          // Вертикальный список всех станций
          if (!isSecretSearch)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final station = _filteredStations[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => _playStation(station),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(8)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(station.imageUrl, width: 44, height: 44, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.radio, color: textColor, size: 24)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(station.name, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                                  if (station.listenCount > 0)
                                    Text(
                                      '👂 ${station.listenCount} прослушиваний',
                                      style: TextStyle(color: Colors.grey, fontSize: 10),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(station.isFavorite ? Icons.favorite : Icons.favorite_border, color: station.isFavorite ? Colors.red : textColor, size: 22),
                                  onPressed: () => _toggleFavorite(station),
                                ),
                                const SizedBox(width: 16),
                                Consumer<PlayerService>(
                                  builder: (context, player, _) {
                                    final isCurrentStation = player.currentStation?.id == station.id;
                                    return Icon(
                                      isCurrentStation && player.isPlaying 
                                      ? Icons.pause 
                                      : Icons.play_arrow,
                                      color: textColor,
                                      size: 22,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _filteredStations.isEmpty ? 0 : _filteredStations.length,
              ),
            ),
          
          // Сообщение если ничего не найдено
          if (!isSecretSearch && _filteredStations.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text("Ничего не найдено", style: TextStyle(color: subtitleColor)),
                ),
              ),
            ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white30 : Colors.black26),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPopularStationsSliver() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    
    final stationsToShow = _popularStations.isEmpty 
        ? mockStations.where((s) => s.isHidden != true).take(5).toList() 
        : _popularStations.where((s) => s.isHidden != true).take(10).toList();
    
    if (stationsToShow.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: stationsToShow.length,
          itemBuilder: (context, index) {
            final station = stationsToShow[index];
            return GestureDetector(
              onTap: () => _playStation(station),
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(station.imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.radio, color: textColor, size: 28)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        station.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (station.listenCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '👂 ${station.listenCount}',
                          style: TextStyle(color: Colors.grey, fontSize: 9),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenresGridSliver() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    
    final visibleGenres = genres.where((g) => g.id != 'secret').toList();
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: visibleGenres.length,
          itemBuilder: (context, index) {
            final genre = visibleGenres[index];
            final count = mockStations
                .where((s) => s.genre == genre.id && s.isHidden != true)
                .length;
            
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenreDetailScreen(
                      genre: genre,
                      stations: mockStations
                          .where((s) => s.genre == genre.id && s.isHidden != true)
                          .toList(),
                    ),
                  ),
                );
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(genre.icon, size: 32, color: genre.color),
                    const SizedBox(height: 8),
                    Text(
                      genre.name,
                      style: TextStyle(color: textColor, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$count',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSecretStationSliver() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secretStation = mockStations.firstWhere(
      (s) => s.id == 'secret_69',
      orElse: () => Station(
        id: 'secret_69',
        name: 'GACHI RADIO',
        streamUrl: '',
        imageUrl: '',
        genre: 'secret',
        description: '🥚',
      ),
    );
    
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.egg_alt, size: 80, color: Colors.amber),
            ),
            const SizedBox(height: 24),
            Text(
              secretStation.name,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '🥚 СЕКРЕТНАЯ СТАНЦИЯ 🥚',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _playSecretStation(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('ВКЛЮЧИТЬ СЕКРЕТНОЕ РАДИО'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}