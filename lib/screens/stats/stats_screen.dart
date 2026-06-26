import 'dart:async';

import 'package:fluffy_link/core/page_scaffold.dart';
import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/core/utils/code_validator.dart';
import 'package:fluffy_link/core/utils/file_utils.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:fluffy_link/services/link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.code, LinkService? linkService})
    : _linkService = linkService;

  final String code;
  final LinkService? _linkService;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final LinkService _links = widget._linkService ?? LinkService();

  LinkModel? _link;
  bool _notFound = false;
  bool _copied = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (!CodeValidator.isValidShortCode(widget.code)) {
      _notFound = true;
      return;
    }
    _loadStats();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadStats(),
    );
  }

  Future<void> _loadStats() async {
    try {
      final link = await _links.getLinkStats(widget.code);
      if (!mounted) return;

      setState(() {
        _link = link;
        _notFound = link == null;
      });
    } catch (_) {
      // Keep showing the last known stats on transient poll failures.
    }
  }

  Future<void> _copy() async {
    final link = _link;
    if (link == null) return;

    await Clipboard.setData(ClipboardData(text: link.shortUrl));
    setState(() => _copied = true);

    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
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
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_notFound) {
      return const _StatsNotFound();
    }

    final link = _link;
    if (link == null) {
      return const _StatsLoading();
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return PageScaffold(
      currentRoute: '/s/${widget.code}',
      maxContentWidth: 560,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Header ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.glowShadow(opacity: 0.35, blur: 20),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Link Statistics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Real-time analytics for your shared file',
              style: TextStyle(color: AppTheme.muted, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // ── Link URL display ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard().copyWith(
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
                boxShadow: AppTheme.glowShadow(opacity: 0.05, blur: 16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      link.shortUrl,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats grid ──
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = <Widget>[
                  _StatCard(
                    icon: Icons.touch_app_outlined,
                    label: 'Total Clicks',
                    value: link.clickCount.toString(),
                    highlight: true,
                  ),
                  _StatCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Uploaded',
                    value: _formatDate(link.createdAt.toLocal()),
                  ),
                  if (link.fileName != null)
                    _StatCard(
                      icon: Icons.insert_drive_file_outlined,
                      label: 'Filename',
                      value: link.fileName!,
                    ),
                  if (link.fileSize != null)
                    _StatCard(
                      icon: Icons.data_usage_outlined,
                      label: 'Size',
                      value: FileUtils.formatBytes(link.fileSize!),
                    ),
                ];

                if (constraints.maxWidth > 400) {
                  // 2-column grid
                  final rows = <Widget>[];
                  for (var i = 0; i < cards.length; i += 2) {
                    if (i + 1 < cards.length) {
                      rows.add(
                        Row(
                          children: [
                            Expanded(child: cards[i]),
                            const SizedBox(width: 12),
                            Expanded(child: cards[i + 1]),
                          ],
                        ),
                      );
                    } else {
                      rows.add(
                        Row(
                          children: [
                            Expanded(child: cards[i]),
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      );
                    }
                    if (i + 2 < cards.length) {
                      rows.add(const SizedBox(height: 12));
                    }
                  }
                  return Column(children: rows);
                }

                return Column(
                  children:
                      cards
                          .expand((c) => [c, const SizedBox(height: 12)])
                          .toList()
                        ..removeLast(),
                );
              },
            ),

            const SizedBox(height: 32),

            // ── Copy button ──
            SizedBox(
              width: isMobile ? double.infinity : null,
              child: FilledButton.icon(
                onPressed: _copy,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_outlined,
                    key: ValueKey(_copied),
                    size: 18,
                  ),
                ),
                label: Text(_copied ? 'Copied!' : 'Copy link'),
              ),
            ),

            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: () => context.go('/upload'),
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Upload another file'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(
                'Back to home',
                style: TextStyle(color: AppTheme.mutedDim, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STAT CARD
// ═══════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          AppTheme.gradientCard(
            borderColor: highlight
                ? AppTheme.primary.withValues(alpha: 0.35)
                : null,
          ).copyWith(
            boxShadow: highlight
                ? AppTheme.glowShadow(opacity: 0.12, blur: 18)
                : null,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.mutedDim),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.mutedDim,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppTheme.primary : AppTheme.onSurfaceBright,
              fontSize: highlight ? 28 : 15,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING STATE
// ═══════════════════════════════════════════════════════════════════════════

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.glowShadow(opacity: 0.1, blur: 20),
              ),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
            const SizedBox(height: 20),
            Text('Loading stats...', style: TextStyle(color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOT FOUND STATE
// ═══════════════════════════════════════════════════════════════════════════

class _StatsNotFound extends StatelessWidget {
  const _StatsNotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
