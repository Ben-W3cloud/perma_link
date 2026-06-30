import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';

class VideoPreview extends StatelessWidget {
  const VideoPreview({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return const _MediaFallback(
      icon: Icons.videocam_rounded,
      title: 'Video preview is available in the browser.',
    );
  }
}

class AudioPreview extends StatelessWidget {
  const AudioPreview({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return const _MediaFallback(
      icon: Icons.audiotrack_rounded,
      title: 'Audio preview is available in the browser.',
    );
  }
}

class _MediaFallback extends StatelessWidget {
  const _MediaFallback({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: AppTheme.muted),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}
