import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/core/utils/code_validator.dart';
import 'package:fluffy_link/core/utils/error_messages.dart';
import 'package:fluffy_link/screens/redirect/widgets/loading_view.dart';
import 'package:fluffy_link/services/link_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class RedirectScreen extends StatefulWidget {
  const RedirectScreen({
    super.key,
    required this.code,
    LinkService? linkService,
  }) : _linkService = linkService;

  final String code;
  final LinkService? _linkService;

  @override
  State<RedirectScreen> createState() => _RedirectScreenState();
}

class _RedirectScreenState extends State<RedirectScreen> {
  late final LinkService _links = widget._linkService ?? LinkService();

  bool _notFound = false;
  String? _errorMessage;

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

      final uri = Uri.parse(link.walrusUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        setState(() => _errorMessage = 'Could not open the stored file.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = ErrorMessages.forRedirect(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notFound) {
      return const _RedirectNotFound();
    }

    final error = _errorMessage;
    if (error != null) {
      return _RedirectMessage(
        title: 'Redirect failed',
        message: error,
        actionLabel: 'Go to Perma.link',
      );
    }

    return const LoadingView(message: 'Resolving link...');
  }
}

class _RedirectNotFound extends StatelessWidget {
  const _RedirectNotFound();

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

class _RedirectMessage extends StatelessWidget {
  const _RedirectMessage({
    required this.title,
    required this.actionLabel,
    this.message,
  });

  final String title;
  final String? message;
  final String actionLabel;

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
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (message != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: AppTheme.glassCard(borderRadius: 12),
                  child: Text(
                    message!,
                    style: TextStyle(color: AppTheme.muted, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
