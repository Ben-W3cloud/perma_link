import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:fluffy_link/screens/file/widgets/image_preview.dart';
import 'package:fluffy_link/screens/file/widgets/media_preview.dart';
import 'package:fluffy_link/screens/file/widgets/pdf_preview.dart';
import 'package:fluffy_link/screens/file/widgets/text_preview.dart';
import 'package:flutter/material.dart';

class FilePreview extends StatelessWidget {
  const FilePreview({super.key, required this.link});

  final LinkModel link;

  @override
  Widget build(BuildContext context) {
    final mime = link.mimeType;
    if (mime.startsWith('image/')) {
      return ImagePreview(url: link.walrusUrl);
    }
    if (mime == 'application/pdf') {
      return PdfPreview(url: link.walrusUrl);
    }
    if (mime.startsWith('video/')) {
      return VideoPreview(url: link.walrusUrl);
    }
    if (mime.startsWith('audio/')) {
      return AudioPreview(url: link.walrusUrl);
    }
    if (mime.startsWith('text/') ||
        mime == 'application/json' ||
        mime == 'application/xml' ||
        mime == 'application/javascript') {
      return TextPreview(url: link.walrusUrl);
    }
    return const _FallbackPreview();
  }
}

class _FallbackPreview extends StatelessWidget {
  const _FallbackPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                size: 32,
                color: AppTheme.muted,
              ),
              const SizedBox(height: 10),
              Text(
                'Preview not available for this file type',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 4),
              Text(
                'Click View to open it.',
                style: TextStyle(color: AppTheme.mutedDim, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
