import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
          color: AppTheme.background.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.glowShadow(opacity: 0.08, blur: 32),
        ),
        child: Row(
          children: [
            // ── Logo ──
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
                      boxShadow: AppTheme.glowShadow(opacity: 0.3, blur: 12),
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      color: Color(0xFF04241F),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        fontSize: 17,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Perma',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: '.link',
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
              _NavLink(label: 'Home', onTap: () => context.go('/')),
              _NavLink(label: 'Why', onTap: onScrollToWhy),
              _NavLink(label: 'Features', onTap: onScrollToFeatures),
              _NavLink(label: 'Protocol', onTap: onScrollToWorkflow),
              const SizedBox(width: 16),
              // Launch A File button with rocket icon and text
              Semantics(
                label: 'Launch A File',
                child: TextButton.icon(
                  onPressed: () => context.go('/upload'),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                  label: const Text('Launch A File'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.onSurface,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (isMobile)
              IconButton(
                onPressed: () => _showMobileMenu(context),
                icon: const Icon(Icons.menu_rounded),
                color: AppTheme.onSurface,
              )
            else
              // GitHub button - now takes you to the GitHub repository
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://github.com/Ben-W3cloud/perma_link'),
                  mode: LaunchMode.externalApplication,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.muted,
                  side: BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const _GitHubIcon(),
                label: const Text('GitHub', style: TextStyle(fontSize: 13)),
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
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _MobileNavItem(
              label: 'Home',
              onTap: () {
                Navigator.pop(context);
                context.go('/');
              },
            ),
            _MobileNavItem(
              label: 'Why',
              onTap: () {
                Navigator.pop(context);
                onScrollToWhy?.call();
              },
            ),
            _MobileNavItem(
              label: 'Features',
              onTap: () {
                Navigator.pop(context);
                onScrollToFeatures?.call();
              },
            ),
            _MobileNavItem(
              label: 'Protocol',
              onTap: () {
                Navigator.pop(context);
                onScrollToWorkflow?.call();
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/upload');
                },
                icon: const Icon(Icons.upload_rounded, size: 16),
                label: const Text('Upload a file'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _hovered ? AppTheme.onSurface : AppTheme.muted,
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
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Small GitHub SVG icon painted via CustomPaint ─────────────────────────
class _GitHubIcon extends StatelessWidget {
  const _GitHubIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(14, 14),
      painter: _GitHubPainter(color: AppTheme.muted),
    );
  }
}

class _GitHubPainter extends CustomPainter {
  const _GitHubPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Simplified GitHub mark path (scaled to size)
    final path = Path();
    final s = size.width / 24.0;
    path.moveTo(12 * s, 0.5 * s);
    path.addOval(
      Rect.fromCircle(center: Offset(12 * s, 12 * s), radius: 11.5 * s),
    );
    canvas.drawPath(path, paint);

    // Draw the cat silhouette cutout — approximate with a simple icon
    final inner = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill;
    path.reset();
    path.addOval(
      Rect.fromCircle(center: Offset(12 * s, 10 * s), radius: 5 * s),
    );
    canvas.drawPath(path, inner);

    // Body
    path.reset();
    path.moveTo(6 * s, 23 * s);
    path.quadraticBezierTo(6 * s, 17 * s, 12 * s, 17 * s);
    path.quadraticBezierTo(18 * s, 17 * s, 18 * s, 23 * s);
    canvas.drawPath(path, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
