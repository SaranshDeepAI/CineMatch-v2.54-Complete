import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/detail_model.dart';
import '../../models/recommendation_model.dart';
import '../../services/tmdb_service.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/recommendation_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/themed_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  /// WHY Get.arguments?
  /// We pass the RecommendationModel from the card tap via Get.toNamed.
  /// This avoids prop drilling and works cleanly with GetX routing.
  late final RecommendationModel item;
  late final String queryTitle;

  DetailModel? _detail;
  bool _loading = true;
  bool _error = false;

  final AuthController _auth = Get.find<AuthController>();
  final RecommendationController _rec = Get.find<RecommendationController>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    item = args['item'] as RecommendationModel;
    queryTitle = args['queryTitle'] as String? ?? '';
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final detail = await Get.find<TmdbService>().getDetails(
      title: item.title,
      contentType: item.type,
    );
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
        _error = detail == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_outlined,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Could not load details',
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _loadDetails,
            child: Text(
              'Retry',
              style: GoogleFonts.rajdhani(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Go Back',
              style: GoogleFonts.rajdhani(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _detail!;
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(d),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(d),
                    const SizedBox(height: 20),
                    _buildWatchButtons(d),
                    const SizedBox(height: 20),
                    _buildActionRow(d),
                    const SizedBox(height: 24),
                    if (d.overview.isNotEmpty) ...[
                      _buildSectionLabel('📖 Overview'),
                      const SizedBox(height: 8),
                      _buildOverview(d),
                      const SizedBox(height: 24),
                    ],
                    if (d.cast.isNotEmpty) ...[
                      _buildSectionLabel('🎭 Cast'),
                      const SizedBox(height: 10),
                      _buildCastRow(d),
                      const SizedBox(height: 24),
                    ],
                    if (d.trailerUrl != null) ...[
                      _buildSectionLabel('▶ Trailer'),
                      const SizedBox(height: 10),
                      _buildTrailerButton(d),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionLabel('⭐ Rate This'),
                    const SizedBox(height: 10),
                    _buildRatingSection(d),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SLIVER APP BAR with backdrop hero image
  // --------------------------------------------------

  Widget _buildSliverAppBar(DetailModel d) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop image
            d.backdropUrl != null
                ? CachedNetworkImage(
                    imageUrl: d.backdropUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: AppColors.cardBg),
                    errorWidget: (context, url, err) =>
                        Container(color: AppColors.cardBg),
                  )
                : d.posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: d.posterUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.cardBg),
                        errorWidget: (context, url, err) =>
                            Container(color: AppColors.cardBg),
                      )
                    : Container(
                        color: AppColors.cardBg,
                        child: Center(
                          child: Text(
                            AppConstants.contentTypeEmojis[item.type] ?? '🎬',
                            style: const TextStyle(fontSize: 64),
                          ),
                        ),
                      ),
            // Gradient overlay so title text is readable over image
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.background],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // TITLE SECTION — poster + title + meta
  // --------------------------------------------------

  Widget _buildTitleSection(DetailModel d) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Small poster card pulled up over the backdrop
        if (d.posterUrl != null)
          Container(
            width: 90,
            height: 130,
            margin: const EdgeInsets.only(top: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: d.posterUrl!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${AppConstants.contentTypeEmojis[item.type] ?? '🎬'} ${AppConstants.contentTypeLabels[item.type] ?? item.type}',
                  style: GoogleFonts.rajdhani(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Title
              Text(
                d.title,
                style: GoogleFonts.rajdhani(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              // Meta row — year, runtime/episodes, rating
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (d.releaseYear != 'N/A')
                    _MetaChip(d.releaseYear, Icons.calendar_today_outlined),
                  if (d.runtimeFormatted.isNotEmpty)
                    _MetaChip(d.runtimeFormatted, Icons.timer_outlined),
                  if (d.episodes != null)
                    _MetaChip('${d.episodes} eps', Icons.list_alt_outlined),
                  _MetaChip(
                    '${d.starRating.toStringAsFixed(1)} / 5',
                    Icons.star_rounded,
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Genres
              if (d.genres.isNotEmpty)
                Text(
                  d.genres.take(3).join(' • '),
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // WATCH BUTTONS — Netflix & Crunchyroll
  // --------------------------------------------------

  Widget _buildWatchButtons(DetailModel d) {
    final encodedTitle = Uri.encodeQueryComponent(d.title);

    final platforms = [
      {
        'label': 'Netflix',
        'logoUrl':
            'https://upload.wikimedia.org/wikipedia/commons/0/08/Netflix_2015_logo.svg',
        'isSvg': true,
        'color': const Color(0xFFE50914),
        'bgColor': const Color(0xFF1A0000),
        'url': 'https://www.netflix.com/search?q=$encodedTitle',
      },
      {
        'label': 'Crunchyroll',
        'logoUrl': 'https://www.crunchyroll.com/favicons/favicon-192x192.png',
        'isSvg': false,
        'color': const Color(0xFFF47521),
        'bgColor': const Color(0xFF1A0A00),
        'url': 'https://www.crunchyroll.com/search?q=$encodedTitle',
      },
      {
        'label': 'Disney+',
        'logoUrl':
            'https://upload.wikimedia.org/wikipedia/commons/3/3e/Disney%2B_logo.svg',
        'isSvg': true,
        'color': const Color(0xFF1139B8),
        'bgColor': const Color(0xFF00001A),
        'url': 'https://www.disneyplus.com/search/$encodedTitle',
      },
      {
        'label': 'Apple TV+',
        'logoUrl':
            'https://upload.wikimedia.org/wikipedia/commons/2/28/Apple_TV_Plus_Logo.svg',
        'isSvg': true,
        'color': const Color(0xFFFFFFFF),
        'bgColor': const Color(0xFF0A0A0A),
        'url': 'https://tv.apple.com/search?term=$encodedTitle',
      },
      {
        'label': 'Prime Video',
        'logoUrl':
            'https://upload.wikimedia.org/wikipedia/commons/1/11/Amazon_Prime_Video_logo.svg',
        'isSvg': true,
        'color': const Color(0xFF00A8E1),
        'bgColor': const Color(0xFF00101A),
        'url': 'https://www.primevideo.com/search/?phrase=$encodedTitle',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('📺 Where to Watch'),
        const SizedBox(height: 10),
        // First row — Netflix + Crunchyroll (wider, prominent)
        Row(
          children: [
            Expanded(
              child: _WatchButton(
                label: platforms[0]['label'] as String,
                logoUrl: platforms[0]['logoUrl'] as String,
                isSvg: platforms[0]['isSvg'] as bool,
                color: platforms[0]['color'] as Color,
                bgColor: platforms[0]['bgColor'] as Color,
                url: platforms[0]['url'] as String,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WatchButton(
                label: platforms[1]['label'] as String,
                logoUrl: platforms[1]['logoUrl'] as String,
                isSvg: platforms[1]['isSvg'] as bool,
                color: platforms[1]['color'] as Color,
                bgColor: platforms[1]['bgColor'] as Color,
                url: platforms[1]['url'] as String,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Second row — Disney+, Apple TV+, Prime Video
        Row(
          children: [
            for (int i = 2; i < platforms.length; i++) ...[
              Expanded(
                child: _WatchButton(
                  label: platforms[i]['label'] as String,
                  logoUrl: platforms[i]['logoUrl'] as String,
                  isSvg: platforms[i]['isSvg'] as bool,
                  color: platforms[i]['color'] as Color,
                  bgColor: platforms[i]['bgColor'] as Color,
                  url: platforms[i]['url'] as String,
                ),
              ),
              if (i < platforms.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
  // --------------------------------------------------
  // ACTION ROW — Watchlist + Find Similar
  // --------------------------------------------------

  Widget _buildActionRow(DetailModel d) {
    return Row(
      children: [
        Obx(() {
          final inList = _rec.inWatchlist(item.title);
          return Expanded(
            child: _ActionButton(
              icon: inList
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              label: inList ? 'Saved' : '+ Watchlist',
              color: inList ? AppColors.accent : AppColors.textMuted,
              onTap: () => _rec.toggleWatchlist(
                uid: _auth.userId,
                title: item.title,
                contentType: item.type,
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.search_rounded,
            label: 'Find Similar',
            color: AppColors.accentBlue,
            onTap: () {
              Get.back();
              Get.back(); // back to recommendations
              // small delay so navigation settles
              Future.delayed(const Duration(milliseconds: 300), () {
                final search = Get.find();
                search.getRecommendations(
                  title: item.title,
                  userId: _auth.userId,
                );
              });
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // OVERVIEW
  // --------------------------------------------------

  Widget _buildOverview(DetailModel d) {
    return Text(
      d.overview,
      style: GoogleFonts.rajdhani(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.6,
      ),
    );
  }

  // --------------------------------------------------
  // CAST ROW
  // --------------------------------------------------

  Widget _buildCastRow(DetailModel d) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: d.cast.length,
        itemBuilder: (context, i) {
          final member = d.cast[i];
          return Container(
            width: 68,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: member.profileUrl != null
                        ? CachedNetworkImage(
                            imageUrl: member.profileUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.cardBg,
                            ),
                            errorWidget: (context, url, err) => _castFallback(),
                          )
                        : _castFallback(),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  member.name,
                  style: GoogleFonts.rajdhani(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _castFallback() {
    return Container(
      color: AppColors.cardBg,
      child: const Icon(Icons.person, color: AppColors.textMuted, size: 28),
    );
  }

  // --------------------------------------------------
  // TRAILER BUTTON
  // --------------------------------------------------

  Widget _buildTrailerButton(DetailModel d) {
    return GestureDetector(
      onTap: () => _launchUrl(d.trailerUrl!),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline_rounded,
                color: Colors.red, size: 22),
            const SizedBox(width: 10),
            Text(
              'Watch Trailer on YouTube',
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.red,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // RATING SECTION
  // --------------------------------------------------

  Widget _buildRatingSection(DetailModel d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBgLight),
      ),
      child: Obx(() {
        final isRated = _rec.isRated(item.title);
        final myRating = _rec.getRating(item.title);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRated ? '⭐ Your Rating' : 'Rate this title',
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            RatingBar.builder(
              initialRating: myRating,
              minRating: 1,
              itemCount: 5,
              itemSize: 32,
              allowHalfRating: true,
              unratedColor: AppColors.cardBgLight,
              itemBuilder: (context, _) => const Icon(
                Icons.star_rounded,
                color: AppColors.accent,
              ),
              onRatingUpdate: (stars) => _showRatingDialog(stars),
            ),
            if (isRated) ...[
              const SizedBox(height: 6),
              Text(
                '${myRating.toStringAsFixed(1)} / 5.0 stars',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  void _showRatingDialog(double stars) {
    final reviewController = TextEditingController();
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate "${item.title}"',
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${stars.toStringAsFixed(1)} / 5.0 stars',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary, fontSize: 14),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a review (optional)...',
                  hintStyle: GoogleFonts.rajdhani(
                      color: AppColors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
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
                      child: Text('Cancel',
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
                        _rec.submitRating(
                          uid: _auth.userId,
                          queryTitle: queryTitle,
                          recommendation: item,
                          stars: stars,
                          review: reviewController.text.isEmpty
                              ? null
                              : reviewController.text,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: Text('Submit',
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

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.rajdhani(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Could not open link',
        'Please try manually searching on the platform.',
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

// --------------------------------------------------
// WATCH BUTTON WIDGET — Netflix / Crunchyroll
// --------------------------------------------------

class _WatchButton extends StatelessWidget {
  final String label;
  final String logoUrl;
  final bool isSvg;
  final Color color;
  final Color bgColor;
  final String url;

  const _WatchButton({
    required this.label,
    required this.logoUrl,
    required this.isSvg,
    required this.color,
    required this.bgColor,
    required this.url,
  });

  Future<void> _open() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo — SVG or PNG depending on source
            SizedBox(
              height: 28,
              child: isSvg
                  ? SvgPicture.network(
                      logoUrl,
                      height: 28,
                      // WHY colorFilter only for Apple TV+?
                      // Apple TV+ logo is black — invisible on dark bg.
                      // Netflix/Disney+/Prime are already colored so
                      // we don't tint them, just show as-is.
                      colorFilter: label == 'Apple TV+'
                          ? const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            )
                          : null,
                      placeholderBuilder: (context) => _logoFallback(),
                    )
                  : CachedNetworkImage(
                      imageUrl: logoUrl,
                      height: 28,
                      placeholder: (context, url) => _logoFallback(),
                      errorWidget: (context, url, err) => _logoFallback(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Shown while logo loads or if network fails
  Widget _logoFallback() {
    return Text(
      label,
      style: GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// --------------------------------------------------
// META CHIP — small pill for year/runtime/rating
// --------------------------------------------------

class _MetaChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;

  const _MetaChip(this.text, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.rajdhani(
            fontSize: 11,
            color: c,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------
// ACTION BUTTON — Watchlist / Find Similar
// --------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
