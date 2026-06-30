import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --------------------------------------------------
// THEME DATA CLASS
// --------------------------------------------------

class CineTheme {
  final String id;
  final String name;
  final String emoji;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color cardBg;
  final Color cardBgLight;
  final LinearGradient primaryGradient;
  final LinearGradient splashGradient;
  final LinearGradient cardGradient;
  final TextTheme textTheme;

  const CineTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.cardBg,
    required this.cardBgLight,
    required this.primaryGradient,
    required this.splashGradient,
    required this.cardGradient,
    required this.textTheme,
  });
}

// --------------------------------------------------
// ALL 6 THEMES
// --------------------------------------------------

class AppThemes {
  /// Why static getters? → computed once when accessed,
  /// not stored in memory unnecessarily

  // 1. ANIME — Sakura Dark (default)
  static CineTheme get anime => CineTheme(
        id: 'anime',
        name: 'Sakura Dark',
        emoji: '⛩️',
        primary: const Color(0xFFE63946),
        secondary: const Color(0xFF7B2FBE),
        accent: const Color(0xFFF4A261),
        background: const Color(0xFF0D0D0F),
        surface: const Color(0xFF1A1A2E),
        cardBg: const Color(0xFF16213E),
        cardBgLight: const Color(0xFF1F2B47),
        primaryGradient: const LinearGradient(
          colors: [Color(0xFFE63946), Color(0xFF7B2FBE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        splashGradient: const LinearGradient(
          colors: [Color(0xFF0D0D0F), Color(0xFF1A1A2E), Color(0xFF0D0D0F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        cardGradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        textTheme: GoogleFonts.rajdhaniTextTheme(),
      );

  // 2. K-DRAMA — Seoul Rose
  static CineTheme get kdrama => CineTheme(
        id: 'kdrama',
        name: 'Seoul Rose',
        emoji: '🌸',
        primary: const Color(0xFFFF6B9D),
        secondary: const Color(0xFFC44569),
        accent: const Color(0xFFFFD93D),
        background: const Color(0xFF0F0A0F),
        surface: const Color(0xFF1E1020),
        cardBg: const Color(0xFF180D1A),
        cardBgLight: const Color(0xFF251528),
        primaryGradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFC44569)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        splashGradient: const LinearGradient(
          colors: [Color(0xFF0F0A0F), Color(0xFF1E1020), Color(0xFF0F0A0F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        cardGradient: const LinearGradient(
          colors: [Color(0xFF1E1020), Color(0xFF180D1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(),
      );

  // 3. BOLLYWOOD — Mumbai Gold
  static CineTheme get bollywood => CineTheme(
        id: 'bollywood',
        name: 'Mumbai Gold',
        emoji: '✨',
        primary: const Color(0xFFF7B731),
        secondary: const Color(0xFFE55039),
        accent: const Color(0xFF2ECC71),
        background: const Color(0xFF0F0A00),
        surface: const Color(0xFF1A1200),
        cardBg: const Color(0xFF150E00),
        cardBgLight: const Color(0xFF221800),
        primaryGradient: const LinearGradient(
          colors: [Color(0xFFF7B731), Color(0xFFE55039)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        splashGradient: const LinearGradient(
          colors: [Color(0xFF0F0A00), Color(0xFF1A1200), Color(0xFF0F0A00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        cardGradient: const LinearGradient(
          colors: [Color(0xFF1A1200), Color(0xFF150E00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        textTheme: GoogleFonts.exo2TextTheme(),
      );

  // 4. INDIAN CINEMA — Kollywood Fire
  static CineTheme get indianCinema => CineTheme(
        id: 'indian_cinema',
        name: 'Kollywood Fire',
        emoji: '🔥',
        primary: const Color(0xFFFF5722),
        secondary: const Color(0xFF880E4F),
        accent: const Color(0xFFFFC107),
        background: const Color(0xFF0F0500),
        surface: const Color(0xFF1A0A00),
        cardBg: const Color(0xFF150700),
        cardBgLight: const Color(0xFF221000),
        primaryGradient: const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFF880E4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        splashGradient: const LinearGradient(
          colors: [Color(0xFF0F0500), Color(0xFF1A0A00), Color(0xFF0F0500)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        cardGradient: const LinearGradient(
          colors: [Color(0xFF1A0A00), Color(0xFF150700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        textTheme: GoogleFonts.tekoTextTheme(),
      );

  // 5. HOLLYWOOD — Noir Silver
  static CineTheme get movie => CineTheme(
        id: 'movie',
        name: 'Noir Silver',
        emoji: '🎬',
        primary: const Color(0xFF4CC9F0),
        secondary: const Color(0xFF4361EE),
        accent: const Color(0xFFF72585),
        background: const Color(0xFF050508),
        surface: const Color(0xFF0D0D1A),
        cardBg: const Color(0xFF0A0A14),
        cardBgLight: const Color(0xFF14142A),
        primaryGradient: const LinearGradient(
          colors: [Color(0xFF4CC9F0), Color(0xFF4361EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        splashGradient: const LinearGradient(
          colors: [Color(0xFF050508), Color(0xFF0D0D1A), Color(0xFF050508)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        cardGradient: const LinearGradient(
          colors: [Color(0xFF0D0D1A), Color(0xFF0A0A14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        textTheme: GoogleFonts.orbitronTextTheme(),
      );

  // 6. TV SHOWS — Emerald Night
  static CineTheme get tv => CineTheme(
        id: 'tv',
        name: 'Emerald Night',
        emoji: '📺',
        primary: const Color(0xFF2ECC71),
        secondary: const Color(0xFF1ABC9C),
        accent: const Color(0xFFF39C12),
        background: const Color(0xFF030F0A),
        surface: const Color(0xFF071A10),
        cardBg: const Color(0xFF05140C),
        cardBgLight: const Color(0xFF0A2016),
        primaryGradient: const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF1ABC9C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        splashGradient: const LinearGradient(
          colors: [Color(0xFF030F0A), Color(0xFF071A10), Color(0xFF030F0A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        cardGradient: const LinearGradient(
          colors: [Color(0xFF071A10), Color(0xFF05140C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        textTheme: GoogleFonts.rajdhaniTextTheme(),
      );

  /// Get theme by content type ID
  static CineTheme fromContentType(String? contentType) {
    switch (contentType) {
      case 'kdrama':
        return kdrama;
      case 'bollywood':
        return bollywood;
      case 'indian_cinema':
        return indianCinema;
      case 'movie':
        return movie;
      case 'tv':
        return tv;
      case 'anime':
      default:
        return anime;
    }
  }

  static List<CineTheme> get all => [
        anime,
        kdrama,
        bollywood,
        indianCinema,
        movie,
        tv,
      ];
}
