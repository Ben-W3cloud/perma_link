import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _EmbedFormat { html, markdown, imageMarkdown }

// Shared collapsible embed snippet box used by SuccessCard and
// FilePageScreen. HTML / Markdown / Image MD tabs (image variant only
// shown for image/* mime types).
class EmbedSnippetBox extends StatefulWidget {
  const EmbedSnippetBox({
    super.key,
    required this.shortUrl,
    required this.walrusUrl,
    required this.fileName,
    required this.mimeType,
    this.initiallyExpanded = true,
  });

  final String shortUrl;
  final String walrusUrl;
  final String fileName;
  final String mimeType;
  final bool initiallyExpanded;

  @override
  State<EmbedSnippetBox> createState() => _EmbedSnippetBoxState();
}

class _EmbedSnippetBoxState extends State<EmbedSnippetBox> {
  late bool _expanded = widget.initiallyExpanded;
  _EmbedFormat _format = _EmbedFormat.html;
  bool _justCopied = false;

  bool get _isImage => widget.mimeType.startsWith('image/');

  String _snippetFor(_EmbedFormat f) {
    switch (f) {
      case _EmbedFormat.html:
        return '<a href="${widget.shortUrl}">${widget.fileName}</a>';
      case _EmbedFormat.markdown:
        return '[${widget.fileName}](${widget.shortUrl})';
      case _EmbedFormat.imageMarkdown:
        return '![${widget.fileName}](${widget.walrusUrl})';
    }
  }

  String _labelFor(_EmbedFormat f) {
    switch (f) {
      case _EmbedFormat.html:
        return 'HTML';
      case _EmbedFormat.markdown:
        return 'Markdown';
      case _EmbedFormat.imageMarkdown:
        return 'Image MD';
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _snippetFor(_format)));
    if (!mounted) return;
    setState(() => _justCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final formats = <_EmbedFormat>[
      _EmbedFormat.html,
      _EmbedFormat.markdown,
      if (_isImage) _EmbedFormat.imageMarkdown,
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(Icons.code_rounded, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Embed snippet',
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
                      color: AppTheme.muted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          children: formats
                              .map(
                                (f) => _FormatChip(
                                  label: _labelFor(f),
                                  selected: f == _format,
                                  onTap: () => setState(() => _format = f),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: SelectableText(
                            _snippetFor(_format),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _copy,
                            icon: Icon(
                              _justCopied
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              size: 16,
                            ),
                            label: Text(_justCopied ? 'Copied' : 'Copy snippet'),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.18)
              : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primary : AppTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
