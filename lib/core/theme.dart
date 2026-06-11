import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color primary = Color(0xFF0F766E);
  static const Color muted = Color(0xFF6B7280);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: GoogleFonts.interTextTheme(),
  );
}
