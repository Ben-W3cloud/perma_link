import 'dart:math' as math;

import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';

// Decentralized network visualization — nodes oscillate around fixed centers
// and connect to neighbors within range, mimicking a distributed peer network.
class NetworkBackground extends StatefulWidget {
  const NetworkBackground({super.key});

  @override
  State<NetworkBackground> createState() => _NetworkBackgroundState();
}

class _NetworkBackgroundState extends State<NetworkBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _NetworkPainter(progress: _controller),
      ),
    );
  }
}

// Each node has a fixed center and oscillates with its own phase + speed.
class _Node {
  const _Node({
    required this.cx,
    required this.cy,
    required this.amplitude,
    required this.phaseX,
    required this.phaseY,
    required this.speed,
    required this.isAccent,
    required this.size,
  });

  final double cx, cy; // normalized center (0–1)
  final double amplitude; // drift amplitude (normalized)
  final double phaseX, phaseY;
  final double speed;
  final bool isAccent;
  final double size; // node radius in px
}

// 30 hand-tuned nodes spread across the canvas.
final List<_Node> _nodes = [
  _Node(
    cx: 0.08,
    cy: 0.18,
    amplitude: 0.025,
    phaseX: 0.0,
    phaseY: 1.2,
    speed: 0.7,
    isAccent: false,
    size: 3.5,
  ),
  _Node(
    cx: 0.22,
    cy: 0.08,
    amplitude: 0.020,
    phaseX: 1.1,
    phaseY: 0.3,
    speed: 0.5,
    isAccent: true,
    size: 2.5,
  ),
  _Node(
    cx: 0.38,
    cy: 0.14,
    amplitude: 0.030,
    phaseX: 2.3,
    phaseY: 1.8,
    speed: 0.8,
    isAccent: false,
    size: 4.0,
  ),
  _Node(
    cx: 0.55,
    cy: 0.06,
    amplitude: 0.018,
    phaseX: 0.7,
    phaseY: 2.5,
    speed: 0.6,
    isAccent: false,
    size: 3.0,
  ),
  _Node(
    cx: 0.70,
    cy: 0.15,
    amplitude: 0.022,
    phaseX: 3.1,
    phaseY: 0.9,
    speed: 0.9,
    isAccent: true,
    size: 2.8,
  ),
  _Node(
    cx: 0.85,
    cy: 0.10,
    amplitude: 0.028,
    phaseX: 1.5,
    phaseY: 3.2,
    speed: 0.7,
    isAccent: false,
    size: 3.5,
  ),
  _Node(
    cx: 0.92,
    cy: 0.28,
    amplitude: 0.020,
    phaseX: 2.8,
    phaseY: 1.0,
    speed: 0.5,
    isAccent: false,
    size: 2.5,
  ),
  _Node(
    cx: 0.12,
    cy: 0.38,
    amplitude: 0.032,
    phaseX: 0.4,
    phaseY: 2.1,
    speed: 0.6,
    isAccent: false,
    size: 5.0,
  ),
  _Node(
    cx: 0.30,
    cy: 0.32,
    amplitude: 0.024,
    phaseX: 1.9,
    phaseY: 0.6,
    speed: 1.0,
    isAccent: true,
    size: 3.0,
  ),
  _Node(
    cx: 0.48,
    cy: 0.28,
    amplitude: 0.035,
    phaseX: 3.4,
    phaseY: 1.4,
    speed: 0.8,
    isAccent: false,
    size: 4.5,
  ),
  _Node(
    cx: 0.62,
    cy: 0.35,
    amplitude: 0.020,
    phaseX: 0.9,
    phaseY: 2.8,
    speed: 0.7,
    isAccent: false,
    size: 3.0,
  ),
  _Node(
    cx: 0.78,
    cy: 0.30,
    amplitude: 0.028,
    phaseX: 2.2,
    phaseY: 0.5,
    speed: 0.9,
    isAccent: true,
    size: 2.5,
  ),
  _Node(
    cx: 0.05,
    cy: 0.55,
    amplitude: 0.022,
    phaseX: 1.3,
    phaseY: 3.0,
    speed: 0.6,
    isAccent: false,
    size: 3.5,
  ),
  _Node(
    cx: 0.20,
    cy: 0.60,
    amplitude: 0.030,
    phaseX: 3.7,
    phaseY: 1.7,
    speed: 0.8,
    isAccent: false,
    size: 4.0,
  ),
  _Node(
    cx: 0.35,
    cy: 0.52,
    amplitude: 0.018,
    phaseX: 0.6,
    phaseY: 0.4,
    speed: 0.5,
    isAccent: true,
    size: 2.8,
  ),
  _Node(
    cx: 0.50,
    cy: 0.58,
    amplitude: 0.026,
    phaseX: 2.0,
    phaseY: 2.3,
    speed: 0.7,
    isAccent: false,
    size: 5.5,
  ),
  _Node(
    cx: 0.65,
    cy: 0.50,
    amplitude: 0.032,
    phaseX: 1.6,
    phaseY: 0.8,
    speed: 1.0,
    isAccent: false,
    size: 3.5,
  ),
  _Node(
    cx: 0.80,
    cy: 0.55,
    amplitude: 0.020,
    phaseX: 3.0,
    phaseY: 2.6,
    speed: 0.6,
    isAccent: true,
    size: 2.5,
  ),
  _Node(
    cx: 0.93,
    cy: 0.48,
    amplitude: 0.025,
    phaseX: 0.3,
    phaseY: 1.5,
    speed: 0.9,
    isAccent: false,
    size: 3.0,
  ),
  _Node(
    cx: 0.10,
    cy: 0.72,
    amplitude: 0.030,
    phaseX: 2.5,
    phaseY: 3.4,
    speed: 0.7,
    isAccent: false,
    size: 4.0,
  ),
  _Node(
    cx: 0.25,
    cy: 0.80,
    amplitude: 0.022,
    phaseX: 1.0,
    phaseY: 0.7,
    speed: 0.5,
    isAccent: false,
    size: 3.0,
  ),
  _Node(
    cx: 0.42,
    cy: 0.75,
    amplitude: 0.028,
    phaseX: 3.3,
    phaseY: 1.9,
    speed: 0.8,
    isAccent: true,
    size: 2.5,
  ),
  _Node(
    cx: 0.58,
    cy: 0.72,
    amplitude: 0.020,
    phaseX: 0.8,
    phaseY: 2.7,
    speed: 0.6,
    isAccent: false,
    size: 3.5,
  ),
  _Node(
    cx: 0.72,
    cy: 0.78,
    amplitude: 0.034,
    phaseX: 2.1,
    phaseY: 0.3,
    speed: 0.9,
    isAccent: false,
    size: 5.0,
  ),
  _Node(
    cx: 0.88,
    cy: 0.70,
    amplitude: 0.018,
    phaseX: 1.4,
    phaseY: 3.1,
    speed: 0.7,
    isAccent: true,
    size: 2.8,
  ),
  _Node(
    cx: 0.15,
    cy: 0.92,
    amplitude: 0.025,
    phaseX: 3.6,
    phaseY: 0.9,
    speed: 0.6,
    isAccent: false,
    size: 3.0,
  ),
  _Node(
    cx: 0.45,
    cy: 0.90,
    amplitude: 0.020,
    phaseX: 0.5,
    phaseY: 2.0,
    speed: 0.8,
    isAccent: false,
    size: 3.5,
  ),
  _Node(
    cx: 0.70,
    cy: 0.94,
    amplitude: 0.030,
    phaseX: 2.7,
    phaseY: 1.3,
    speed: 0.7,
    isAccent: true,
    size: 2.5,
  ),
  _Node(
    cx: 0.92,
    cy: 0.88,
    amplitude: 0.022,
    phaseX: 1.7,
    phaseY: 3.5,
    speed: 0.9,
    isAccent: false,
    size: 4.0,
  ),
  _Node(
    cx: 0.50,
    cy: 0.42,
    amplitude: 0.028,
    phaseX: 0.2,
    phaseY: 0.5,
    speed: 0.5,
    isAccent: false,
    size: 6.0,
  ),
];

class _NetworkPainter extends CustomPainter {
  _NetworkPainter({required this.progress}) : super(repaint: progress);

  final Animation<double> progress;

  static const double _connectionRange = 0.28; // normalized distance threshold
  static const double _maxAlpha = 0.3;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value * math.pi * 2;

    // Compute current node positions
    final positions = List<Offset>.generate(_nodes.length, (i) {
      final n = _nodes[i];
      final x =
          (n.cx + n.amplitude * math.sin(t * n.speed + n.phaseX)) * size.width;
      final y =
          (n.cy + n.amplitude * math.cos(t * n.speed * 0.7 + n.phaseY)) *
          size.height;
      return Offset(x, y);
    });

    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final nodePaint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()..style = PaintingStyle.fill;

    // Draw connections
    for (var i = 0; i < positions.length; i++) {
      for (var j = i + 1; j < positions.length; j++) {
        final dx = (positions[j].dx - positions[i].dx) / size.width;
        final dy = (positions[j].dy - positions[i].dy) / size.height;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > _connectionRange) continue;

        final alpha = (1.0 - dist / _connectionRange) * _maxAlpha;
        final isAccentLine = _nodes[i].isAccent || _nodes[j].isAccent;
        final lineColor = isAccentLine ? AppTheme.accent : AppTheme.primary;

        connectionPaint.color = lineColor.withValues(alpha: alpha);
        canvas.drawLine(positions[i], positions[j], connectionPaint);
      }
    }

    // Draw nodes
    for (var i = 0; i < positions.length; i++) {
      final n = _nodes[i];
      final pos = positions[i];
      final color = n.isAccent ? AppTheme.accent : AppTheme.primary;

      // Outer glow
      glowPaint.color = color.withValues(alpha: 0.06);
      canvas.drawCircle(pos, n.size * 4, glowPaint);

      // Inner glow
      glowPaint.color = color.withValues(alpha: 0.14);
      canvas.drawCircle(pos, n.size * 2, glowPaint);

      // Core
      nodePaint.color = color.withValues(alpha: 0.55);
      canvas.drawCircle(pos, n.size, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) => false;
}
