import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/movie_search_controller.dart';
import '../../services/tmdb_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../search/search_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/themed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  /// WHY const list here?
  /// These widgets are created once. With IndexedStack below they
  /// stay alive in memory forever — no rebuilds on tab switch!
  final List<Widget> _screens = const [
    _HomeTab(),
    SearchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ThemedScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,

        /// WHY IndexedStack instead of _screens[_currentIndex]?
        ///
        /// OLD: body: _screens[_currentIndex]
        /// → Flutter destroys and recreates the widget every tab switch.
        ///   Switching Home→Search→Home re-creates _HomeTab and fires
        ///   all 36 poster fetches again. Sluggish!
        ///
        /// NEW: IndexedStack keeps ALL tabs alive in memory.
        ///   Switching tabs just changes visibility, like browser tabs.
        ///   _HomeTab is built ONCE, posters fetched ONCE. ✅
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.cardBgLight.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.rajdhani(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.rajdhani(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// HOME TAB
// --------------------------------------------------

class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final AuthController _auth = Get.find<AuthController>();
  final MovieSearchController _search = Get.find<MovieSearchController>();

  /// 6 items in every row for visual consistency
  final List<Map<String, String>> _featuredItems = [
    {'title': 'demon slayer', 'type': 'anime', 'display': 'Demon Slayer'},
    {'title': 'jujutsu kaisen', 'type': 'anime', 'display': 'Jujutsu Kaisen'},
    {'title': 'squid game', 'type': 'kdrama', 'display': 'Squid Game'},
    {'title': 'interstellar', 'type': 'movie', 'display': 'Interstellar'},
    {'title': 'solo leveling', 'type': 'anime', 'display': 'Solo Leveling'},
    {'title': 'the dark knight', 'type': 'movie', 'display': 'The Dark Knight'},
  ];

  final Map<String, List<Map<String, String>>> _sectionItems = {
    'anime': [
      {'title': 'demon slayer', 'type': 'anime', 'display': 'Demon Slayer'},
      {'title': 'jujutsu kaisen', 'type': 'anime', 'display': 'Jujutsu Kaisen'},
      {'title': 'solo leveling', 'type': 'anime', 'display': 'Solo Leveling'},
      {
        'title': 'attack on titan',
        'type': 'anime',
        'display': 'Attack on Titan'
      },
      {'title': 'dragon ball z', 'type': 'anime', 'display': 'Dragon Ball Z'},
      {
        'title': 'my hero academia',
        'type': 'anime',
        'display': 'My Hero Academia'
      },
    ],
    'kdrama': [
      {'title': 'squid game', 'type': 'kdrama', 'display': 'Squid Game'},
      {
        'title': 'crash landing on you',
        'type': 'kdrama',
        'display': 'Crash Landing on You'
      },
      {
        'title': 'business proposal',
        'type': 'kdrama',
        'display': 'Business Proposal'
      },
      {'title': 'goblin', 'type': 'kdrama', 'display': 'Goblin'},
      {'title': 'itaewon class', 'type': 'kdrama', 'display': 'Itaewon Class'},
      {
        'title': 'my love from the star',
        'type': 'kdrama',
        'display': 'My Love From The Star'
      },
    ],
    'bollywood': [
      {'title': 'jawan', 'type': 'bollywood', 'display': 'Jawan'},
      {'title': '3 idiots', 'type': 'bollywood', 'display': '3 Idiots'},
      {'title': 'dunki', 'type': 'bollywood', 'display': 'Dunki'},
      {'title': 'dangal', 'type': 'bollywood', 'display': 'Dangal'},
      {'title': 'kabir singh', 'type': 'bollywood', 'display': 'Kabir Singh'},
      {'title': 'animal', 'type': 'bollywood', 'display': 'Animal'},
    ],
    'indian_cinema': [
      {'title': 'rrr', 'type': 'indian_cinema', 'display': 'RRR'},
      {
        'title': 'pushpa the rise',
        'type': 'indian_cinema',
        'display': 'Pushpa: The Rise'
      },
      {
        'title': 'k g f chapter 2',
        'type': 'indian_cinema',
        'display': 'KGF Chapter 2'
      },
      {'title': 'vikram', 'type': 'indian_cinema', 'display': 'Vikram'},
      {'title': 'jailer', 'type': 'indian_cinema', 'display': 'Jailer'},
      {'title': 'leo', 'type': 'indian_cinema', 'display': 'Leo'},
    ],
    'movie': [
      {'title': 'interstellar', 'type': 'movie', 'display': 'Interstellar'},
      {
        'title': 'the dark knight',
        'type': 'movie',
        'display': 'The Dark Knight'
      },
      {'title': 'inception', 'type': 'movie', 'display': 'Inception'},
      {
        'title': 'avengers endgame',
        'type': 'movie',
        'display': 'Avengers: Endgame'
      },
      {'title': 'oppenheimer', 'type': 'movie', 'display': 'Oppenheimer'},
      {
        'title': 'spider man no way home',
        'type': 'movie',
        'display': 'Spider-Man: No Way Home'
      },
    ],
  };

  /// WHY initState here?
  /// We prefetch ALL poster URLs before the cards are built.
  /// By the time ListView renders the cards, the TmdbService cache
  /// is already warm — cards get instant hits instead of showing
  /// loading spinners and firing individual network calls.
  @override
  void initState() {
    super.initState();
    _warmUpPosters();
  }

  Future<void> _warmUpPosters() async {
    final allTitles = [
      ..._featuredItems.map((e) => e['title']!),
      ..._sectionItems.values.expand((list) => list.map((e) => e['title']!)),
    ];
    await Get.find<TmdbService>().prefetchPosters(allTitles);

    /// Trigger rebuild so cards immediately re-check the now-warm cache
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildTypeFilter()),
              SliverToBoxAdapter(child: _buildFeaturedBanner()),
              SliverToBoxAdapter(
                  child: _buildSectionTitle('⛩️ Anime Spotlight')),
              SliverToBoxAdapter(
                  child: _buildPosterRow(_sectionItems['anime']!)),
              SliverToBoxAdapter(child: _buildSectionTitle('🎭 K-Drama Picks')),
              SliverToBoxAdapter(
                  child: _buildPosterRow(_sectionItems['kdrama']!)),
              SliverToBoxAdapter(
                  child: _buildSectionTitle('💃 Bollywood Hits')),
              SliverToBoxAdapter(
                  child: _buildPosterRow(_sectionItems['bollywood']!)),
              SliverToBoxAdapter(
                  child: _buildSectionTitle('🎞️ Indian Cinema')),
              SliverToBoxAdapter(
                  child: _buildPosterRow(_sectionItems['indian_cinema']!)),
              SliverToBoxAdapter(child: _buildSectionTitle('🎥 Top Movies')),
              SliverToBoxAdapter(
                  child: _buildPosterRow(_sectionItems['movie']!)),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppUtils.getGreeting(),
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              Obx(() => Text(
                    _auth.userName,
                    style: GoogleFonts.rajdhani(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  )),
            ],
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.movie_filter_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: GestureDetector(
        onTap: () {
          final homeState = context.findAncestorStateOfType<_HomeScreenState>();
          homeState?.setState(() => homeState._currentIndex = 1);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBgLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Text(
                'Search movies, anime, dramas...',
                style: GoogleFonts.rajdhani(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'AI',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    /// WHY read selectedType.value at the TOP of Obx?
    /// GetX scans the Obx builder synchronously on first run to find
    /// which observables to watch. ListView.builder is LAZY — it only
    /// calls itemBuilder for visible items, so GetX never sees the
    /// .value read inside itemBuilder during that first scan.
    /// Result: GetX thinks "nothing is being observed here" → red screen!
    ///
    /// Fix: read the observable once at the top of Obx (outside ListView).
    /// GetX sees it immediately, registers the subscription, and now
    /// rebuilds the whole filter row whenever selectedType changes. ✅
    return Obx(() {
      final selectedType =
          _search.selectedType.value; // 👈 this line is the fix

      return SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: AppConstants.contentTypes.length,
          itemBuilder: (context, index) {
            final type = AppConstants.contentTypes[index];
            final label = AppConstants.contentTypeLabels[type] ?? type;
            final emoji = AppConstants.contentTypeEmojis[type] ?? '🎬';
            final isSelected = selectedType == type; // 👈 use local variable
            return GestureDetector(
              onTap: () => _search.setContentType(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.cardBg,
                  border: Border.all(
                    color:
                        isSelected ? Colors.transparent : AppColors.cardBgLight,
                  ),
                ),
                child: Text(
                  '$emoji $label',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildFeaturedBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🔥 Trending Now'),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _featuredItems.length,
            itemBuilder: (context, index) => _DynamicPosterCard(
              item: _featuredItems[index],
              width: 150,
              height: 220,
              featured: true,
              onTap: () => _onTitleTap(
                _featuredItems[index]['title']!,
                _featuredItems[index]['type']!,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: GoogleFonts.rajdhani(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPosterRow(List<Map<String, String>> items) {
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) => _DynamicPosterCard(
          item: items[index],
          width: 115,
          height: 170,
          onTap: () => _onTitleTap(
            items[index]['title']!,
            items[index]['type']!,
          ),
        ),
      ),
    );
  }

  void _onTitleTap(String title, String type) {
    _search.setContentType(type);
    _search.getRecommendations(
      title: title,
      userId: _auth.userId,
    );
  }
}

// --------------------------------------------------
// DYNAMIC POSTER CARD — fetches poster from TMDB API
// --------------------------------------------------

class _DynamicPosterCard extends StatefulWidget {
  final Map<String, String> item;
  final double width;
  final double height;
  final bool featured;
  final VoidCallback onTap;

  const _DynamicPosterCard({
    required this.item,
    required this.width,
    required this.height,
    required this.onTap,
    this.featured = false,
  });

  @override
  State<_DynamicPosterCard> createState() => _DynamicPosterCardState();
}

class _DynamicPosterCardState extends State<_DynamicPosterCard> {
  String? _posterUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPoster();
  }

  Future<void> _fetchPoster() async {
    /// WHY is this fast now?
    /// _HomeTabState.initState() already called prefetchPosters() which
    /// warmed the TmdbService cache. So getPosterUrl() returns instantly
    /// from cache — no network call happens here at all. ✅
    final url =
        await Get.find<TmdbService>().getPosterUrl(widget.item['title']!);
    if (mounted) {
      setState(() {
        _posterUrl = url;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        margin: EdgeInsets.only(right: widget.featured ? 12 : 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.featured ? 14 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.featured ? 14 : 12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _loading
                  ? Container(
                      color: AppColors.cardBg,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : _posterUrl != null
                      ? CachedNetworkImage(
                          imageUrl: _posterUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: AppColors.cardBg),
                          errorWidget: (context, url, error) => _fallback(),
                        )
                      : _fallback(),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(widget.featured ? 10 : 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item['display']!,
                        style: GoogleFonts.rajdhani(
                          fontSize: widget.featured ? 13 : 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: widget.featured ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.featured)
                        Text(
                          AppConstants.contentTypeLabels[widget.item['type']] ??
                              widget.item['type']!,
                          style: GoogleFonts.rajdhani(
                            fontSize: 10,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (widget.featured)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.85),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.cardBg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppConstants.contentTypeEmojis[widget.item['type']] ?? '🎬',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                widget.item['display']!,
                style: GoogleFonts.rajdhani(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
