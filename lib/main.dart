import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const RadioMDApp());
}

class RadioMDApp extends StatelessWidget {
  const RadioMDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RadioMD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: Text('RadioMD'),
        ),
      ),
    );
  }
}