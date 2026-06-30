import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/movie_search_controller.dart';
import '../../controllers/recommendation_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/recommendation_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/tmdb_service.dart';
import '../../widgets/themed_screen.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MovieSearchController search = Get.find<MovieSearchController>();
    final RecommendationController rec = Get.find<RecommendationController>();
    final AuthController auth = Get.find<AuthController>();

    return ThemedScreen(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(search),
        body: Obx(() {
          final response = search.recommendations.value;
          if (response == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  _buildQueryInfo(response),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: response.results.length,
                      itemBuilder: (context, index) {
                        final item = response.results[index];
                        return _RecommendationCard(
                          item: item,
                          queryTitle: response.query,
                          auth: auth,
                          rec: rec,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        bottomSheet: Obx(() {
          if (rec.statusMessage.value.isEmpty) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            color: AppColors.surface,
            child: Text(
              rec.statusMessage.value,
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(MovieSearchController search) {
    return AppBar(
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary, size: 18),
        onPressed: () => Get.back(),
      ),
      title: Obx(() => Column(
            children: [
              Text(
                'Recommendations',
                style: GoogleFonts.rajdhani(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                search.recommendations.value?.query ?? '',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          )),
    );
  }

  Widget _buildQueryInfo(RecommendationResponse response) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBgLight),
      ),
      child: Row(
        children: [
          Text(
            AppConstants.contentTypeEmojis[response.detectedType] ?? '🎬',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Because you searched "${response.query}"',
                  style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${response.count} recommendations • ${AppConstants.contentTypeLabels[response.detectedType] ?? response.detectedType}',
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (response.fallbackLevel > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Extended',
                style: GoogleFonts.rajdhani(
                  fontSize: 10,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// RECOMMENDATION CARD
// --------------------------------------------------

class _RecommendationCard extends StatefulWidget {
  final RecommendationModel item;
  final String queryTitle;
  final AuthController auth;
  final RecommendationController rec;

  const _RecommendationCard({
    required this.item,
    required this.queryTitle,
    required this.auth,
    required this.rec,
  });

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _expanded = false;
  String? _posterUrl;
  bool _posterLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPoster();
  }

  Future<void> _fetchPoster() async {
    final url = await Get.find<TmdbService>().getPosterUrl(widget.item.title);
    if (mounted) {
      setState(() {
        _posterUrl = url;
        _posterLoading = false;
      });
    }
  }

  /// WHY a separate onTap for the poster vs the card?
  /// Tapping the POSTER → opens detail screen (immersive view)
  /// Tapping the card ROW → expands inline rating/watchlist actions
  /// This gives users two natural interaction patterns. 😊
  void _openDetail() {
    Get.toNamed(
      '/detail',
      arguments: {
        'item': widget.item,
        'queryTitle': widget.queryTitle,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBgLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCardHeader(),
          if (_expanded) _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    final emoji = AppConstants.contentTypeEmojis[widget.item.type] ?? '🎬';
    final typeLabel =
        AppConstants.contentTypeLabels[widget.item.type] ?? widget.item.type;

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            /// Poster thumbnail — tap opens detail screen
            GestureDetector(
              onTap: _openDetail,
              child: _buildPosterThumb(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: widget.item.rank <= 3
                              ? AppColors.primaryGradient
                              : null,
                          color: widget.item.rank > 3
                              ? AppColors.cardBgLight
                              : null,
                        ),
                        child: Text(
                          '#${widget.item.rank}',
                          style: GoogleFonts.rajdhani(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: widget.item.rank <= 3
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _openDetail,
                          child: Text(
                            widget.item.title,
                            style: GoogleFonts.rajdhani(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  AppColors.primary.withValues(alpha: 0.4),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: GoogleFonts.rajdhani(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (widget.item.genreOverlap > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${widget.item.genreOverlap} genres',
                            style: GoogleFonts.rajdhani(
                              fontSize: 10,
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Hint text so users know they can tap for details
                  const SizedBox(height: 4),
                  Text(
                    'Tap title or poster for details',
                    style: GoogleFonts.rajdhani(
                      fontSize: 10,
                      color: AppColors.textMuted.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(widget.item.score * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _scoreColor(widget.item.score),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 44,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.item.score,
                      backgroundColor: AppColors.cardBgLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _scoreColor(widget.item.score),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterThumb() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 80,
        child: _posterLoading
            ? Container(
                color: AppColors.cardBgLight,
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 1.5,
                    ),
                  ),
                ),
              )
            : _posterUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: _posterUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.cardBgLight),
                        errorWidget: (context, url, error) => _posterFallback(),
                      ),
                      // Small "tap to open" overlay hint on poster
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 20,
                          color: Colors.black.withValues(alpha: 0.45),
                          child: const Icon(
                            Icons.open_in_new_rounded,
                            size: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  )
                : _posterFallback(),
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      color: AppColors.cardBgLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppConstants.contentTypeEmojis[widget.item.type] ?? '🎬',
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.cardBgLight, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Obx(() {
                final inList = widget.rec.inWatchlist(widget.item.title);
                return _ActionButton(
                  icon: inList
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  label: inList ? 'Saved' : 'Watchlist',
                  color: inList ? AppColors.accent : AppColors.textMuted,
                  onTap: () => widget.rec.toggleWatchlist(
                    uid: widget.auth.userId,
                    title: widget.item.title,
                    contentType: widget.item.type,
                  ),
                );
              }),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.info_outline_rounded,
                label: 'Details',
                color: AppColors.primary,
                onTap: _openDetail,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.search_rounded,
                label: 'Similar',
                color: AppColors.accentBlue,
                onTap: () {
                  Get.back();
                  final search = Get.find<MovieSearchController>();
                  search.getRecommendations(
                    title: widget.item.title,
                    userId: widget.auth.userId,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final isRated = widget.rec.isRated(widget.item.title);
            final myRating = widget.rec.getRating(widget.item.title);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRated ? '⭐ Your Rating' : 'Rate this recommendation',
                  style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                RatingBar.builder(
                  initialRating: myRating,
                  minRating: 1,
                  itemCount: 5,
                  itemSize: 28,
                  allowHalfRating: true,
                  unratedColor: AppColors.cardBgLight,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star_rounded,
                    color: AppColors.accent,
                  ),
                  onRatingUpdate: (stars) => _showRatingDialog(stars),
                ),
                if (isRated)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${myRating.toStringAsFixed(1)} / 5.0',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
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
                'Rate "${widget.item.title}"',
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${stars.toStringAsFixed(1)} / 5.0 stars',
                style:
                    GoogleFonts.rajdhani(fontSize: 13, color: AppColors.accent),
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
                        widget.rec.submitRating(
                          uid: widget.auth.userId,
                          queryTitle: widget.queryTitle,
                          recommendation: widget.item,
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

  Color _scoreColor(double score) {
    if (score >= 0.7) return AppColors.success;
    if (score >= 0.5) return AppColors.accent;
    return AppColors.textMuted;
  }
}

// --------------------------------------------------
// ACTION BUTTON WIDGET
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                fontSize: 12,
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
