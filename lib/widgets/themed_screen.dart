import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

/// Why ThemedScreen? → Single wrapper that makes ANY screen
/// react to theme changes automatically. Wrap once, works forever!
class ThemedScreen extends StatelessWidget {
  final Widget child;

  const ThemedScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// Reading currentTheme triggers rebuild on theme change
      final t = Get.find<ThemeController>().currentTheme.value;
      return AnimatedContainer(
        /// Why AnimatedContainer? → smooth color transition
        /// when theme changes instead of instant jarring switch!
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        color: t.background,
        child: child,
      );
    });
  }
}
