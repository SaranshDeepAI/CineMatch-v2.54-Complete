import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme_advanced.dart';

class ThemeController extends GetxController {
  /// WHY Rx?
  /// When currentTheme.value changes, the Obx() in main.dart
  /// automatically rebuilds GetMaterialApp with the new ThemeData.
  /// No manual rebuild needed!
  final Rx<CineTheme> currentTheme = AppThemes.anime.obs;

  static const String _prefKey = 'selected_theme';

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
  }

  /// Load theme from SharedPreferences on app start
  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      currentTheme.value = AppThemes.fromContentType(saved);
    }
  }

  /// Called after onboarding — sets theme based on top content type
  Future<void> setThemeFromPreferences(List<String> favoriteTypes) async {
    if (favoriteTypes.isEmpty) return;

    /// Why first? → user's top pick determines the theme
    final topType = favoriteTypes.first;
    await setTheme(topType);
  }

  Future<void> setTheme(String contentTypeId) async {
    currentTheme.value = AppThemes.fromContentType(contentTypeId);

    /// Persist so theme survives app restart
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, contentTypeId);

    /// WHY removed Get.forceAppUpdate()?
    /// The Obx() wrapping GetMaterialApp in main.dart already watches
    /// currentTheme.value and rebuilds automatically when it changes.
    /// Calling Get.forceAppUpdate() on top of that caused a DOUBLE
    /// rebuild — the whole widget tree was recreated twice on every
    /// theme change, causing jank and wasted frames.
    /// Removing it = smooth single rebuild. ✅
  }

  /// Convenience getters used across the app
  Color get primary => currentTheme.value.primary;
  Color get secondary => currentTheme.value.secondary;
  Color get accent => currentTheme.value.accent;
  Color get background => currentTheme.value.background;
  Color get surface => currentTheme.value.surface;
  Color get cardBg => currentTheme.value.cardBg;
  Color get cardBgLight => currentTheme.value.cardBgLight;
  LinearGradient get primaryGradient => currentTheme.value.primaryGradient;
  LinearGradient get splashGradient => currentTheme.value.splashGradient;
  LinearGradient get cardGradient => currentTheme.value.cardGradient;
  String get themeName => currentTheme.value.name;
  String get themeEmoji => currentTheme.value.emoji;

  ThemeData buildThemeData() {
    final t = currentTheme.value;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: t.background,
      colorScheme: ColorScheme.dark(
        primary: t.primary,
        secondary: t.secondary,
        surface: t.surface,
        error: const Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSurface: const Color(0xFFF0F0F0),
      ),
      textTheme: t.textTheme.apply(
        bodyColor: const Color(0xFFF0F0F0),
        displayColor: const Color(0xFFF0F0F0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFF0F0F0)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: t.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.surface,
        selectedItemColor: t.primary,
        unselectedItemColor: const Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
