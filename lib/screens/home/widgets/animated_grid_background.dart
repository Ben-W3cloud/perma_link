import 'dart:math' as math;

import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';

/// Animated grid/mesh background with subtle wave distortion
class _AnimatedGridBackground extends StatefulWidget {
  const _AnimatedGridBackground();

  @override
  State<_AnimatedGridBackground> createState() =>
      _AnimatedGridBackgroundState();
}

class _AnimatedGridBackgroundState extends State<_AnimatedGridBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GridPainter(
            progress: _controller.value,
            lineColor: AppTheme.primary.withValues(alpha: 0.04),
            accentColor: AppTheme.accent.withValues(alpha: 0.03),
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.progress,
    required this.lineColor,
    required this.accentColor,
  });

  final double progress;
  final Color lineColor;
  final Color accentColor;

  static const double _gridSize = 60;
  static const double _waveAmplitude = 8;
  static const double _waveFrequency = 0.015;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final offsetX = (progress * _gridSize) % _gridSize;
    final offsetY = (progress * _gridSize * 0.7) % _gridSize;

    // Vertical lines with wave distortion
    for (double x = -offsetX; x < size.width + _gridSize; x += _gridSize) {
      final path = Path();
      for (double y = 0; y <= size.height; y += 2) {
        final wave =
            math.sin((y * _waveFrequency) + (progress * 2 * math.pi)) *
            _waveAmplitude;
        final px = x + wave;
        if (y == 0) {
          path.moveTo(px, y);
        } else {
          path.lineTo(px, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Horizontal lines with wave distortion
    for (double y = -offsetY; y < size.height + _gridSize; y += _gridSize) {
      final path = Path();
      for (double x = 0; x <= size.width; x += 2) {
        final wave =
            math.cos((x * _waveFrequency) + (progress * 2 * math.pi)) *
            _waveAmplitude;
        final py = y + wave;
        if (x == 0) {
          path.moveTo(x, py);
        } else {
          path.lineTo(x, py);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Accent lines (subtle, fewer)
    final accentPaint2 = Paint()
      ..color = accentColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final y =
          (size.height / 4) * (i + 1) +
          math.sin(progress * 2 * math.pi + i) * 20;
      final path = Path();
      for (double x = 0; x <= size.width; x += 2) {
        final wave =
            math.sin((x * _waveFrequency * 0.5) + (progress * math.pi) + i) *
            12;
        if (x == 0) {
          path.moveTo(x, y + wave);
        } else {
          path.lineTo(x, y + wave);
        }
      }
      canvas.drawPath(path, accentPaint2);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Wrapper that respects prefers-reduced-motion
class AnimatedGridBackground extends StatelessWidget {
  const AnimatedGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion = mediaQuery.disableAnimations;

    if (reduceMotion) {
      return const SizedBox.shrink();
    }

    return const _AnimatedGridBackground();
  }
}
