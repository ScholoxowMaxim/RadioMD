import 'package:flutter/material.dart';
import '../data/stations_mock.dart';
import '../domain/station.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              onTap: () {
                // TODO: перейти к плееру
              },
            ),
          );
        },
      ),
    );
  }
}