import 'package:flutter/material.dart';

enum UploadPhase { walrus, saving }

class UploadProgress extends StatelessWidget {
  const UploadProgress({
    super.key,
    required this.fileName,
    required this.phase,
  });

  final String fileName;
  final UploadPhase phase;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Colors.grey.shade600);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          fileName,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        _StepRow(
          label: 'Uploading to Walrus...',
          active: phase == UploadPhase.walrus,
          showSpinner: phase == UploadPhase.walrus,
        ),
        const SizedBox(height: 8),
        _StepRow(
          label: 'Saving your link...',
          active: phase == UploadPhase.saving,
          showSpinner: phase == UploadPhase.saving,
        ),
        const SizedBox(height: 16),
        Text('This may take a moment', style: muted),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.active,
    required this.showSpinner,
  });

  final String label;
  final bool active;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: active
          ? Theme.of(context).colorScheme.primary
          : Colors.grey.shade400,
      fontWeight: active ? FontWeight.w500 : FontWeight.normal,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showSpinner) ...[
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ] else ...[
          Icon(
            active ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
        ],
        Text(label, style: style),
      ],
    );
  }
}
