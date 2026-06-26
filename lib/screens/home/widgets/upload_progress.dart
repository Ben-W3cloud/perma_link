import 'package:fluffy_link/core/theme.dart';
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Glowing progress indicator
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.15),
                AppTheme.primaryDark.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            boxShadow: AppTheme.glowShadow(opacity: 0.2, blur: 32),
          ),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          fileName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.onSurfaceBright),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassCard(),
          child: Column(
            children: [
              _StepRow(
                label: 'Uploading to Walrus...',
                active: phase == UploadPhase.walrus,
                done: phase == UploadPhase.saving,
                showSpinner: phase == UploadPhase.walrus,
              ),
              const SizedBox(height: 12),
              _StepRow(
                label: 'Saving your link...',
                active: phase == UploadPhase.saving,
                done: false,
                showSpinner: phase == UploadPhase.saving,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'This may take a moment',
          style: TextStyle(color: AppTheme.mutedDim, fontSize: 13),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.active,
    required this.done,
    required this.showSpinner,
  });

  final String label;
  final bool active;
  final bool done;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    final FontWeight weight;

    if (done) {
      textColor = AppTheme.primary;
      weight = FontWeight.w500;
    } else if (active) {
      textColor = AppTheme.onSurfaceBright;
      weight = FontWeight.w500;
    } else {
      textColor = AppTheme.mutedDim;
      weight = FontWeight.normal;
    }

    return Row(
      children: [
        if (done) ...[
          const Icon(Icons.check_circle, size: 16, color: AppTheme.primary),
        ] else if (showSpinner) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ] else ...[
          Icon(Icons.circle_outlined, size: 16, color: AppTheme.mutedDim),
        ],
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: textColor, fontWeight: weight),
        ),
      ],
    );
  }
}
