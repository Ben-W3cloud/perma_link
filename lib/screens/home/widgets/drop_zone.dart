import 'package:file_picker/file_picker.dart';
import 'package:fluffy_link/core/theme.dart';
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _hovered
              ? LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.primaryDark.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [AppTheme.surface, AppTheme.surfaceAlt],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _hovered
              ? AppTheme.glowShadow(opacity: 0.15, blur: 24)
              : null,
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: _hovered
                ? AppTheme.primary.withValues(alpha: 0.6)
                : AppTheme.border,
            borderRadius: 14,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _hovered
                        ? AppTheme.primaryGradient
                        : LinearGradient(
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.1),
                              AppTheme.primaryDark.withValues(alpha: 0.06),
                            ],
                          ),
                    boxShadow: _hovered
                        ? AppTheme.glowShadow(opacity: 0.4, blur: 16)
                        : null,
                  ),
                  child: Icon(
                    Icons.upload_file_outlined,
                    size: 30,
                    color: _hovered ? Colors.white : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Drop your file here',
                  style: TextStyle(
                    color: _hovered ? AppTheme.onSurfaceBright : AppTheme.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'or click Browse below',
                  style: TextStyle(color: AppTheme.mutedDim, fontSize: 12),
                ),
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
