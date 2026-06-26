import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  // ── Radius scale ─────────────────────────────────────────────────────
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusXl = 18;
  static const double radiusPill = 999;

  // ── Spacing scale ────────────────────────────────────────────────────
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double space2xl = 48;

  // ── Content width ────────────────────────────────────────────────────
  static const double maxContentWidth = 1180;

  // ── Electric Orange palette ─────────────────────────────────────────
  // Deep dark backgrounds with electric orange primary
  static const Color _backgroundDark = Color(0xFF0A0A0F); // deep charcoal
  static const Color _surfaceDark = Color(0xFF121218); // dark gray-brown surface
  static const Color _surfaceAltDark = Color(0xFF1A1A22); // elevated surface
  static const Color _borderDark = Color(0xFF2A2A35); // warm gray-brown border
  
  static const Color background = _backgroundDark;
  static const Color surface = _surfaceDark;
  static const Color surfaceAlt = _surfaceAltDark;
  static const Color border = _borderDark;

  // Brand: electric orange
  static const Color primary = Color(0xFFFF6B00); // electric orange
  static const Color primaryDark = Color(0xFFE65100); // deep orange
  static const Color primaryLight = Color(0xFFFF8F00); // bright orange

  // Accent: bright orange — complementary to primary orange
  static const Color accent = Color(0xFFFF9800);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Text
  static const Color _onSurfaceDark = Color(0xFFCACBE8); // cool-white body text
  static const Color _onSurfaceBrightDark = Color(0xFFFFFFFF);
  static const Color _mutedDark = Color(0xFF8888AA); // muted blue-gray
  static const Color _mutedDimDark = Color(0xFF5A5A7A); // dimmer
  
  static const Color onSurface = _onSurfaceDark;
  static const Color onSurfaceBright = _onSurfaceBrightDark;
  static const Color muted = _mutedDark;
  static const Color mutedDim = _mutedDimDark;

  // ── Gradients ────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F0F35), Color(0xFF07071A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Glow shadow ───────────────────────────────────────────────────────
  static List<BoxShadow> glowShadow({
    double opacity = 0.3,
    double blur = 24,
    Color color = primary,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: 0,
      ),
    ];
  }

  // ── Card decoration ───────────────────────────────────────────────────
  static BoxDecoration glassCard({
    double borderRadius = 14,
    bool showBorder = true,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(borderRadius),
      border: showBorder
          ? Border.all(color: borderColor ?? border, width: 1)
          : null,
    );
  }

  // ── Gradient card decoration (for elevated cards) ──────────────────────
  static BoxDecoration gradientCard({
    double borderRadius = 14,
    Color? borderColor,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          surface.withValues(alpha: 0.95),
          surfaceAlt.withValues(alpha: 0.85),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? border, width: 1),
    );
  }

  // ── Theme data ────────────────────────────────────────────────────────
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: _surfaceDark,
      error: error,
      onPrimary: Colors.white,
      onSurface: _onSurfaceDark,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _backgroundDark,
    textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme)
        .copyWith(
          // ── Display / Hero (Bebas Neue) ──
          displayLarge: GoogleFonts.bebasNeue(
            fontSize: 160,
            fontWeight: FontWeight.w400,
            color: _onSurfaceBrightDark,
            height: 0.85,
            letterSpacing: -1.0,
          ),
          displayMedium: GoogleFonts.bebasNeue(
            fontSize: 96,
            fontWeight: FontWeight.w400,
            color: _onSurfaceBrightDark,
            height: 0.9,
          ),
          // ── Section headings (Space Grotesk) ──
          headlineLarge: GoogleFonts.spaceGrotesk(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: _onSurfaceBrightDark,
            height: 1.15,
            letterSpacing: -0.5,
          ),
          headlineMedium: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: _onSurfaceBrightDark,
            height: 1.2,
            letterSpacing: -0.3,
          ),
          headlineSmall: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: _onSurfaceBrightDark,
            letterSpacing: -0.2,
          ),
          titleLarge: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _onSurfaceBrightDark,
          ),
          titleMedium: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _onSurfaceDark,
          ),
          bodyLarge: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: _onSurfaceDark,
          ),
          bodyMedium: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _onSurfaceDark,
          ),
          bodySmall: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _mutedDark,
          ),
          labelLarge: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _onSurfaceBrightDark,
          ),
          // ── Mono labels / code / tags (Fira Code) ──
          labelSmall: GoogleFonts.firaCode(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
            color: _mutedDark,
          ),
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: _mutedDark),
    ),
    cardTheme: CardThemeData(
      color: _surfaceDark,
      surfaceTintColor: Colors.transparent,
      shadowColor: primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _borderDark.withValues(alpha: 0.8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceDark,
      hintStyle: GoogleFonts.spaceGrotesk(color: _mutedDimDark),
      labelStyle: GoogleFonts.spaceGrotesk(color: _mutedDark),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _borderDark.withValues(alpha: 0.9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: error, width: 1.4),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _surfaceDark,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: _surfaceDark,
      modalBarrierColor: Colors.black87,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _surfaceAltDark,
      contentTextStyle: GoogleFonts.spaceGrotesk(color: _onSurfaceBrightDark),
      actionTextColor: primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: primary,
      selectionColor: primary.withValues(alpha: 0.28),
      selectionHandleColor: primary,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    dividerTheme: const DividerThemeData(color: _borderDark, thickness: 1),
  );

}
