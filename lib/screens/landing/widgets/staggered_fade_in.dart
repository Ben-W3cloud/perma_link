import 'dart:async';
import 'package:flutter/material.dart';

class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    super.key,
    required this.child,
    required this.delay,
    this.duration = const Duration(milliseconds: 800),
    this.translationOffset = const Offset(0, 40),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset translationOffset;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _translation;
  bool _completed = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _translation = Tween<Offset>(
      begin: widget.translationOffset,
      end: Offset.zero,
    ).animate(curved);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _completed = true);
      }
    });

    _delayTimer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fast path: once the animation completes we drop both the FadeTransition
    // (which can still saveLayer at intermediate opacities) and the
    // AnimatedBuilder-driven Transform, and just render the child statically.
    if (_completed) return widget.child;

    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _translation,
        builder: (context, child) {
          return Transform.translate(offset: _translation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
