import 'dart:async';

import 'package:fluffy_link/core/utils/code_validator.dart';
import 'package:fluffy_link/core/utils/file_utils.dart';
import 'package:fluffy_link/models/link_model.dart';
import 'package:fluffy_link/services/link_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.code, LinkService? linkService})
    : _linkService = linkService ?? LinkService();

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
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading stats...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Link stats',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  _LinkBox(url: link.shortUrl),
                  const SizedBox(height: 24),
                  _StatRow(label: 'Clicks', value: link.clickCount.toString()),
                  const SizedBox(height: 12),
                  _StatRow(
                    label: 'Uploaded',
                    value: _formatDate(link.createdAt.toLocal()),
                  ),
                  if (link.fileName != null) ...[
                    const SizedBox(height: 12),
                    _StatRow(label: 'Filename', value: link.fileName!),
                  ],
                  if (link.fileSize != null) ...[
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Size',
                      value: FileUtils.formatBytes(link.fileSize!),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _copy,
                    icon: Icon(_copied ? Icons.check : Icons.copy_outlined),
                    label: Text(_copied ? 'Copied' : 'Copy link'),
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

class _LinkBox extends StatelessWidget {
  const _LinkBox({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        url,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(color: Colors.grey.shade600, fontSize: 14);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: mutedStyle),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

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
              Text(
                'Link not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                "This link doesn't exist or may have expired.",
                style: TextStyle(color: Colors.grey.shade600),
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
