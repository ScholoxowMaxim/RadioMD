import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:radiomd/features/home/domain/station.dart';
import 'package:radiomd/features/player/presentation/mini_player.dart';
import 'package:radiomd/features/player/presentation/full_player_screen.dart';
import 'package:radiomd/features/settings/presentation/settings_screen.dart';
import '../data/stations_mock.dart';
import '../../../core/services/player_service.dart';
import 'package:radiomd/features/favorites/presentation/favorites_screen.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/features/home/presentation/widgets/recent_stations.dart';
import 'package:radiomd/features/home/presentation/genres_screen.dart';

/// Главный экран приложения
/// Содержит: поиск, недавние станции, популярные, жанры, список всех станций
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0 - главная, 1 - избранное
  int _selectedTab = 0; // 0 - популярные, 1 - жанры
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoadingPopular = true;
  List<Station> _popularStations = [];

  @override
  void initState() {
    super.initState();
    _loadPopularStations();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final player = context.read<PlayerService>();
        player.setAllStations(mockStations);
      }
    });
  }

  Future<void> _loadPopularStations() async {
    final player = context.read<PlayerService>();
    final popular = await player.getPopularStations();
    setState(() {
      _popularStations = popular;
      _isLoadingPopular = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Фильтрация станций по поисковому запросу + секретный код "gachi"
  List<Station> get _filteredStations {
    final visibleStations = mockStations.where((s) => s.isHidden != true).toList();
    
    if (_searchQuery.isEmpty) return visibleStations;
    
    // Секретный код для показа скрытой станции
    if (_searchQuery.toLowerCase() == 'gachi') {
      return mockStations.where((s) => s.isHidden == true).toList();
    }
    
    // Частичный ввод кода - ничего не показываем (интрига)
    if (_searchQuery.toLowerCase().startsWith('gach') && _searchQuery.length < 5) {
      return [];
    }
    
    return visibleStations.where((station) =>
        station.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Future<void> _playStation(Station station) async {
    final player = context.read<PlayerService>();
    await player.play(station);
    await _loadPopularStations(); // Обновляем рейтинг
  }

  void _openFullPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FullPlayerScreen(),
      ),
    );
  }

  /// Пасхалка: диалог при нахождении секретной станции
  void _showSecretStationFound() {
    HapticFeedback.heavyImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
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
    final player = context.watch<PlayerService>(); // Слушаем изменения плеера

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _currentIndex == 0
          ? _buildContent(player)
          : FavoritesScreen(
              favoriteIds: player.favoriteIds, // Берем из PlayerService
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

  Widget _buildContent(PlayerService player) {
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
                  // Шапка
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RadioMD',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
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
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => const SettingsScreen())
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Поле поиска с пасхалкой
                  Container(
                    decoration: BoxDecoration(
                      color: isSecretSearch ? Colors.amber.withOpacity(0.2) : searchBgColor,
                      borderRadius: BorderRadius.circular(30),
                      border: isSecretSearch ? Border.all(color: Colors.amber, width: 2) : null,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Поиск',
                        hintStyle: TextStyle(color: subtitleColor),
                        prefixIcon: Icon(Icons.search, color: isSecretSearch ? Colors.amber : subtitleColor),
                        suffixIcon: isSecretSearch ? Icon(Icons.celebration, color: Colors.amber) : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        if (value.toLowerCase() == 'gachi') _showSecretStationFound();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (!isSecretSearch) const RecentStations(),
                ],
              ),
            ),
          ),
          
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
          
          if (isSecretSearch)
            _buildSecretStationSliver()
          else if (_selectedTab == 0)
            _buildPopularStationsSliver()
          else
            _buildGenresGridSliver(),
          
          if (!isSecretSearch)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text("Все станции", style: TextStyle(color: subtitleColor, fontSize: 14)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          
          // Список всех станций
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
                                child: CachedNetworkImage(
                                  imageUrl: station.imageUrl,
                                  placeholder: (context, url) => CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => Icon(Icons.radio),
                                )
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(station.name, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                                  if (station.listenCount > 0)
                                    Text('👂 ${station.listenCount}', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(station.isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: station.isFavorite ? Colors.red : textColor, size: 22),
                                  onPressed: () => player.toggleFavorite(station.id),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  player.currentStation?.id == station.id && player.isPlaying
                                      ? Icons.pause : Icons.play_arrow,
                                  color: textColor, size: 22,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _filteredStations.length,
              ),
            ),
          
          if (!isSecretSearch && _filteredStations.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text("Ничего не найдено", style: TextStyle(color: subtitleColor)),
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
          color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white30 : Colors.black26)),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPopularStationsSliver() {
    if (_isLoadingPopular) {
      return const SliverToBoxAdapter(child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())));
    }
    
    if (_popularStations.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _popularStations.length,
          itemBuilder: (context, index) {
            final station = _popularStations[index];
            return GestureDetector(
              onTap: () => _playStation(station),
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: station.imageUrl,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.radio),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(station.name, textAlign: TextAlign.center,
                      style: TextStyle(color: textColor, fontSize: 11), maxLines: 2),
                    if (station.listenCount > 0)
                      Text('👂 ${station.listenCount}', style: TextStyle(color: Colors.grey, fontSize: 9)),
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
            final count = mockStations.where((s) => s.genre == genre.id && !s.isHidden).length;
            
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenreDetailScreen(
                      genre: genre,
                      stations: mockStations.where((s) => s.genre == genre.id && !s.isHidden).toList(),
                    ),
                  ),
                );
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(genre.icon, size: 32, color: genre.color),
                    const SizedBox(height: 8),
                    Text(genre.name, style: TextStyle(color: textColor, fontSize: 12), textAlign: TextAlign.center),
                    Text('$count', style: TextStyle(color: Colors.grey, fontSize: 10)),
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
    final secretStation = mockStations.firstWhere((s) => s.id == 'secret_69');
    
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.purple]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)],
              ),
              child: const Icon(Icons.egg_alt, size: 80, color: Colors.amber),
            ),
            const SizedBox(height: 24),
            Text(secretStation.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            const Text('🥚 СЕКРЕТНАЯ СТАНЦИЯ 🥚', style: TextStyle(fontSize: 14, color: Colors.amber, letterSpacing: 2)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _playSecretStation,
              icon: const Icon(Icons.play_arrow),
              label: const Text('ВКЛЮЧИТЬ СЕКРЕТНОЕ РАДИО'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}