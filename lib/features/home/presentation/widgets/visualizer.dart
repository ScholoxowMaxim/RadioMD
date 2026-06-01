import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiomd/core/services/player_service.dart';

class AudioVisualizer extends StatefulWidget {
  final double height;
  final Color color;

  const AudioVisualizer({
    super.key,
    required this.height,
    this.color = Colors.white,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<double> _bars = List.generate(40, (_) => 0.3);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(() {
        for (int i = 0; i < _bars.length; i++) {
          _bars[i] = 0.2 + _random.nextDouble() * 0.6;
        }
        setState(() {});
      });
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerService>(
      builder: (context, player, _) {
        if (!player.isPlaying) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity, // На всю ширину
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_bars.length, (index) {
              final barHeight = (_bars[index] * widget.height).clamp(4.0, widget.height);
              
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.5 + _bars[index] * 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}