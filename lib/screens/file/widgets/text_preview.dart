import 'dart:convert';

import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TextPreview extends StatefulWidget {
  const TextPreview({super.key, required this.url, this.maxBytes = 65536});

  final String url;
  final int maxBytes;

  @override
  State<TextPreview> createState() => _TextPreviewState();
}

class _TextPreviewState extends State<TextPreview> {
  String? _text;
  bool _truncated = false;
  bool _loading = true;
  String? _error;

  static const int _maxLines = 80;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Range request keeps us from pulling multi-MB files just to show
      // the first 80 lines. Walrus aggregator respects Range on most blobs.
      final response = await http.get(
        Uri.parse(widget.url),
        headers: {'Range': 'bytes=0-${widget.maxBytes - 1}'},
      );
      if (response.statusCode >= 400) {
        throw http.ClientException('HTTP ${response.statusCode}');
      }
      final raw = utf8.decode(response.bodyBytes, allowMalformed: true);
      final lines = const LineSplitter().convert(raw);
      final shown = lines.length > _maxLines ? lines.take(_maxLines).toList() : lines;
      if (!mounted) return;
      setState(() {
        _text = shown.join('\n');
        _truncated = lines.length > _maxLines || response.bodyBytes.length >= widget.maxBytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load text preview';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    final error = _error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 28, color: AppTheme.muted),
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: AppTheme.muted)),
          ],
        ),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  _text ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_truncated)
          Positioned(
            right: 10,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                'Preview truncated',
                style: TextStyle(color: AppTheme.muted, fontSize: 10.5),
              ),
            ),
          ),
      ],
    );
  }
}
