import 'dart:math' as math;

import 'package:fluffy_link/core/app_navbar.dart';
import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/screens/landing/widgets/network_background.dart';
import 'package:fluffy_link/screens/landing/widgets/marquee_scroller.dart';
import 'package:fluffy_link/screens/landing/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);
  final GlobalKey _whyKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _workflowKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncScrollOffset);
  }

  void _syncScrollOffset() {
    _scrollOffset.value = _scrollController.offset;
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOutCubic,
      alignment: 0.03,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncScrollOffset);
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                _HeroSection(
                  scrollOffset: _scrollOffset,
                  onExplore: () => _scrollToSection(_workflowKey),
                ),
                _ScrollReveal(
                  key: _whyKey,
                  scrollController: _scrollController,
                  child: const _WhySection(),
                ),
                _ScrollReveal(
                  key: _featuresKey,
                  scrollController: _scrollController,
                  child: const _FeaturesSection(),
                ),
                _ScrollReveal(
                  key: _workflowKey,
                  scrollController: _scrollController,
                  child: const _WorkflowSection(),
                ),
                _ScrollReveal(
                  scrollController: _scrollController,
                  child: const _BottomCTASection(),
                ),
                const _Footer(),
              ],
            ),
          ),
          SafeArea(
            bottom: false,
            child: AppNavBar(
              currentRoute: '/',
              scrollController: _scrollController,
              onScrollToWhy: () => _scrollToSection(_whyKey),
              onScrollToFeatures: () => _scrollToSection(_featuresKey),
              onScrollToWorkflow: () => _scrollToSection(_workflowKey),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.scrollOffset, required this.onExplore});

  final ValueNotifier<double> scrollOffset;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final heroHeight = math.max(size.height * 0.96, isMobile ? 860.0 : 800.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dot-grid background with parallax
          Positioned.fill(
            child: RepaintBoundary(
              child: ValueListenableBuilder<double>(
                valueListenable: scrollOffset,
                builder: (_, scroll, child) => Transform.translate(
                  offset: Offset(0, scroll * 0.18),
                  child: child,
                ),
                child: const Opacity(opacity: 0.55, child: NetworkBackground()),
              ),
            ),
          ),
          // Radial teal glow overlay top-left
          Positioned(
            left: -160,
            top: size.height * 0.20,
            child: IgnorePointer(
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Radial teal glow bottom-right
          Positioned(
            right: -160,
            bottom: 40,
            child: IgnorePointer(
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryDark.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom fade
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.background.withValues(alpha: 0.0),
                      AppTheme.background,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Hero content with scroll-fade
          Align(
            alignment: Alignment.center,
            child: RepaintBoundary(
              child: ValueListenableBuilder<double>(
                valueListenable: scrollOffset,
                builder: (_, scroll, child) {
                  final progress = (scroll / heroHeight).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: (1.0 - progress * 0.4).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1.0 - progress * 0.04,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 20 : 48,
                    isMobile ? 148 : 118,
                    isMobile ? 20 : 48,
                    isMobile ? 28 : 20,
                  ),
                  child: _HeroCopy(isMobile: isMobile, onExplore: onExplore),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.isMobile, required this.onExplore});

  final bool isMobile;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Status badge ──
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 80),
            child: _StatusBadge(),
          ),
          const SizedBox(height: 20),

          // ── Headline ──
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 200),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: isMobile ? 36 : 64,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -1.0,
                    color: AppTheme.onSurfaceBright,
                  ),
                  children: [
                    const TextSpan(text: 'Short links.\n'),
                    TextSpan(
                      text: 'Permanent',
                      style: TextStyle(
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryLight],
                          ).createShader(const Rect.fromLTWH(0, 0, 400, 80)),
                      ),
                    ),
                    const TextSpan(text: ' files.'),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 18 : 24),

          // ── Subtitle ──
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 400),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(
                'Upload any file. Get a short link. Share it everywhere.\nStored on Walrus — decentralized, permanent, unstoppable.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.muted,
                  fontSize: isMobile ? 15 : 18,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 28 : 36),

          // ── CTA buttons ──
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 600),
            child: Wrap(
              spacing: 14,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/upload'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: const Color(0xFF04241F),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 32,
                      vertical: isMobile ? 14 : 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: Text(
                    'Upload a file',
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onExplore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.onSurface,
                    side: BorderSide(color: AppTheme.border),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 32,
                      vertical: isMobile ? 14 : 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    size: 18,
                  ),
                  label: Text(
                    'See how it works',
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),

          // ── Demo card ──
          StaggeredFadeIn(
            delay: const Duration(milliseconds: 800),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isMobile ? 340 : 520),
              child: const _DemoCard(),
            ),
          ),

          // ── Scroll indicator ──
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                'SCROLL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  letterSpacing: 3,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 1,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primary, Colors.transparent],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(),
          const SizedBox(width: 8),
          Text(
            'Running on Walrus testnet',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 1,
            height: 12,
            color: AppTheme.border,
          ),
          Text(
            'v1.0',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primary.withValues(alpha: 0.5 + _anim.value * 0.5),
        ),
      ),
    );
  }
}

// ── Demo card (mock terminal) ─────────────────────────────────────────────

class _DemoCard extends StatelessWidget {
  const _DemoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.08),
            AppTheme.background.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
        boxShadow: AppTheme.glowShadow(opacity: 0.20, blur: 60),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Window chrome
          Row(
            children: [
              _dot(const Color(0xFFF87171)),
              const SizedBox(width: 6),
              _dot(const Color(0xFFFBBF24)),
              const SizedBox(width: 6),
              _dot(const Color(0xFF4ADE80)),
              const Spacer(),
              Text(
                'perma.link · upload complete',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _TerminalRow(
            label: 'file:',
            value: 'thesis_v3_final.pdf',
            context: context,
          ),
          const SizedBox(height: 8),
          _TerminalRow(
            label: 'blob:',
            value: 'wAtcbEtCYyCX2gPcAv6z84NL...',
            muted: true,
            context: context,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'link: ',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppTheme.muted,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                ).createShader(bounds),
                child: const Text(
                  'perma.link/xk4r',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TerminalRow(
            label: 'hits:',
            value: '1,284',
            context: context,
            suffix: '  ↑ 12% this week',
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppTheme.border),
          const SizedBox(height: 10),
          Row(
            children: [
              _PulsingDot(),
              const SizedBox(width: 8),
              Text(
                'stored on ',
                style: TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
              Text(
                'Walrus',
                style: const TextStyle(fontSize: 11, color: AppTheme.primary),
              ),
              const Spacer(),
              Text(
                '#0001284',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppTheme.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 11,
    height: 11,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.7),
    ),
  );
}

class _TerminalRow extends StatelessWidget {
  const _TerminalRow({
    required this.label,
    required this.value,
    required this.context,
    this.muted = false,
    this.suffix,
  });

  final String label;
  final String value;
  final BuildContext context;
  final bool muted;
  final String? suffix;

  @override
  Widget build(BuildContext _) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: AppTheme.muted,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: muted ? AppTheme.muted : AppTheme.onSurfaceBright,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (suffix != null)
          Text(
            suffix!,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppTheme.muted,
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WHY SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _WhySection extends StatelessWidget {
  const _WhySection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;

    final cards = const [
      _WhyCard(
        svgPath: Icons.bar_chart_rounded,
        tagLabel: 'THE GAP',
        title: "Blob IDs aren't URLs",
        description:
            'Walrus blob identifiers are cryptographic hashes — durable on chain, invisible to friends. Nobody clicks a 32-character token.',
      ),
      _WhyCard(
        svgPath: Icons.check_circle_outline_rounded,
        tagLabel: 'THE FIX',
        title: 'Four characters, forever',
        description:
            'We issue a short code — perma.link/xk4r — that resolves to your Walrus blob. Memorable. Shareable. Permanent.',
        accentText: 'perma.link/xk4r',
      ),
      _WhyCard(
        svgPath: Icons.location_on_outlined,
        tagLabel: 'THE PROMISE',
        title: 'No server, no expiry',
        description:
            'The file lives on Walrus. The code lives on chain. There\'s no backend you need to trust. Your link won\'t die because we shut down.',
      ),
    ];

    return Container(
      width: double.infinity,
      color: AppTheme.background,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
        vertical: isMobile ? 70 : 104,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const _SectionTag(label: 'WHY THIS EXISTS'),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: isMobile ? 28 : 48,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                    children: [
                      const TextSpan(text: 'Walrus gives you permanence.\n'),
                      TextSpan(
                        text: 'We give you ',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                      WidgetSpan(
                        child: ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryLight],
                          ).createShader(b),
                          child: Text(
                            'shareability',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontSize: isMobile ? 28 : 48,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: '.',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'Walrus is brilliant decentralized storage — your files live on a distributed network, permanent and tamper-proof. But the blob IDs it spits out aren\'t built for humans. Perma.link bridges that gap.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.muted,
                    height: 1.65,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 32 : 52),
              // Cards
              if (isMobile)
                Column(
                  children: cards
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: c,
                        ),
                      )
                      .toList(),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cards
                      .map(
                        (c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: c,
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhyCard extends StatefulWidget {
  const _WhyCard({
    required this.svgPath,
    required this.tagLabel,
    required this.title,
    required this.description,
    this.accentText,
  });

  final IconData svgPath;
  final String tagLabel;
  final String title;
  final String description;
  final String? accentText;

  @override
  State<_WhyCard> createState() => _WhyCardState();
}

class _WhyCardState extends State<_WhyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(28),
        transform: _hovered
            ? Matrix4.translationValues(0, -4, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: _hovered ? 0.04 : 0.02),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: _hovered
                ? AppTheme.primary.withValues(alpha: 0.3)
                : AppTheme.border,
          ),
          boxShadow: _hovered
              ? AppTheme.glowShadow(opacity: 0.12, blur: 30)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(widget.svgPath, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              widget.tagLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
                letterSpacing: 1.5,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FEATURES SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return ClipRect(
      child: Container(
        width: double.infinity,
        color: AppTheme.background,
        padding: EdgeInsets.only(
          top: isMobile ? 34 : 48,
          bottom: isMobile ? 80 : 112,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTag(label: 'FEATURE SHOWCASE'),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontSize: isMobile ? 28 : 46,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                              children: [
                                const TextSpan(text: 'Built to replace the\n'),
                                WidgetSpan(
                                  child: ShaderMask(
                                    shaderCallback: (b) => const LinearGradient(
                                      colors: [
                                        AppTheme.primary,
                                        AppTheme.primaryLight,
                                      ],
                                    ).createShader(b),
                                    child: Text(
                                      'bit.lys of the world.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontSize: isMobile ? 28 : 46,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.white,
                                            height: 1.1,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isMobile) const SizedBox(width: 32),
                        if (!isMobile)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Text(
                              'Hover any card for the full story. The carousel loops continuously — pause it anytime.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isMobile ? 32 : 52),
            // Auto-scrolling carousel
            RepaintBoundary(
              child: Transform.rotate(
                angle: isMobile ? 0 : -2.2 * math.pi / 180,
                child: Transform.scale(
                  scale: isMobile ? 1 : 1.06,
                  child: SizedBox(
                    height: isMobile ? 340 : 400,
                    child: MarqueeScroller(
                      duration: const Duration(seconds: 34),
                      itemExtent: isMobile ? 280 : 330,
                      children: const [
                        _FeatureCard(
                          tag: 'BLOB STORAGE',
                          title: 'Blob Storage',
                          subtitle:
                              'Files live on Walrus\' decentralized network.',
                          deepDive:
                              'Every file is encoded and dispersed across Walrus\' network of storage nodes using erasure coding. No single server holds your file — it\'s reconstructed on demand from redundant shards.',
                          number: '01 / 05',
                          icon: Icons.dns_outlined,
                        ),
                        _FeatureCard(
                          tag: 'SHORT URL',
                          title: 'Short URL',
                          subtitle: 'Four characters resolve to any blob.',
                          deepDive:
                              'Perma.link maps a human-readable 4-char code to the underlying Walrus blob. The mapping is stored on the Sui chain — verifiable and tamper-resistant. Codes are reserved forever.',
                          number: '02 / 05',
                          icon: Icons.link_rounded,
                        ),
                        _FeatureCard(
                          tag: 'LIVE ANALYTICS',
                          title: 'Live Analytics',
                          subtitle:
                              'Hits, referrers, devices — on each file page.',
                          deepDive:
                              'Every /:code page doubles as a stats dashboard. See clicks over time, top referrers, and device breakdowns. Analytics are privacy-first: aggregated and non-identifying.',
                          number: '03 / 05',
                          icon: Icons.bar_chart_rounded,
                        ),
                        _FeatureCard(
                          tag: 'FAST REDIRECT',
                          title: 'Fast Redirect',
                          subtitle:
                              'Sub-second code resolution, straight to blob.',
                          deepDive:
                              'Edge workers resolve your short code in under 200ms by reading the on-chain index. No cold starts, no database round trips. Cached resolution means repeat visits are near-instant.',
                          number: '04 / 05',
                          icon: Icons.bolt_outlined,
                        ),
                        _FeatureCard(
                          tag: 'DROP ANY FILE',
                          title: 'Drop Any File',
                          subtitle: 'PDFs, images, zips — anything under 10MB.',
                          deepDive:
                              'Perma.link accepts any file type up to 10MB. Browsers stream your file directly to Walrus via the Dartus SDK — we never touch your bytes on a server. Drag, drop, done.',
                          number: '05 / 05',
                          icon: Icons.upload_file_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.deepDive,
    required this.number,
    required this.icon,
  });

  final String tag;
  final String title;
  final String subtitle;
  final String deepDive;
  final String number;
  final IconData icon;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onHover(bool h) {
    setState(() => _hovered = h);
    if (h) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: Container(
          width: isMobile ? 220 : 260,
          height: isMobile ? 320 : 360,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F1A24), Color(0xFF070B10)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Stack(
            children: [
              // ── Front layer ──
              AnimatedOpacity(
                duration: const Duration(milliseconds: 280),
                opacity: _hovered ? 0.15 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _TagChip(label: widget.tag),
                          Text(
                            widget.number,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.muted, fontSize: 10),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Center(
                        child: Icon(
                          widget.icon,
                          size: isMobile ? 80 : 96,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Deep-dive overlay (slides up from bottom) ──
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _slide,
                  builder: (_, child) => FractionalTranslation(
                    translation: Offset(0, 1.0 - _slide.value),
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.10),
                          const Color(0xFF070B10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TagChip(label: 'DEEP DIVE'),
                        const SizedBox(height: 12),
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: Text(
                            widget.deepDive,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted, height: 1.6),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        const Spacer(),
                        Divider(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '↑ hover to explore',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Top teal border glow on hover
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 2,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _hovered ? 1.0 : 0.0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.primary,
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WORKFLOW / PROTOCOL SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;

    final cards = const [
      _ProtocolCard(
        step: '01',
        label: 'CLIENT_INPUT',
        title: 'Upload',
        description:
            'Select any file under 10MB. The client streams it directly to the Walrus publisher nodes via the Dartus SDK. Your bytes never pass through a Perma.link server.',
        icon: Icons.file_upload_outlined,
      ),
      _ProtocolCard(
        step: '02',
        label: 'WALRUS_BLOB',
        title: 'Store',
        description:
            'Walrus returns a certified blob ID — a long cryptographic identifier anchored on-chain. Perma.link writes a short code → blob ID mapping to the resolver contract.',
        icon: Icons.storage_outlined,
      ),
      _ProtocolCard(
        step: '03',
        label: 'PERMA_ROUTE',
        title: 'Share',
        description:
            'Hand out perma.link/xk4r. Visitors hit our edge, which resolves the code and streams the blob. Every visit tallies on the live stats page.',
        icon: Icons.share_outlined,
      ),
    ];

    return Container(
      width: double.infinity,
      color: AppTheme.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
        vertical: isMobile ? 78 : 118,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTag(label: 'PROTOCOL WORKFLOW'),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: isMobile ? 28 : 48,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                  children: [
                    const TextSpan(text: 'Three moves from\n'),
                    WidgetSpan(
                      child: ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryLight],
                        ).createShader(b),
                        child: Text(
                          'file',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: isMobile ? 28 : 48,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                height: 1.1,
                              ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' to '),
                    WidgetSpan(
                      child: ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryLight],
                        ).createShader(b),
                        child: Text(
                          'forever.',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: isMobile ? 28 : 48,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                height: 1.1,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 32 : 52),
              isMobile
                  ? Column(
                      children: cards
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: c,
                            ),
                          )
                          .toList(),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cards
                          .map(
                            (c) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: c,
                              ),
                            ),
                          )
                          .toList(),
                    ),
              SizedBox(height: isMobile ? 20 : 32),
              const _ProtocolNoteBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtocolCard extends StatefulWidget {
  const _ProtocolCard({
    required this.step,
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String step;
  final String label;
  final String title;
  final String description;
  final IconData icon;

  @override
  State<_ProtocolCard> createState() => _ProtocolCardState();
}

class _ProtocolCardState extends State<_ProtocolCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.all(28),
          transform: _hovered
              ? Matrix4.translationValues(0, -6, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F1A24), Color(0xFF070B10)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: _hovered
                  ? AppTheme.primary.withValues(alpha: 0.45)
                  : AppTheme.border,
            ),
            boxShadow: _hovered
                ? AppTheme.glowShadow(opacity: 0.10, blur: 28)
                : null,
          ),
          child: Stack(
            children: [
              // Ghost step number
              Positioned(
                top: 0,
                right: 0,
                child: Text(
                  widget.step,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 54,
                    color: Colors.white.withValues(alpha: 0.05),
                    height: 1,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.step} · ${widget.label}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.muted,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.15),
                          AppTheme.primary.withValues(alpha: 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(widget.icon, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtocolNoteBanner extends StatelessWidget {
  const _ProtocolNoteBanner();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 760;
    final facts = const [
      _ProtocolFact(
        icon: Icons.lock_outline_rounded,
        label: 'Storage',
        value: 'Walrus blob backed',
      ),
      _ProtocolFact(
        icon: Icons.route_outlined,
        label: 'Route',
        value: 'Short code redirect',
      ),
      _ProtocolFact(
        icon: Icons.speed_rounded,
        label: 'Flow',
        value: 'Upload to share in one pass',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.06),
            AppTheme.primary.withValues(alpha: 0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.20)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  facts.expand((f) => [f, const SizedBox(height: 16)]).toList()
                    ..removeLast(),
            )
          : Row(children: facts.map((f) => Expanded(child: f)).toList()),
    );
  }
}

class _ProtocolFact extends StatelessWidget {
  const _ProtocolFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM CTA SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _BottomCTASection extends StatelessWidget {
  const _BottomCTASection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      width: double.infinity,
      color: AppTheme.background,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
        vertical: isMobile ? 80 : 120,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              const _SectionTag(label: 'START NOW'),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: isMobile ? 36 : 62,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                  children: [
                    const TextSpan(text: 'Drop a file.\n'),
                    WidgetSpan(
                      child: ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryLight],
                        ).createShader(b),
                        child: Text(
                          'Outlive the internet.',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontSize: isMobile ? 36 : 62,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                height: 1.1,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Free to use. Open source. Built on Walrus decentralized storage.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.muted,
                  fontSize: isMobile ? 14 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/upload'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: const Color(0xFF04241F),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 36,
                        vertical: isMobile ? 14 : 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: Text(
                      'Upload your first file',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.muted,
                      side: BorderSide(color: AppTheme.border),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 36,
                        vertical: isMobile ? 14 : 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Read the docs',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FOOTER
// ═══════════════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 760;

    return Container(
      width: double.infinity,
      color: AppTheme.background,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 24 : 48,
        0,
        isMobile ? 24 : 48,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppTheme.border),
          const SizedBox(height: 40),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FooterBrand(context: context),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FooterLinks(
                            title: 'PRODUCT',
                            links: _productLinks,
                          ),
                        ),
                        Expanded(
                          child: _FooterLinks(
                            title: 'PROTOCOL',
                            links: _protocolLinks,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _FooterBrand(context: context)),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 2,
                      child: _FooterLinks(
                        title: 'PRODUCT',
                        links: _productLinks,
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 2,
                      child: _FooterLinks(
                        title: 'PROTOCOL',
                        links: _protocolLinks,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 40),
          Divider(color: AppTheme.border),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  '© 2025 Perma.link — Built on Walrus. Open source forever.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.muted,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mainnet operational',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _productLinks = [
    ('Upload', '/upload'),
    ('Docs', ''),
    ('Changelog', ''),
  ];

  static const _protocolLinks = [
    ('GitHub', ''),
    ('Walrus', ''),
    ('Sui Explorer', ''),
  ];
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.link_rounded,
                color: Color(0xFF04241F),
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
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
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            'A decentralized URL shortener built on Walrus storage. Short links that outlast the servers they\'re born on.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.muted,
              height: 1.65,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks({required this.title, required this.links});

  final String title;
  final List<(String, String)> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.muted,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: link.$2.isNotEmpty ? () => context.go(link.$2) : null,
                child: Text(
                  link.$1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _SectionTag extends StatelessWidget {
  const _SectionTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.primary,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.primary,
          fontSize: 9,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCROLL REVEAL
// ═══════════════════════════════════════════════════════════════════════════

class _ScrollReveal extends StatefulWidget {
  const _ScrollReveal({
    super.key,
    required this.scrollController,
    required this.child,
  });

  final ScrollController scrollController;
  final Widget child;

  @override
  State<_ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<_ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _translation;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _translation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);

    widget.scrollController.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (_visible || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    if (pos.dy < screenH * 0.88) {
      _visible = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_visible && _controller.isCompleted) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _translation, child: widget.child),
    );
  }
}
