import 'dart:math' as math;

import 'package:fluffy_link/core/app_navbar.dart';
import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/screens/landing/widgets/network_background.dart';
import 'package:fluffy_link/screens/landing/widgets/marquee_scroller.dart';
import 'package:fluffy_link/screens/landing/widgets/staggered_fade_in.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> _scrollToWorkflow() async {
    await _scrollToSection(_workflowKey);
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
                  onExplore: _scrollToWorkflow,
                ),
                _SlantedTransition(),
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

class _HeroSection extends StatefulWidget {
  const _HeroSection({required this.scrollOffset, required this.onExplore});

  final ValueListenable<double> scrollOffset;
  final VoidCallback onExplore;

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final heroHeight = math.max(size.height * 0.96, isMobile ? 820.0 : 780.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Parallax background — only this subtree rebuilds with scroll.
          Positioned.fill(
            child: RepaintBoundary(
              child: ValueListenableBuilder<double>(
                valueListenable: widget.scrollOffset,
                builder: (context, scroll, child) {
                  final parallax = reducedMotion ? 0.0 : scroll * 0.18;
                  return Transform.translate(
                    offset: Offset(0, parallax),
                    child: child,
                  );
                },
                child: const Opacity(opacity: 0.55, child: NetworkBackground()),
              ),
            ),
          ),
          // Gradient mesh overlay — cinematic depth effect.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.4),
                    radius: 1.1,
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.22),
                      AppTheme.background.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom fade into next section.
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
          // Center hero content — only the wrapping transform listens to scroll.
          Align(
            alignment: Alignment.center,
            child: RepaintBoundary(
              child: ValueListenableBuilder<double>(
                valueListenable: widget.scrollOffset,
                builder: (context, scroll, child) {
                  final progress = (scroll / heroHeight).clamp(0.0, 1.0);
                  final heroOpacity = 1.0 - (progress * 0.34);
                  final heroScale = 1.0 - (progress * 0.045);
                  return Opacity(
                    opacity: heroOpacity,
                    child: Transform.scale(scale: heroScale, child: child),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 20 : 48,
                    isMobile ? 142 : 118,
                    isMobile ? 20 : 48,
                    isMobile ? 44 : 36,
                  ),
                  child: _HeroCopy(
                    isMobile: isMobile,
                    onExplore: widget.onExplore,
                  ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StaggeredFadeIn(
          delay: const Duration(milliseconds: 80),
          child: _HeroBadge(compact: isMobile),
        ),
        StaggeredFadeIn(
          delay: const Duration(milliseconds: 180),
          child: Padding(
            padding: EdgeInsets.only(top: isMobile ? 12 : 16),
            child: Text(
              'Permanent links\nfor permanent files',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: isMobile ? 30 : 48,
                fontWeight: FontWeight.w900,
                height: 1.02,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        StaggeredFadeIn(
          delay: const Duration(milliseconds: 500),
          child: Padding(
            padding: EdgeInsets.only(top: isMobile ? 18 : 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(
                'Stop sharing raw blob IDs. Upload any file to Walrus and get a clean, memorable short link that redirects to decentralized storage — forever.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontSize: isMobile ? 16 : 19,
                  fontWeight: FontWeight.w400,
                  height: 1.48,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        StaggeredFadeIn(
          delay: const Duration(milliseconds: 720),
          child: Padding(
            padding: const EdgeInsets.only(top: 36),
            child: Wrap(
              spacing: 16,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/upload'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: const Text('Start Shortening'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 28 : 44,
                      vertical: isMobile ? 16 : 22,
                    ),
                    textStyle: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onExplore,
                  icon: const Icon(
                    Icons.keyboard_double_arrow_down_rounded,
                    size: 20,
                  ),
                  label: const Text('See How It Works'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 28 : 44,
                      vertical: isMobile ? 16 : 22,
                    ),
                    textStyle: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: const [
            _AnimatedStat(target: 70, label: 'FILES STORED'),
            _AnimatedStat(target: 100, label: 'DECENTRALIZED'),
            _AnimatedStat(target: 5, label: 'EASE OF ACCESS'),
          ],
        ),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_rounded, size: 16, color: AppTheme.accent),
          const SizedBox(width: 8),
          Text(
            'FILE LINKS FOR WALRUS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStat extends StatefulWidget {
  const _AnimatedStat({required this.target, required this.label, this.duration = const Duration(milliseconds: 1500)});

  final int target;
  final String label;
  final Duration duration;

  @override
  State<_AnimatedStat> createState() => _AnimatedStatState();
}

class _AnimatedStatState extends State<_AnimatedStat> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _countAnimation = IntTween(begin: 0, end: widget.target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, child) {
              return Text(
                '${_countAnimation.value}${widget.target > 100 ? '%' : widget.target == 5 ? '/5' : '+'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
          const SizedBox(height: 5),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white54,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlantedTransition extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 110,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: _SlantedClipper(),
              child: Container(color: AppTheme.background),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlantedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _WhySection extends StatelessWidget {
  const _WhySection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;
    final pillars = const [
      _AboutPillar(
        icon: Icons.link_off_rounded,
        title: 'Blob IDs aren\'t shareable',
        description:
            'No one remembers wAtcbEtCYyCX2gPc... Short links are universal.',
      ),
      _AboutPillar(
        icon: Icons.public_rounded,
        title: 'Files should outlive feeds',
        description:
            'Decentralized storage means your files persist even when platforms disappear.',
      ),
      _AboutPillar(
        icon: Icons.query_stats_rounded,
        title: 'Sharing needs feedback',
        description:
            'Track clicks, monitor engagement, and know who\'s accessing your files.',
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
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _WhyCopy(),
                    const SizedBox(height: 30),
                    ...pillars.map(
                      (pillar) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: pillar,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 9, child: _WhyCopy()),
                    const SizedBox(width: 44),
                    Expanded(
                      flex: 10,
                      child: Column(
                        children: pillars
                            .map(
                              (pillar) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: pillar,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _WhyCopy extends StatelessWidget {
  const _WhyCopy();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 760;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHY PERMA.LINK',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Raw blob IDs\naren\'t shareable',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Walrus gives you permanent, decentralized file storage — but those 40-character blob IDs aren\'t something you\'d put in a tweet, a resume, or an email signature. Perma.link bridges the gap between decentralized permanence and human-friendly sharing.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.65,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: const [
            _AboutMetric(value: '01', label: 'UPLOAD'),
            _AboutMetric(value: '02', label: 'SHORTEN'),
            _AboutMetric(value: '03', label: 'SHARE'),
          ],
        ),
      ],
    );
  }
}

class _AboutMetric extends StatelessWidget {
  const _AboutMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 34,
              color: AppTheme.accent,
              height: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white60,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutPillar extends StatelessWidget {
  const _AboutPillar({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
            _SectionHeader(
              eyebrow: 'FEATURES',
              title: 'Everything you need,\nnothing you don\'t',
              subtitle:
                  'Upload, store, shorten, track, and redirect through one fast Walrus-backed flow.',
              compact: isMobile,
            ),
            SizedBox(height: isMobile ? 34 : 56),
            RepaintBoundary(
              child: Transform.rotate(
                angle: isMobile ? 0 : -2.2 * math.pi / 180,
                child: Transform.scale(
                  scale: isMobile ? 1 : 1.06,
                  child: SizedBox(
                    height: isMobile ? 320 : 390,
                    child: MarqueeScroller(
                      duration: const Duration(seconds: 34),
                      itemExtent: isMobile ? 292 : 332,
                      children: const [
                        _FeatureCard(
                          tag: 'UPLOAD',
                          title: 'Drop Any File',
                          description:
                              'Choose a file and hand it to the Walrus-backed upload flow.',
                          number: '01',
                          icon: Icons.upload_file_outlined,
                          accent: AppTheme.primary,
                        ),
                        _FeatureCard(
                          tag: 'WALRUS',
                          title: 'Blob Storage',
                          description:
                              'Store the file as a content blob instead of hiding it behind a private server.',
                          number: '02',
                          icon: Icons.dns_outlined,
                          accent: AppTheme.accent,
                        ),
                        _FeatureCard(
                          tag: 'LINK',
                          title: 'Short URL',
                          description:
                              'Convert the blob route into a clean link people can actually remember.',
                          number: '03',
                          icon: Icons.link_rounded,
                          accent: AppTheme.primary,
                        ),
                        _FeatureCard(
                          tag: 'STATS',
                          title: 'Live Analytics',
                          description:
                              'Check link activity from the share page without adding heavy account friction.',
                          number: '04',
                          icon: Icons.bar_chart_rounded,
                          accent: AppTheme.accent,
                        ),
                        _FeatureCard(
                          tag: 'ROUTE',
                          title: 'Fast Redirect',
                          description:
                              'Send visitors straight to the stored file through a simple permanent route.',
                          number: '05',
                          icon: Icons.bolt_outlined,
                          accent: AppTheme.primary,
                        ),
                        _FeatureCard(
                          tag: 'SECURITY',
                          title: 'Decentralized',
                          description:
                              'No single point of failure. Files distributed across the Walrus network.',
                          number: '06',
                          icon: Icons.security_rounded,
                          accent: AppTheme.accent,
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

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;
    final cards = const [
      _ProtocolCard(
        step: '01',
        title: 'Upload',
        label: 'CLIENT_INPUT',
        description:
            'Select a file under the current size limit and send bytes to the upload pipeline.',
        icon: Icons.file_upload_outlined,
      ),
      _ProtocolCard(
        step: '02',
        title: 'Store',
        label: 'WALRUS_BLOB',
        description:
            'The blob is stored on Walrus and resolved into a durable content identifier.',
        icon: Icons.storage_outlined,
      ),
      _ProtocolCard(
        step: '03',
        title: 'Share',
        label: 'PERMA_ROUTE',
        description:
            'Perma.link creates a short URL that redirects users to the stored file.',
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: Column(
          children: [
            _SectionHeader(
              eyebrow: 'HOW IT WORKS',
              title: 'Three moves from file to forever',
              subtitle:
                  'The landing page stays cinematic, but the upload flow remains simple and direct.',
              compact: isMobile,
            ),
            SizedBox(height: isMobile ? 34 : 54),
            isMobile
                ? Column(
                    children: cards
                        .map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: card,
                          ),
                        )
                        .toList(),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cards
                        .map(
                          (card) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: card,
                            ),
                          ),
                        )
                        .toList(),
                  ),
            SizedBox(height: isMobile ? 18 : 28),
            const _ProtocolNote(),
          ],
        ),
      ),
    );
  }
}

class _ProtocolNote extends StatelessWidget {
  const _ProtocolNote();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 760;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 26),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.14)),
      ),
      child: isMobile
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProtocolFact(
                  icon: Icons.lock_outline_rounded,
                  label: 'Storage',
                  value: 'Walrus blob backed',
                ),
                SizedBox(height: 16),
                _ProtocolFact(
                  icon: Icons.route_outlined,
                  label: 'Route',
                  value: 'Short code redirect',
                ),
                SizedBox(height: 16),
                _ProtocolFact(
                  icon: Icons.speed_rounded,
                  label: 'Flow',
                  value: 'Upload to share in one pass',
                ),
              ],
            )
          : const Row(
              children: [
                Expanded(
                  child: _ProtocolFact(
                    icon: Icons.lock_outline_rounded,
                    label: 'Storage',
                    value: 'Walrus blob backed',
                  ),
                ),
                Expanded(
                  child: _ProtocolFact(
                    icon: Icons.route_outlined,
                    label: 'Route',
                    value: 'Short code redirect',
                  ),
                ),
                Expanded(
                  child: _ProtocolFact(
                    icon: Icons.speed_rounded,
                    label: 'Flow',
                    value: 'Upload to share in one pass',
                  ),
                ),
              ],
            ),
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
        Icon(icon, color: AppTheme.accent, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white38,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.tag,
    required this.title,
    required this.description,
    required this.number,
    required this.icon,
    required this.accent,
  });

  final String tag;
  final String title;
  final String description;
  final String number;
  final IconData icon;
  final Color accent;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: isMobile ? 260 : 300,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          transform: _hovered
              ? Matrix4.translationValues(0.0, -8.0, 0.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.surfaceAlt : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: _hovered
                  ? widget.accent.withValues(alpha: 0.8)
                  : AppTheme.border,
            ),
            boxShadow: _hovered
                ? AppTheme.glowShadow(
                    opacity: 0.18,
                    blur: 34,
                    color: widget.accent,
                  )
                : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.tag,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _hovered ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hovered
                          ? widget.accent
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: isMobile ? 92 : 112,
                        height: isMobile ? 92 : 112,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: AppTheme.surfaceAlt,
                          border: Border.all(
                            color: widget.accent.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          size: isMobile ? 42 : 52,
                          color: _hovered ? widget.accent : Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.58),
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.number,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.white30),
                    ),
                  ],
                ),
              ),
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
    required this.title,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String step;
  final String title;
  final String label;
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
          padding: const EdgeInsets.all(26),
          transform: _hovered
              ? Matrix4.translationValues(0.0, -6.0, 0.0)
              : Matrix4.identity(),
          decoration:
              AppTheme.glassCard(
                borderRadius: AppTheme.radiusMd,
                borderColor: _hovered
                    ? AppTheme.primary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
              ).copyWith(
                boxShadow: _hovered
                    ? AppTheme.glowShadow(opacity: 0.1, blur: 26)
                    : null,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(widget.icon, color: AppTheme.primary),
                  ),
                  const Spacer(),
                  Text(
                    widget.step,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 42,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                widget.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 980),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 22 : 54,
          vertical: isMobile ? 40 : 58,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.22)),
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withValues(alpha: 0.18),
              AppTheme.primaryDark.withValues(alpha: 0.08),
              AppTheme.accent.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: AppTheme.glowShadow(opacity: 0.08, blur: 54),
        ),
        child: isMobile
            ? Column(
                children: [
                  Text(
                    'Ready?',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start sharing\npermanent links today',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: isMobile ? 34 : 56,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sign-up required. Upload a file, get a short link, done. Powered by Walrus decentralized storage.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.66),
                      height: 1.55,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 38),
                  FilledButton.icon(
                    onPressed: () => context.go('/upload'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: const Text('Launch App'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 32 : 48,
                        vertical: isMobile ? 18 : 24,
                      ),
                      textStyle: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready?',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Start sharing\npermanent links today',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sign-up required. Upload a file, get a short link, done. Powered by Walrus decentralized storage.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.66),
                                height: 1.55,
                              ),
                        ),
                        const SizedBox(height: 38),
                        FilledButton.icon(
                          onPressed: () => context.go('/upload'),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                          label: const Text('Launch App'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 24,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                  _CTAVisual(),
                ],
              ),
      ),
    );
  }
}

class _CTAVisual extends StatelessWidget {
  const _CTAVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
          ),
          Icon(
            Icons.link_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 22,
        runSpacing: 12,
        children: [
          Text(
            'Perma.link - Powered by Walrus',
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Column(
          children: [
            Text(
              eyebrow,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: compact ? 30 : 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.muted,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {});
      }
    });

    widget.scrollController.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didUpdateWidget(covariant _ScrollReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_checkVisibility);
      if (!_visible) {
        widget.scrollController.addListener(_checkVisibility);
      }
    }
  }

  void _checkVisibility() {
    if (_visible || !mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final viewportHeight = MediaQuery.of(context).size.height;
    final top = renderObject.localToGlobal(Offset.zero).dy;
    if (top < viewportHeight * 0.86) {
      _visible = true;
      // Detach immediately so we stop paying the cost on every scroll tick.
      widget.scrollController.removeListener(_checkVisibility);
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
      // Trigger one rebuild to swap into the visible branch.
      if (mounted) setState(() {});
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
    // Fast path: once fully shown, render the child plainly — no FadeTransition
    // / SlideTransition layers, so completed sections cost zero on scroll.
    if (_visible && _controller.isCompleted) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _translation, child: widget.child),
    );
  }
}
