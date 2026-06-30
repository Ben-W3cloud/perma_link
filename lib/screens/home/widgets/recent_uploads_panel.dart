import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/core/utils/file_utils.dart';
import 'package:fluffy_link/services/upload_history_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class RecentUploadsPanel extends StatefulWidget {
  const RecentUploadsPanel({super.key, required this.entries});

  final List<UploadHistoryEntry> entries;

  @override
  State<RecentUploadsPanel> createState() => _RecentUploadsPanelState();
}

class _RecentUploadsPanelState extends State<RecentUploadsPanel> {
  bool _expanded = false;
  String? _copiedCode;

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copiedCode = code);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copiedCode = null);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();

    final count = widget.entries.length;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$count recent upload${count == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                ...widget.entries.map(
                  (entry) => _RecentRow(
                    entry: entry,
                    copied: _copiedCode == entry.shortCode,
                    onCopy: () => _copy(entry.shortCode),
                    onOpen: () => launchUrl(
                      Uri.parse(entry.walrusUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.entry,
    required this.copied,
    required this.onCopy,
    required this.onOpen,
  });

  final UploadHistoryEntry entry;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 16,
              color: AppTheme.mutedDim,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.fileName,
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FileUtils.formatBytes(entry.fileSize),
                    style: TextStyle(
                      color: AppTheme.mutedDim,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _CodeChip(
              code: entry.shortCode,
              copied: copied,
              onTap: onCopy,
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onOpen,
              tooltip: 'Open file',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({
    required this.code,
    required this.copied,
    required this.onTap,
  });

  final String code;
  final bool copied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  copied ? Icons.check_rounded : Icons.copy_outlined,
                  key: ValueKey(copied),
                  size: 12,
                  color: copied ? AppTheme.primary : AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
