import 'package:flutter/material.dart';
import 'package:radiomd/features/player/presentation/mini_player.dart';
import '../data/stations_mock.dart';
import '../domain/station.dart';
import '../../../core/services/player_service.dart';
import '../../player/presentation/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlayerService playerService = PlayerService();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RadioMD')),
      body: ListView.builder(
        itemCount: mockStations.length,
        itemBuilder: (context, index) {
          final station = mockStations[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Image.network(
                station.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.radio, size: 50),
              ),
              title: Text(station.name),
              trailing: const Icon(Icons.play_arrow),
              onTap: () async {
                await PlayerService().play(station);
                setState(() {});
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}