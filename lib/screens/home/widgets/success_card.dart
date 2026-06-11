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
    await shareUrl(
      title: 'Perma.link',
      url: widget.link.shortUrl,
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Colors.grey.shade600, fontSize: 13);
    final meta = widget.metadata;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
        const SizedBox(height: 16),
        Text('Your link is ready', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        _LinkBox(
          label: 'Share link',
          url: widget.link.shortUrl,
          copied: _copiedUrl == widget.link.shortUrl,
          onCopy: () => _copy(widget.link.shortUrl),
        ),
        const SizedBox(height: 12),
        _LinkBox(
          label: 'Stats link',
          url: widget.link.statsUrl,
          copied: _copiedUrl == widget.link.statsUrl,
          onCopy: () => _copy(widget.link.statsUrl),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _shareTwitter,
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Twitter'),
            ),
            if (isWebShareSupported) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _shareNative,
                icon: const Icon(Icons.ios_share_outlined, size: 18),
                label: const Text('Share'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text(meta.fileName, style: muted),
        Text(
          '${FileUtils.formatBytes(meta.fileSize)} · ${meta.mimeType}',
          style: muted,
        ),
        Text('Uploaded ${_formatDate(meta.uploadedAt.toLocal())}', style: muted),
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
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  url,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(copied ? Icons.check : Icons.copy_outlined),
                tooltip: copied ? 'Copied' : 'Copy link',
                onPressed: onCopy,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
