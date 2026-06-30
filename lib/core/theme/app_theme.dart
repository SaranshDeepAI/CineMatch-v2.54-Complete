import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';

/// Static fallback colors — used when ThemeController not ready
/// (e.g. during app initialization)
class AppColors {
  // --- Backgrounds ---
  static const Color background  = Color(0xFF0D0D0F);
  static const Color surface     = Color(0xFF1A1A2E);
  static const Color cardBg      = Color(0xFF16213E);
  static const Color cardBgLight = Color(0xFF1F2B47);

  // --- Accents ---
  static const Color primary     = Color(0xFFE63946);
  static const Color secondary   = Color(0xFF7B2FBE);
  static const Color accent      = Color(0xFFF4A261);
  static const Color accentBlue  = Color(0xFF4CC9F0);

  // --- Text (these NEVER change with theme) ---
  static const Color textPrimary   = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted     = Color(0xFF6B7280);

  // --- Status (these NEVER change with theme) ---
  static const Color success = Color(0xFF4CAF50);
  static const Color error   = Color(0xFFCF6679);
  static const Color warning = Color(0xFFFFB74D);

  // --- Static Gradients (fallback) ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE63946), Color(0xFF7B2FBE)],
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0D0D0F), Color(0xFF1A1A2E), Color(0xFF0D0D0F)],
    begin: Alignment.topCenter,
    end:   Alignment.bottomCenter,
  );
}

/// Dynamic colors — always reads from ThemeController
/// Why separate class? → screens using T.primary get live updates
/// while AppColors.primary stays as a const fallback
class T {
  static ThemeController? get _c {
    try { return Get.find<ThemeController>(); }
    catch (_) { return null; }
  }

  static Color get primary        => _c?.primary        ?? AppColors.primary;
  static Color get secondary      => _c?.secondary      ?? AppColors.secondary;
  static Color get accent         => _c?.accent         ?? AppColors.accent;
  static Color get background     => _c?.background     ?? AppColors.background;
  static Color get surface        => _c?.surface        ?? AppColors.surface;
  static Color get cardBg         => _c?.cardBg         ?? AppColors.cardBg;
  static Color get cardBgLight    => _c?.cardBgLight    ?? AppColors.cardBgLight;

  static LinearGradient get primaryGradient =>
      _c?.primaryGradient ?? AppColors.primaryGradient;
  static LinearGradient get cardGradient    =>
      _c?.cardGradient    ?? AppColors.cardGradient;
  static LinearGradient get splashGradient  =>
      _c?.splashGradient  ?? AppColors.splashGradient;

  /// Text and status colors never change — always use AppColors
  static const Color textPrimary   = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted     = AppColors.textMuted;
  static const Color success       = AppColors.success;
  static const Color error         = AppColors.error;
  static const Color warning       = AppColors.warning;
  static const Color accentBlue    = AppColors.accentBlue;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.primary,
        secondary: AppColors.secondary,
        surface:   AppColors.surface,
        error:     AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme().copyWith(
        displayLarge: GoogleFonts.rajdhani(
          fontSize: 32, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: 1.2,
        ),
        displayMedium: GoogleFonts.rajdhani(
          fontSize: 26, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.rajdhani(
          fontSize: 22, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.rajdhani(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.rajdhani(
          fontSize: 16, fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.rajdhani(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.rajdhani(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: 0.8,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBg,
        hintStyle: GoogleFonts.rajdhani(
          color: AppColors.textMuted, fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:     AppColors.surface,
        selectedItemColor:   AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type:      BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardBg,
        selectedColor:   AppColors.primary.withValues(alpha: 0.3),
        labelStyle: GoogleFonts.rajdhani(
          color: AppColors.textSecondary, fontSize: 12,
        ),
        side: const BorderSide(color: AppColors.cardBgLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}