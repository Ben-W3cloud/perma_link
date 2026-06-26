import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/core/utils/file_utils.dart';
import 'package:fluffy_link/core/utils/web_share.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UploadMetadata {
  const UploadMetadata({
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedAt,
  });

  final String fileName;
  final int fileSize;
  final String mimeType;
  final DateTime uploadedAt;
}

class SuccessCard extends StatefulWidget {
  const SuccessCard({
    super.key,
    required this.link,
    required this.metadata,
    required this.onReset,
  });

  final LinkModel link;
  final UploadMetadata metadata;
  final VoidCallback onReset;

  @override
  State<SuccessCard> createState() => _SuccessCardState();
}

class _SuccessCardState extends State<SuccessCard> {
  String? _copiedUrl;

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    setState(() => _copiedUrl = url);

    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copiedUrl = null);
  }

  Future<void> _shareTwitter() async {
    final text = Uri.encodeComponent('Check out this file on Perma.link');
    final url = Uri.encodeComponent(widget.link.shortUrl);
    final uri = Uri.parse(
      'https://twitter.com/intent/tweet?text=$text&url=$url',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareNative() async {
    await shareUrl(title: 'Perma.link', url: widget.link.shortUrl);
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.metadata;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success icon
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 28,
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 20),
        Text(
          'Your link is ready',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),

        // Link boxes inside glassmorphic container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassCard(),
          child: Column(
            children: [
              _LinkBox(
                label: 'Share link',
                url: widget.link.shortUrl,
                copied: _copiedUrl == widget.link.shortUrl,
                onCopy: () => _copy(widget.link.shortUrl),
              ),
              const SizedBox(height: 16),
              _LinkBox(
                label: 'Stats link',
                url: widget.link.statsUrl,
                copied: _copiedUrl == widget.link.statsUrl,
                onCopy: () => _copy(widget.link.statsUrl),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Share buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ShareButton(
              icon: Icons.share_outlined,
              label: 'Twitter',
              onPressed: _shareTwitter,
            ),
            if (isWebShareSupported) ...[
              const SizedBox(width: 8),
              _ShareButton(
                icon: Icons.ios_share_outlined,
                label: 'Share',
                onPressed: _shareNative,
              ),
            ],
          ],
        ),

        const SizedBox(height: 20),

        // File metadata
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _MetaRow(
                icon: Icons.insert_drive_file_outlined,
                text: meta.fileName,
              ),
              const SizedBox(height: 4),
              _MetaRow(
                icon: Icons.data_usage_outlined,
                text:
                    '${FileUtils.formatBytes(meta.fileSize)} \u00B7 ${meta.mimeType}',
              ),
              const SizedBox(height: 4),
              _MetaRow(
                icon: Icons.access_time_outlined,
                text: 'Uploaded ${_formatDate(meta.uploadedAt.toLocal())}',
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: widget.onReset,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Upload another file'),
        ),
      ],
    );
  }
}

class _LinkBox extends StatelessWidget {
  const _LinkBox({
    required this.label,
    required this.url,
    required this.copied,
    required this.onCopy,
  });

  final String label;
  final String url;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.mutedDim, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  url,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: AppTheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onCopy,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    copied ? Icons.check_rounded : Icons.copy_outlined,
                    key: ValueKey(copied),
                    size: 18,
                    color: copied ? AppTheme.primary : AppTheme.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.muted,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.mutedDim),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppTheme.muted, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
