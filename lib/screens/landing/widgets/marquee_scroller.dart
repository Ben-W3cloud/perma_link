import 'dart:math' as math;

import 'package:flutter/material.dart';

class MarqueeScroller extends StatefulWidget {
  const MarqueeScroller({
    super.key,
    required this.children,
    this.duration = const Duration(seconds: 20),
    this.itemExtent = 332,
    this.pauseOnHover = true,
    this.diagonalAmplitude = 20.0,
  });

  final List<Widget> children;
  final Duration duration;
  final double itemExtent;
  final bool pauseOnHover;
  final double diagonalAmplitude;

  @override
  State<MarqueeScroller> createState() => _MarqueeScrollerState();
}

class _MarqueeScrollerState extends State<MarqueeScroller>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant MarqueeScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (!_hovered || !widget.pauseOnHover) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setHover(bool hovered) {
    if (!widget.pauseOnHover || _hovered == hovered) return;
    setState(() => _hovered = hovered);
    if (hovered) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 700;
    final loopWidth = widget.children.length * widget.itemExtent;
    final boundedChildren = widget.children
        .map((c) => RepaintBoundary(child: c))
        .toList(growable: false);
    final doubled = <Widget>[...boundedChildren, ...boundedChildren];

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Diagonal animation: X-axis scroll + Y-axis sine wave oscillation
              final xOffset = -loopWidth * _controller.value;
              final yOffset = isMobile
                  ? 0.0
                  : math.sin(_controller.value * 2 * math.pi) * widget.diagonalAmplitude;

              return OverflowBox(
                minWidth: loopWidth * 2,
                maxWidth: loopWidth * 2,
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(xOffset, yOffset),
                  child: child,
                ),
              );
            },
            child: Row(children: doubled),
          ),
        ),
      ),
    );
  }
}
