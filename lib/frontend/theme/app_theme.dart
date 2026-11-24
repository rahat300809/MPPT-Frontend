import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Softened HelioGlass-inspired day palette (easier on the eyes).
class AppColors {
  static const background = Color(0xFFF7F4EE); // lighter sand
  static const surface = Color(0xFFFFFCF8); // near-white card
  static const surfaceLow = Color(0xFFF0EBE3);
  static const surfaceHigh = Color(0xFFE6E0D6);
  static const onSurface = Color(0xFF2A2724); // softer than pure espresso
  static const onVariant = Color(0xFF8A8378);
  static const primary = Color(0xFFE8934A); // softer sunset orange
  static const primaryContainer = Color(0xFFFFF3E8);
  static const primaryFixed = Color(0xFFF8D59A);
  static const secondary = Color(0xFF3F8F5A); // softer sage
  static const secondaryContainer = Color(0xFFEAF6EE);
  static const secondaryFixed = Color(0xFFEAF6EE);
  static const tertiary = Color(0xFF5B7FCF); // softer cobalt
  static const outline = Color(0xFFD9D2C7);
  static const error = Color(0xFFD45B5B);
  static const badgeOkBg = Color(0xFFEAF6EE);
  static const badgeWarnBg = Color(0xFFFFF3E8);
  static const badgeErrBg = Color(0xFFFBECEC);
  static const navBarBg = Color(0xE8F0EBE3);
  static const mpptAccent = Color(0xFF5B7FCF);
  static const loadAccent = Color(0xFFD8894A);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: 36,
        color: AppColors.onSurface,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: AppColors.onSurface,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: AppColors.onSurface,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: AppColors.onSurface,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        color: AppColors.onVariant,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.onSurface,
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: AppColors.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.onVariant,
        );
      }),
    ),
  );
}
