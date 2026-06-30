import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_theme_advanced.dart';
import '../../core/utils/app_utils.dart';
import '../../models/rating_model.dart';
import '../../widgets/themed_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthController _auth = Get.find<AuthController>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final ThemeController _theme = Get.find<ThemeController>();
  late TabController _tabController;

  List<RatingModel> _ratings = [];
  List<Map<String, dynamic>> _watchlist = [];
  List<Map<String, dynamic>> _searchHistory = [];
  bool _isLoading = true;

  int _totalRatings = 0;
  int _totalWatchlist = 0;
  int _totalSearches = 0;
  double _avgRating = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final uid = _auth.userId;
    final results = await Future.wait([
      _firestore.getUserRatings(uid),
      _firestore.getSearchHistory(uid),
    ]);

    final ratings = results[0] as List<RatingModel>;
    final history = results[1] as List<Map<String, dynamic>>;
    final watchSnap = await _firestore.watchlistStream(uid).first;

    if (!mounted) return;
    setState(() {
      _ratings = ratings;
      _searchHistory = history;
      _watchlist = watchSnap;
      _totalRatings = ratings.length;
      _totalWatchlist = watchSnap.length;
      _totalSearches = history.length;
      _avgRating = ratings.isEmpty
          ? 0.0
          : ratings.map((r) => r.stars).reduce((a, b) => a + b) /
              ratings.length;
      _isLoading = false;
    });
  }

  // --------------------------------------------------
  // EDIT PREFERENCES BOTTOM SHEET
  // --------------------------------------------------

  /// WHY a bottom sheet instead of a new screen?
  /// Bottom sheets are great for focused tasks that don't need
  /// a full navigation push. User can see context behind it
  /// and it feels lighter than a full page transition. 😊
  Future<void> _showEditPreferences() async {
    // Load current preferences first to pre-select them
    final prefs = await _firestore.getPreferences(_auth.userId);
    final currentTypes = List<String>.from(prefs['favoriteTypes'] ?? []);
    final currentGenres = List<String>.from(prefs['favoriteGenres'] ?? []);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditPreferencesSheet(
        currentTypes: currentTypes,
        currentGenres: currentGenres,
        onSave: (types, genres) async {
          await _firestore.savePreferences(
            uid: _auth.userId,
            favoriteTypes: types,
            favoriteGenres: genres,
          );
          // Update theme to reflect new top preference
          await _theme.setThemeFromPreferences(types);
          Get.snackbar(
            '✅ Preferences Updated',
            'Your taste profile has been saved!',
            backgroundColor: AppColors.success.withValues(alpha: 0.9),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScreen(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primary,
                    backgroundColor: AppColors.cardBg,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildProfileHeader()),
                        SliverToBoxAdapter(child: _buildStatsRow()),
                        SliverToBoxAdapter(child: _buildEditPrefsButton()),
                        SliverToBoxAdapter(child: _buildTabBar()),
                        SliverToBoxAdapter(child: _buildTabContent()),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // PROFILE HEADER
  // --------------------------------------------------

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.cardBg, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.cardBgLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardBg,
              ),
              child: Center(
                child: Obx(() => Text(
                      _auth.userName.isNotEmpty
                          ? _auth.userName[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.rajdhani(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    )),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      _auth.userName,
                      style: GoogleFonts.rajdhani(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    )),
                const SizedBox(height: 2),
                Obx(() => Text(
                      _auth.firebaseUser.value?.email ?? '',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    )),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.movie_filter_rounded,
                          size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'CineMatch Member',
                        style: GoogleFonts.rajdhani(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _IconAction(
                icon: Icons.refresh_rounded,
                color: AppColors.accentBlue,
                onTap: _loadData,
              ),
              const SizedBox(height: 8),
              _IconAction(
                icon: Icons.logout_rounded,
                color: AppColors.error,
                onTap: _showLogoutDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // STATS ROW
  // --------------------------------------------------

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatCard(
            value: _totalSearches.toString(),
            label: 'Searches',
            icon: Icons.search_rounded,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: _totalRatings.toString(),
            label: 'Rated',
            icon: Icons.star_rounded,
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: _totalWatchlist.toString(),
            label: 'Watchlist',
            icon: Icons.bookmark_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '-',
            label: 'Avg Rating',
            icon: Icons.auto_awesome_rounded,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // EDIT PREFERENCES BUTTON
  // --------------------------------------------------

  Widget _buildEditPrefsButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: _showEditPreferences,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Preferences',
                      style: GoogleFonts.rajdhani(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Update your content types & favourite genres',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // TAB BAR
  // --------------------------------------------------

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: AppColors.primaryGradient,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.rajdhani(
              fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          unselectedLabelStyle:
              GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w500),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textMuted,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_rounded, size: 14),
                  SizedBox(width: 6),
                  Text('Watchlist'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, size: 14),
                  SizedBox(width: 6),
                  Text('Ratings'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 14),
                  SizedBox(width: 6),
                  Text('History'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // TAB CONTENT
  // --------------------------------------------------

  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: [
          _buildWatchlistTab(),
          _buildRatingsTab(),
          _buildHistoryTab(),
        ][_tabController.index],
      ),
    );
  }

  // --------------------------------------------------
  // WATCHLIST TAB
  // --------------------------------------------------

  Widget _buildWatchlistTab() {
    if (_watchlist.isEmpty) {
      return _buildEmptyState(
        emoji: '🎬',
        title: 'Your watchlist is empty',
        subtitle: 'Save titles from recommendations to watch later',
      );
    }
    return Column(
      children: _watchlist.map((item) {
        final watched = item['watched'] as bool? ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: watched
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.cardBgLight,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await _firestore.toggleWatched(
                    uid: _auth.userId,
                    title: item['title'],
                    watched: !watched,
                  );
                  _loadData();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: watched
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.cardBgLight,
                    border: Border.all(
                      color: watched ? AppColors.success : AppColors.textMuted,
                    ),
                  ),
                  child: watched
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.success)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppUtils.toTitleCase(item['title'] ?? ''),
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: watched
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration: watched ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      item['contentType'] ?? '',
                      style: GoogleFonts.rajdhani(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (watched)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Watched ✓',
                    style: GoogleFonts.rajdhani(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  await _firestore.removeFromWatchlist(
                    uid: _auth.userId,
                    title: item['title'],
                  );
                  _loadData();
                },
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textMuted),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------
  // RATINGS TAB
  // --------------------------------------------------

  Widget _buildRatingsTab() {
    if (_ratings.isEmpty) {
      return _buildEmptyState(
        emoji: '⭐',
        title: 'No ratings yet',
        subtitle: 'Rate recommendations to see them here',
      );
    }
    return Column(
      children: _ratings.map((rating) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBgLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppUtils.toTitleCase(rating.recommendedTitle),
                          style: GoogleFonts.rajdhani(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        Text(
                          'Based on: ${AppUtils.toTitleCase(rating.queryTitle)}',
                          style: GoogleFonts.rajdhani(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < rating.stars.floor()
                            ? Icons.star_rounded
                            : i < rating.stars
                                ? Icons.star_half_rounded
                                : Icons.star_outline_rounded,
                        size: 16,
                        color: AppColors.accent,
                      );
                    }),
                  ),
                ],
              ),
              if (rating.review != null && rating.review!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '"${rating.review}"',
                    style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    AppUtils.formatDate(rating.timestamp),
                    style: GoogleFonts.rajdhani(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _voteColor(rating.vote).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rating.vote.toUpperCase(),
                      style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          color: _voteColor(rating.vote),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------
  // HISTORY TAB
  // --------------------------------------------------

  Widget _buildHistoryTab() {
    if (_searchHistory.isEmpty) {
      return _buildEmptyState(
        emoji: '🔍',
        title: 'No search history',
        subtitle: 'Your searches will appear here',
      );
    }
    return Column(
      children: _searchHistory.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBgLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.history_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppUtils.toTitleCase(item['query'] ?? ''),
                      style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      '${item['resultCount'] ?? 0} results • ${item['detectedType'] ?? ''}',
                      style: GoogleFonts.rajdhani(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.search_rounded,
                      size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------

  Widget _buildEmptyState({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style:
                GoogleFonts.rajdhani(fontSize: 13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👋', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              Text(
                'Leaving so soon?',
                style: GoogleFonts.rajdhani(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Your watchlist and ratings are safely saved.',
                style: GoogleFonts.rajdhani(
                    fontSize: 13, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.cardBgLight),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Stay',
                          style: GoogleFonts.rajdhani(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _auth.signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Logout',
                          style: GoogleFonts.rajdhani(
                              fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _voteColor(String vote) {
    switch (vote) {
      case 'up':
        return AppColors.success;
      case 'down':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }
}

// --------------------------------------------------
// EDIT PREFERENCES BOTTOM SHEET
// --------------------------------------------------

class _EditPreferencesSheet extends StatefulWidget {
  final List<String> currentTypes;
  final List<String> currentGenres;
  final Future<void> Function(List<String> types, List<String> genres) onSave;

  const _EditPreferencesSheet({
    required this.currentTypes,
    required this.currentGenres,
    required this.onSave,
  });

  @override
  State<_EditPreferencesSheet> createState() => _EditPreferencesSheetState();
}

class _EditPreferencesSheetState extends State<_EditPreferencesSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Set<String> _selectedTypes;
  late Set<String> _selectedGenres;
  bool _saving = false;

  final ThemeController _theme = Get.find<ThemeController>();

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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Pre-fill with current saved preferences ✅
    _selectedTypes = Set.from(widget.currentTypes);
    _selectedGenres = Set.from(widget.currentGenres);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(
      _selectedTypes.toList(),
      _selectedGenres.toList(),
    );
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    /// WHY DraggableScrollableSheet?
    /// Starts at 85% of screen height, user can drag it up to full screen
    /// if they need more space. Much better UX than a fixed-height sheet!
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Obx(() {
          final t = _theme.currentTheme.value;
          return Container(
            decoration: BoxDecoration(
              color: t.background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: t.cardBgLight),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '✨ Edit Preferences',
                        style: GoogleFonts.rajdhani(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Changes are saved to history — nothing is lost! 🎯',
                    style: GoogleFonts.rajdhani(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 16),
                // Tab bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: t.primaryGradient,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: GoogleFonts.rajdhani(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: GoogleFonts.rajdhani(fontSize: 13),
                      onTap: (_) => setState(() {}),
                      tabs: const [
                        Tab(text: '🎬 Content Types'),
                        Tab(text: '🎭 Genres'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTypesGrid(t, scrollController),
                      _buildGenresWrap(t, scrollController),
                    ],
                  ),
                ),
                // Save button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
                  child: GestureDetector(
                    onTap: _saving ? null : _save,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: _selectedTypes.isNotEmpty
                            ? t.primaryGradient
                            : null,
                        color: _selectedTypes.isEmpty
                            ? AppColors.cardBgLight
                            : null,
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _selectedTypes.isEmpty
                                    ? 'Select at least 1 type'
                                    : 'SAVE PREFERENCES ✅',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedTypes.isEmpty
                                      ? AppColors.textMuted
                                      : Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildTypesGrid(CineTheme t, ScrollController sc) {
    return GridView.builder(
      controller: sc,
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTypes.remove(item['id']);
              } else {
                _selectedTypes.add(item['id']!);
              }
            });
            // Live theme preview just like onboarding!
            if (_selectedTypes.isNotEmpty) {
              _theme.setTheme(_selectedTypes.last);
            }
          },
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
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['emoji']!, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  item['label']!,
                  style: GoogleFonts.rajdhani(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: Colors.white),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenresWrap(CineTheme t, ScrollController sc) {
    return SingleChildScrollView(
      controller: sc,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
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
                              blurRadius: 10,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(genre['emoji']!,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        genre['label']!,
                        style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '${_selectedGenres.length} selected',
            style: GoogleFonts.rajdhani(
              fontSize: 13,
              color: _selectedGenres.length >= 3
                  ? AppColors.success
                  : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// HELPER WIDGETS
// --------------------------------------------------

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBgLight),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.rajdhani(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
