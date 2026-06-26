import 'package:fluffy_link/core/theme.dart';
import 'package:flutter/material.dart';

/// Text widget with gradient fill using ShaderMask
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.textAlign,
    this.textScaler,
    this.overflow,
    this.maxLines,
  });

  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextScaler? textScaler;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        textScaler: textScaler,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }
}

/// Pre-configured gradient text styles for the app
class AppGradientText {
  /// Hero headline gradient: primary → accent
  static Gradient heroHeadline() => LinearGradient(
    colors: [
      AppTheme.primary,
      AppTheme.accent,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle gradient for subheadings
  static Gradient subtle() => LinearGradient(
    colors: [
      AppTheme.onSurfaceBright,
      AppTheme.onSurface.withValues(alpha: 0.7),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Primary brand gradient
  static Gradient brand() => AppTheme.primaryGradient;
}
