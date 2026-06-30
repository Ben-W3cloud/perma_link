import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  const ImagePreview({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          color: AppTheme.surface,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final total = progress.expectedTotalBytes;
              final loaded = progress.cumulativeBytesLoaded;
              final value = total != null && total > 0 ? loaded / total : null;
              return SizedBox(
                height: 240,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      value: value,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stack) => Container(
              height: 240,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_not_supported_rounded,
                    size: 32,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Could not load image',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
