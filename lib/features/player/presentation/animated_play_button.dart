import 'package:flutter/material.dart';

class AnimatedPlayButton extends StatelessWidget {
  final bool isPlaying;
  final double size;
  final VoidCallback onPressed;

  const AnimatedPlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: size + 8,
        height: size + 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(isPlaying ? 0.2 : 0.1),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            key: ValueKey(isPlaying),
            color: Colors.white,
            size: size,
          ),
        ),
      ),
    );
  }
}