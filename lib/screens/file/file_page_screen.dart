import 'dart:async';

import 'package:fluffy_link/core/page_scaffold.dart';
import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/core/utils/code_validator.dart';
import 'package:fluffy_link/core/utils/error_messages.dart';
import 'package:fluffy_link/core/utils/file_download.dart';
import 'package:fluffy_link/core/utils/file_utils.dart';
import 'package:fluffy_link/core/utils/web_share.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:fluffy_link/screens/file/widgets/file_preview.dart';
import 'package:fluffy_link/screens/file/widgets/whats_new_banner.dart';
import 'package:fluffy_link/screens/shared/embed_snippet_box.dart';
import 'package:fluffy_link/screens/shared/qr_panel.dart';
import 'package:fluffy_link/screens/shared/storage_status_chip.dart';
import 'package:fluffy_link/services/auth_service.dart';
import 'package:fluffy_link/services/link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class FilePageScreen extends StatefulWidget {
  const FilePageScreen({
    super.key,
    required this.code,
    this.autoDownload = false,
    LinkService? linkService,
  }) : _linkService = linkService;

  final String code;
  final bool autoDownload;
  final LinkService? _linkService;

  @override
  State<FilePageScreen> createState() => _FilePageScreenState();
}

class _FilePageScreenState extends State<FilePageScreen> {
  late final LinkService _links = widget._linkService ?? LinkService();

  LinkModel? _link;
  bool _notFound = false;
  String? _errorMessage;
  bool _copied = false;
  bool _autoDownloadTriggered = false;

  @override
  void initState() {
    super.initState();
    if (!CodeValidator.isValidShortCode(widget.code)) {
      _notFound = true;
      return;
    }
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final link = await _links.resolveAndTrack(widget.code);
      if (!mounted) return;
      if (link == null) {
        setState(() => _notFound = true);
        return;
      }
      setState(() => _link = link);

      if (widget.autoDownload && !_autoDownloadTriggered) {
        _autoDownloadTriggered = true;
        unawaited(_handleDownload());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = ErrorMessages.forRedirect(e));
    }
  }

  bool get _isOwner {
    final link = _link;
    final user = AuthScope.of(context).currentUser;
    if (link == null || user == null || link.userId == null) return false;
    return link.userId == user.id;
  }

  Future<void> _handleView() async {
    final link = _link;
    if (link == null) return;
    final ok = await launchUrl(
      Uri.parse(link.walrusUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the file.')));
    }
  }

  Future<void> _handleDownload() async {
    final link = _link;
    if (link == null) return;
    final ok = await downloadFile(
      url: link.walrusUrl,
      filename: link.fileName ?? link.shortCode,
      mimeType: link.mimeType,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed — opening file instead')),
      );
      await launchUrl(
        Uri.parse(link.walrusUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _handleShare() async {
    final link = _link;
    if (link == null) return;
    final url = link.shortUrl;
    if (isWebShareSupported) {
      final ok = await shareUrl(
        title: link.fileName ?? link.shortCode,
        url: url,
      );
      if (ok) return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  Future<void> _copyShortUrl() async {
    final link = _link;
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link.shortUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _confirmDelete() async {
    final link = _link;
    if (link == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete this link?'),
        content: const Text(
          'The short code stops resolving. The file remains on Walrus until '
          'the storage epoch expires.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _links.deleteLink(link.shortCode);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link deleted')));
      context.go('/dashboard');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notFound) return const _NotFoundView();

    final error = _errorMessage;
    if (error != null) {
      return _ErrorView(message: error);
    }

    final link = _link;
    if (link == null) {
      return const PageScaffold(
        currentRoute: '/file',
        scrollable: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return PageScaffold(
      currentRoute: '/file',
      maxContentWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WhatsNewBanner(),
          const SizedBox(height: 16),
          _MetadataCard(
            link: link,
            isOwner: _isOwner,
            onDelete: _confirmDelete,
          ),
          const SizedBox(height: 16),
          FilePreview(link: link),
          const SizedBox(height: 16),
          _ShortUrlBox(
            url: link.shortUrl,
            copied: _copied,
            onCopy: _copyShortUrl,
          ),
          const SizedBox(height: 12),
          _ActionRow(
            onView: _handleView,
            onDownload: _handleDownload,
            onShare: _handleShare,
          ),
          const SizedBox(height: 16),
          StorageStatusChip(blobId: link.blobId, createdAt: link.createdAt),
          const SizedBox(height: 12),
          QrPanel(url: link.shortUrl),
          const SizedBox(height: 12),
          EmbedSnippetBox(
            shortUrl: link.shortUrl,
            walrusUrl: link.walrusUrl,
            fileName: link.fileName ?? link.shortCode,
            mimeType: link.mimeType,
            initiallyExpanded: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({
    required this.link,
    required this.isOwner,
    required this.onDelete,
  });

  final LinkModel link;
  final bool isOwner;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final size = link.fileSize == null
        ? '—'
        : FileUtils.formatBytes(link.fileSize!);
    final mime = link.mimeType;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.gradientCard(borderRadius: AppTheme.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MimeBadge(mime: mime),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.fileName ?? link.shortCode,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$size · $mime',
                      style: TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isOwner) ...[
                const SizedBox(width: 8),
                const _OwnerPill(),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppTheme.mutedDim,
              ),
              const SizedBox(width: 6),
              Text(
                'Uploaded ${_formatDate(link.createdAt.toLocal())}',
                style: TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
              const SizedBox(width: 14),
              Icon(Icons.bar_chart_rounded, size: 14, color: AppTheme.mutedDim),
              const SizedBox(width: 6),
              Text(
                '${link.clickCount} ${link.clickCount == 1 ? 'view' : 'views'}',
                style: TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _MimeBadge extends StatelessWidget {
  const _MimeBadge({required this.mime});
  final String mime;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (mime.startsWith('image/')) {
      icon = Icons.image_rounded;
    } else if (mime.startsWith('video/')) {
      icon = Icons.videocam_rounded;
    } else if (mime.startsWith('audio/')) {
      icon = Icons.audiotrack_rounded;
    } else if (mime == 'application/pdf') {
      icon = Icons.picture_as_pdf_rounded;
    } else if (mime.startsWith('text/') ||
        mime == 'application/json' ||
        mime == 'application/xml') {
      icon = Icons.description_rounded;
    } else if (mime == 'application/zip' ||
        mime == 'application/gzip' ||
        mime == 'application/x-tar') {
      icon = Icons.folder_zip_rounded;
    } else {
      icon = Icons.insert_drive_file_rounded;
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.glowShadow(opacity: 0.25, blur: 14),
      ),
      child: Icon(icon, size: 22, color: Colors.white),
    );
  }
}

class _OwnerPill extends StatelessWidget {
  const _OwnerPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, size: 12, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            'Owner',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortUrlBox extends StatelessWidget {
  const _ShortUrlBox({
    required this.url,
    required this.copied,
    required this.onCopy,
  });

  final String url;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              url,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              maxLines: 1,
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
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onView,
    required this.onDownload,
    required this.onShare,
  });

  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onView,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('View'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Share'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      currentRoute: '/file',
      scrollable: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Icon(
                  Icons.link_off_rounded,
                  size: 28,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Link not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                "This link doesn't exist or may have expired.",
                style: TextStyle(color: AppTheme.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Perma.link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      currentRoute: '/file',
      scrollable: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7F1D1D).withValues(alpha: 0.2),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load this link',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: AppTheme.glassCard(borderRadius: 12),
                child: Text(
                  message,
                  style: TextStyle(color: AppTheme.muted, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Perma.link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
