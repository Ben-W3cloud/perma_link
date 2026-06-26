import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentRoute,
    this.scrollController,
    this.onScrollToWhy,
    this.onScrollToFeatures,
    this.onScrollToWorkflow,
  });

  final String currentRoute;
  final ScrollController? scrollController;
  final VoidCallback? onScrollToWhy;
  final VoidCallback? onScrollToFeatures;
  final VoidCallback? onScrollToWorkflow;

  @override
  Widget build(BuildContext context) {
    // 900 covers narrow laptop windows where the four desktop nav links plus
    // PERMA.LINK logo and the "Start Uploading" CTA can't all fit on one row.
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 28,
        12,
        isMobile ? 12 : 28,
        8,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.glowShadow(opacity: 0.1, blur: 32),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppTheme.glowShadow(opacity: 0.35, blur: 10),
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                      children: const [
                        TextSpan(text: 'PERMA.'),
                        TextSpan(
                          text: 'LINK',
                          style: TextStyle(color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (!isMobile) ...[
              _NavLink(
                label: 'WHY',
                isActive: false,
                onTap: onScrollToWhy,
              ),
              _NavLink(
                label: 'FEATURES',
                isActive: false,
                onTap: onScrollToFeatures,
              ),
              _NavLink(
                label: 'HOW IT WORKS',
                isActive: false,
                onTap: onScrollToWorkflow,
              ),
              const SizedBox(width: 12),
            ],
            if (isMobile)
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showMobileMenu(context),
                    icon: const Icon(Icons.menu_rounded),
                    color: AppTheme.onSurface,
                  ),
                ],
              )
            else
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/upload'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.rocket_launch_rounded, size: 15),
                    label: const Text('Launch App'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MobileNavItem(
              label: 'WHY',
              onTap: () {
                Navigator.pop(context);
                onScrollToWhy?.call();
              },
            ),
            _MobileNavItem(
              label: 'FEATURES',
              onTap: () {
                Navigator.pop(context);
                onScrollToFeatures?.call();
              },
            ),
            _MobileNavItem(
              label: 'HOW IT WORKS',
              onTap: () {
                Navigator.pop(context);
                onScrollToWorkflow?.call();
              },
            ),
            _MobileNavItem(
              label: 'LAUNCH APP',
              onTap: () {
                Navigator.pop(context);
                context.go('/upload');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? AppTheme.primary
        : (_hovered ? Colors.white : Colors.white60);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppTheme.primary.withValues(alpha: 0.12)
                : (_hovered ? AppTheme.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isActive
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
      title: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
