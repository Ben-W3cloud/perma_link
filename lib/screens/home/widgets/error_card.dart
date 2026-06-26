import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Error icon
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF991B1B), Color(0xFFEF4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                blurRadius: 28,
              ),
            ],
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text('Upload failed', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: AppTheme.glassCard(borderRadius: 12),
          child: Text(
            message,
            style: TextStyle(color: AppTheme.muted, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}
