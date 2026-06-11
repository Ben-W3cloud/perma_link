import 'package:file_picker/file_picker.dart';
import 'package:fluffy_link/screens/home/widgets/drop_zone_listener.dart'
    if (dart.library.html) 'package:fluffy_link/screens/home/widgets/drop_zone_web.dart';
import 'package:flutter/material.dart';

class DropZone extends StatefulWidget {
  const DropZone({super.key, required this.onFileDrop});

  final Future<void> Function(PlatformFile file) onFileDrop;

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    setupDropZone(
      onHoverChanged: (hovered) {
        if (mounted) setState(() => _hovered = hovered);
      },
      onFileDrop: widget.onFileDrop,
    );
  }

  @override
  void dispose() {
    teardownDropZone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const idleBorder = Color(0xFFD1D5DB);
    const hoverFill = Color(0xFFF0FDFA);
    final primary = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _hovered ? hoverFill : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: _hovered ? primary : idleBorder,
            borderRadius: 16,
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload_file_outlined, size: 40),
                SizedBox(height: 12),
                Text('Drop your file here'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      Radius.circular(borderRadius),
    );

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
