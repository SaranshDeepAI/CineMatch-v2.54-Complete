import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_theme_advanced.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final AuthController _auth = Get.find<AuthController>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final ThemeController _theme = Get.find<ThemeController>();

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  final Set<String> _selectedTypes = {};
  final Set<String> _selectedGenres = {};

  final List<Map<String, String>> _contentTypes = [
    {'id': 'anime', 'label': 'Anime', 'emoji': '⛩️'},
    {'id': 'kdrama', 'label': 'K-Drama', 'emoji': '🎭'},
    {'id': 'bollywood', 'label': 'Bollywood', 'emoji': '💃'},
    {'id': 'indian_cinema', 'label': 'Indian Cinema', 'emoji': '🎞️'},
    {'id': 'movie', 'label': 'Hollywood', 'emoji': '🎥'},
    {'id': 'tv', 'label': 'TV Shows', 'emoji': '📺'},
  ];

  final List<Map<String, String>> _genres = [
    {'id': 'action', 'label': 'Action', 'emoji': '💥'},
    {'id': 'romance', 'label': 'Romance', 'emoji': '❤️'},
    {'id': 'thriller', 'label': 'Thriller', 'emoji': '😱'},
    {'id': 'comedy', 'label': 'Comedy', 'emoji': '😂'},
    {'id': 'horror', 'label': 'Horror', 'emoji': '👻'},
    {'id': 'drama', 'label': 'Drama', 'emoji': '🎭'},
    {'id': 'scifi', 'label': 'Sci-Fi', 'emoji': '🚀'},
    {'id': 'fantasy', 'label': 'Fantasy', 'emoji': '🧙'},
    {'id': 'mystery', 'label': 'Mystery', 'emoji': '🔍'},
    {'id': 'adventure', 'label': 'Adventure', 'emoji': '🗺️'},
    {'id': 'animation', 'label': 'Animation', 'emoji': '🎨'},
    {'id': 'crime', 'label': 'Crime', 'emoji': '🕵️'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);
    try {
      final uid = _auth.userId;

      await _firestore.savePreferences(
        uid: uid,
        favoriteGenres: _selectedGenres.toList(),
        favoriteTypes: _selectedTypes.toList(),
      );
      await _firestore.markOnboardingDone(uid);

      /// Apply theme based on top content type BEFORE navigating
      await _theme.setThemeFromPreferences(_selectedTypes.toList());

      if (_auth.userModel.value != null) {
        _auth.userModel.value =
            _auth.userModel.value!.copyWith(onboardingDone: true);
      }

      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save preferences. Please try again.',
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Preview theme live as user selects content types
  void _onContentTypeTap(String id) {
    setState(() {
      if (_selectedTypes.contains(id)) {
        _selectedTypes.remove(id);
      } else {
        _selectedTypes.add(id);
      }
    });

    /// Live preview — apply theme of most recently tapped type
    if (_selectedTypes.isNotEmpty) {
      _theme.setTheme(_selectedTypes.last);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// Re-read theme so UI updates when theme changes during onboarding
      final t = _theme.currentTheme.value;
      return Scaffold(
        backgroundColor: t.background,
        body: Stack(
          children: [
            _buildBackground(t),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      _buildTopBar(t),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (i) =>
                              setState(() => _currentPage = i),
                          children: [
                            _buildWelcomePage(t),
                            _buildContentTypePage(t),
                            _buildGenrePage(t),
                          ],
                        ),
                      ),
                      _buildBottomBar(t),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBackground(CineTheme t) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  t.secondary.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  t.primary.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(CineTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(3, (i) {
              final isActive = i == _currentPage;
              final isDone = i < _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: isActive || isDone ? t.primaryGradient : null,
                  color: isActive || isDone ? null : t.cardBgLight,
                ),
              );
            }),
          ),
          if (_currentPage < 2)
            TextButton(
              onPressed: () => Get.offAllNamed('/home'),
              child: Text(
                'Skip',
                style: GoogleFonts.rajdhani(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(CineTheme t) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: t.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: t.primary.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.movie_filter_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) => t.primaryGradient.createShader(bounds),
            child: Text(
              'Welcome to\nCineMatch!',
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s personalize your experience.\nTell us what you love to watch!',
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _buildFeatureRow(t, '🤖', 'AI-powered recommendations'),
          const SizedBox(height: 12),
          _buildFeatureRow(t, '🎌', 'Anime, K-Drama, Bollywood & more'),
          const SizedBox(height: 12),
          _buildFeatureRow(t, '⭐', 'Rate and build your watchlist'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(CineTheme t, String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.cardBgLight),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypePage(CineTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you\nlike to watch?',
            style: GoogleFonts.rajdhani(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply — theme previews live! ✨',
            style: GoogleFonts.rajdhani(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: _contentTypes.length,
              itemBuilder: (context, index) {
                final item = _contentTypes[index];
                final isSelected = _selectedTypes.contains(item['id']);
                return GestureDetector(
                  onTap: () => _onContentTypeTap(item['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: isSelected ? t.primaryGradient : null,
                      color: isSelected ? null : t.cardBg,
                      border: Border.all(
                        color: isSelected ? Colors.transparent : t.cardBgLight,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: t.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['emoji']!,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item['label']!,
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenrePage(CineTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your favourite\ngenres?',
            style: GoogleFonts.rajdhani(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick at least 3 for better recommendations',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _genres.map((genre) {
                  final isSelected = _selectedGenres.contains(genre['id']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedGenres.remove(genre['id']);
                        } else {
                          _selectedGenres.add(genre['id']!);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: isSelected ? t.primaryGradient : null,
                        color: isSelected ? null : t.cardBg,
                        border: Border.all(
                          color:
                              isSelected ? Colors.transparent : t.cardBgLight,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: t.primary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            genre['emoji']!,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            genre['label']!,
                            style: GoogleFonts.rajdhani(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${_selectedGenres.length} selected',
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                color: _selectedGenres.length >= 3
                    ? AppColors.success
                    : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CineTheme t) {
    final isLastPage = _currentPage == 2;
    final canProceed = _currentPage == 0 ||
        (_currentPage == 1 && _selectedTypes.isNotEmpty) ||
        (_currentPage == 2 && _selectedGenres.length >= 3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _prevPage,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: t.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.cardBgLight),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: canProceed
                  ? (isLastPage ? _saveAndContinue : _nextPage)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: canProceed ? t.primaryGradient : null,
                  color: canProceed ? null : t.cardBgLight,
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isLastPage ? 'GET STARTED 🚀' : 'NEXT →',
                          style: GoogleFonts.rajdhani(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color:
                                canProceed ? Colors.white : AppColors.textMuted,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
