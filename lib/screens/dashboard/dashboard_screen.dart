import 'dart:async';

import 'package:fluffy_link/core/page_scaffold.dart';
import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/core/utils/file_utils.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:fluffy_link/services/auth_service.dart';
import 'package:fluffy_link/services/link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

const int _pageSize = 20;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, LinkService? linkService})
    : _linkService = linkService;

  final LinkService? _linkService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final LinkService _links = widget._linkService ?? LinkService();

  List<LinkModel> _items = const [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  // Pending deletes keyed by shortCode → restore data + timer. Lets us undo
  // an optimistic remove if the user hits Undo before the timer fires.
  final Map<String, _PendingDelete> _pending = {};

  @override
  void initState() {
    super.initState();
    _maybeLoad();
  }

  @override
  void dispose() {
    for (final p in _pending.values) {
      p.timer.cancel();
    }
    super.dispose();
  }

  Future<void> _maybeLoad({bool loadMore = false}) async {
    final user = AuthScope.of(context).currentUser;
    if (user == null) {
      context.go('/auth?redirect=${Uri.encodeComponent('/dashboard')}');
      return;
    }

    if (loadMore) {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
        _items = const [];
        _hasMore = true;
      });
    }

    try {
      final offset = loadMore ? _items.length : 0;
      final rows = await _links.listMine(
        userId: user.id,
        limit: _pageSize,
        offset: offset,
      );
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _items = [..._items, ...rows];
        } else {
          _items = rows;
        }
        _hasMore = rows.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!loadMore) {
        setState(() {
          _error = 'Could not load your links. Pull to retry.';
          _loading = false;
        });
      } else {
        setState(() => _loadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load more links.')),
        );
      }
    }
  }

  void _handleDelete(LinkModel link) {
    final index = _items.indexOf(link);
    if (index < 0) return;

    setState(() => _items = List.of(_items)..removeAt(index));

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final timer = Timer(const Duration(seconds: 5), () {
      final pending = _pending.remove(link.shortCode);
      if (pending == null) return;
      unawaited(_links.deleteLink(link.shortCode).catchError((Object _) {}));
    });

    _pending[link.shortCode] = _PendingDelete(
      link: link,
      index: index,
      timer: timer,
    );

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text('Deleted ${link.fileName ?? link.shortCode}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _undoDelete(link.shortCode),
        ),
      ),
    );
  }

  void _undoDelete(String shortCode) {
    final pending = _pending.remove(shortCode);
    if (pending == null) return;
    pending.timer.cancel();
    final restored = List.of(_items)
      ..insert(pending.index.clamp(0, _items.length), pending.link);
    setState(() => _items = restored);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      currentRoute: '/dashboard',
      scrollable: false,
      maxContentWidth: 1180,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return _ErrorState(message: _error!, onRetry: _maybeLoad);
    }
    if (_items.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _maybeLoad(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              _hasMore &&
              !_loadingMore) {
            final metrics = notification.metrics;
            if (metrics.pixels >= metrics.maxScrollExtent - 200) {
              _maybeLoad(loadMore: true);
            }
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _DashboardHeader(count: _items.length)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  int cols;
                  if (width < 600) {
                    cols = 1;
                  } else if (width < 960) {
                    cols = 2;
                  } else if (width < 1280) {
                    cols = 3;
                  } else {
                    cols = 4;
                  }
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      mainAxisExtent: 188,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _LinkCard(
                        link: _items[i],
                        onOpen: () => context.go('/${_items[i].shortCode}'),
                        onCopyLink: () =>
                            _copyAndToast(_items[i].shortUrl, 'Link copied'),
                        onCopyEmbed: () => _copyAndToast(
                          '<a href="${_items[i].shortUrl}">'
                              '${_items[i].fileName ?? _items[i].shortCode}'
                              '</a>',
                          'Embed snippet copied',
                        ),
                        onDelete: () => _handleDelete(_items[i]),
                      ),
                      childCount: _items.length,
                    ),
                  );
                },
              ),
            ),
            if (_loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyAndToast(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PendingDelete {
  _PendingDelete({
    required this.link,
    required this.index,
    required this.timer,
  });
  final LinkModel link;
  final int index;
  final Timer timer;
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My links',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count ${count == 1 ? 'link' : 'links'}',
                  style: TextStyle(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.go('/upload'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Upload'),
          ),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.link,
    required this.onOpen,
    required this.onCopyLink,
    required this.onCopyEmbed,
    required this.onDelete,
  });

  final LinkModel link;
  final VoidCallback onOpen;
  final VoidCallback onCopyLink;
  final VoidCallback onCopyEmbed;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final size = link.fileSize == null
        ? '—'
        : FileUtils.formatBytes(link.fileSize!);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.gradientCard(borderRadius: AppTheme.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MimeIcon(mime: link.mimeType),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    link.fileName ?? link.shortCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _KebabMenu(
                  onOpen: onOpen,
                  onCopyLink: onCopyLink,
                  onCopyEmbed: onCopyEmbed,
                  onDelete: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$size · ${link.mimeType}',
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                _CodeChip(code: link.shortCode, onTap: onCopyLink),
                const SizedBox(width: 8),
                _ClickChip(count: link.clickCount),
                const Spacer(),
                Text(
                  _shortDate(link.createdAt.toLocal()),
                  style: TextStyle(color: AppTheme.mutedDim, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _MimeIcon extends StatelessWidget {
  const _MimeIcon({required this.mime});
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
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: AppTheme.primary),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code, required this.onTap});
  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.copy_rounded, size: 12, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}

class _ClickChip extends StatelessWidget {
  const _ClickChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, size: 12, color: AppTheme.muted),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _KebabMenu extends StatelessWidget {
  const _KebabMenu({
    required this.onOpen,
    required this.onCopyLink,
    required this.onCopyEmbed,
    required this.onDelete,
  });

  final VoidCallback onOpen;
  final VoidCallback onCopyLink;
  final VoidCallback onCopyEmbed;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      offset: const Offset(0, 32),
      icon: Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.muted),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      color: AppTheme.surface,
      onSelected: (v) {
        switch (v) {
          case 'open':
            onOpen();
          case 'copy':
            onCopyLink();
          case 'embed':
            onCopyEmbed();
          case 'delete':
            _confirmDelete(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'open',
          child: _MenuRow(icon: Icons.open_in_new_rounded, label: 'Open'),
        ),
        const PopupMenuItem(
          value: 'copy',
          child: _MenuRow(icon: Icons.copy_rounded, label: 'Copy link'),
        ),
        const PopupMenuItem(
          value: 'embed',
          child: _MenuRow(icon: Icons.code_rounded, label: 'Copy embed'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: c)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 32,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No links yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a file to see it here.',
              style: TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/upload'),
              icon: const Icon(Icons.upload_rounded, size: 18),
              label: const Text('Upload your first file'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
