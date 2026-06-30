import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/movie_search_controller.dart';
import 'controllers/recommendation_controller.dart';
import 'controllers/theme_controller.dart';
import 'services/api_service.dart';
import 'services/tmdb_service.dart';
import 'services/firestore_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/recommendations/recommendations_screen.dart';
import 'screens/detail/detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// Register ThemeController BEFORE runApp so theme: param can find it
  Get.put(ThemeController(), permanent: true);
  runApp(const CineMatchApp());
}

class CineMatchApp extends StatelessWidget {
  const CineMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    /// Why Obx wrapping GetMaterialApp? → watches currentTheme observable.
    /// When user changes theme, entire app rebuilds with new ThemeData!
    return Obx(() {
      final themeController = Get.find<ThemeController>();
      themeController.currentTheme.value;

      return GetMaterialApp(
        title: 'CineMatch',
        debugShowCheckedModeBanner: false,
        theme: themeController.buildThemeData(),
        initialBinding: BindingsBuilder(() {
          Get.put(ApiService(), permanent: true);
          Get.put(TmdbService(), permanent: true);
          Get.put(FirestoreService(), permanent: true);
          Get.put(AuthController(), permanent: true);
        }),
        initialRoute: '/splash',
        getPages: [
          GetPage(name: '/splash', page: () => const SplashScreen()),
          GetPage(name: '/auth', page: () => const AuthScreen()),
          GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
          GetPage(
            name: '/home',
            page: () => const HomeScreen(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => MovieSearchController());
            }),
          ),
          GetPage(name: '/search', page: () => const SearchScreen()),
          GetPage(
            name: '/recommendations',
            page: () => const RecommendationsScreen(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => RecommendationController(), fenix: true);
            }),
          ),

          /// WHY fenix: true on detail?
          /// Detail screen can be opened multiple times (one per title).
          /// fenix: true lets GetX recreate the controller each time
          /// instead of reusing a stale one from a previous title. ✅
          GetPage(
            name: '/detail',
            page: () => const DetailScreen(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => RecommendationController(), fenix: true);
            }),
          ),

          GetPage(name: '/profile', page: () => const ProfileScreen()),
        ],
      );
    });
  }
}

//flutter run -d chrome --web-port 5000
