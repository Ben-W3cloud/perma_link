// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';

class VideoPreview extends StatefulWidget {
  const VideoPreview({super.key, required this.url});

  final String url;

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'permalink-video-${widget.url.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return html.VideoElement()
        ..src = widget.url
        ..controls = true
        ..preload = 'metadata'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#070B10'
        ..style.border = '0';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        height: MediaQuery.of(context).size.width < 700 ? 260 : 420,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}

class AudioPreview extends StatefulWidget {
  const AudioPreview({super.key, required this.url});

  final String url;

  @override
  State<AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<AudioPreview> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'permalink-audio-${widget.url.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return html.AudioElement()
        ..src = widget.url
        ..controls = true
        ..preload = 'metadata'
        ..style.width = '100%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(Icons.audiotrack_rounded, color: AppTheme.primary, size: 32),
          const SizedBox(height: 14),
          SizedBox(height: 44, child: HtmlElementView(viewType: _viewType)),
        ],
      ),
    );
  }
}
