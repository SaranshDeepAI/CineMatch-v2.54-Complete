import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Why AnimationController? → Controls the timing of animations.
  /// Like a stopwatch that drives how far along an animation is.
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSplashSequence();
  }

  void _setupAnimations() {
    /// Logo animates over 1.2 seconds
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    /// Text animates over 800ms
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    /// Glow pulses continuously
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    /// Why CurvedAnimation? → Makes animation feel natural instead of
    /// robotic linear movement. elasticOut = bouncy, easeIn = smooth
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    /// Slides text up from slightly below
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );
  }

  void _startSplashSequence() async {
    /// Wait a tiny bit before starting
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    /// Start text animation after logo is halfway done
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    /// Wait for everything to finish then navigate
    await Future.delayed(const Duration(milliseconds: 2000));
    _navigate();
  }

  Future<void> _navigate() async {
    final auth = Get.find<AuthController>();

    /// Why wait for stream? → On cold start Firebase auth state
    /// may not have fired yet. Instead of guessing with a timer,
    /// we wait for the FIRST real emission from the auth stream.
    /// This guarantees we never send a logged-in user to /auth!
    if (auth.firebaseUser.value == null) {
      /// Wait up to 3 seconds for auth state to resolve
      await auth.firebaseUser.stream
          .firstWhere(
            (user) => true,
            orElse: () => null,
          )
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );
    }

    if (auth.isLoggedIn) {
      Get.offAllNamed('/home');
    } else {
      Get.offAllNamed('/auth');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: Stack(
          children: [
            /// Background glow effect
            _buildBackgroundGlow(),

            /// Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 24),
                  _buildAppName(),
                  const SizedBox(height: 8),
                  _buildTagline(),
                  const SizedBox(height: 60),
                  _buildLoadingDots(),
                ],
              ),
            ),

            /// Bottom version text
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: _buildVersionText(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            /// Top-left purple glow
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary
                          .withValues(alpha: 0.15 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            /// Bottom-right red glow
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary
                          .withValues(alpha: 0.12 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.movie_filter_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppName() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _textOpacity,
          child: SlideTransition(
            position: _textSlide,
            child: ShaderMask(
              /// Why ShaderMask? → Applies our gradient directly to text
              /// giving it that premium anime poster look ✨
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: Text(
                AppConstants.appName,
                style: GoogleFonts.rajdhani(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _textOpacity,
          child: Text(
            AppConstants.appTagline,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: AppColors.textMuted,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            /// Why offset delays? → Each dot animates slightly after
            /// the previous one, creating a wave effect 🌊
            final delay = index * 0.3;
            final animValue =
                (_particleController.value - delay).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: animValue,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildVersionText() {
    return Text(
      'v1.0.0 • Powered by AI',
      textAlign: TextAlign.center,
      style: GoogleFonts.rajdhani(
        fontSize: 11,
        color: AppColors.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }
}
