import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/movie_search_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/themed_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MovieSearchController _search = Get.find<MovieSearchController>();
  final AuthController _auth = Get.find<AuthController>();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScreen(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildTypeFilter(),
                const SizedBox(height: 8),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover',
            style: GoogleFonts.rajdhani(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
          Text(
            'Find your next favourite watch',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Type a movie, anime, drama...',
                hintStyle: GoogleFonts.rajdhani(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  onPressed: () {
                    _textController.clear();
                    _search.clearResults();
                  },
                ),
              ),
              onChanged: _search.onSearchChanged,
              onSubmitted: (_) => _handleSearch(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _handleSearch,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: AppConstants.contentTypes.length,
          itemBuilder: (context, index) {
            final type = AppConstants.contentTypes[index];
            final label = AppConstants.contentTypeLabels[type] ?? type;
            final emoji = AppConstants.contentTypeEmojis[type] ?? '🎬';

            /// Why listen directly? → avoids nested Obx issue
            final isSelected = _search.selectedType.value == type;
            return GestureDetector(
              onTap: () {
                _search.setContentType(type);

                /// Why setState? → forces this widget to rebuild
                /// when type changes without needing Obx
                setState(() {});
              },
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
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      final isSearching = _search.isSearching.value;
      final notFound = _search.notFound.value;
      final errorMessage = _search.errorMessage.value;

      if (isSearching) return _buildLoadingState();
      if (notFound) return _buildNotFound();
      if (errorMessage.isNotEmpty) return _buildError();
      return _buildEmptyState();
    });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Finding recommendations...',
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Powered by AI ✨',
            style: GoogleFonts.rajdhani(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.rajdhani(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different title or check the spelling',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            _search.errorMessage.value,
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleSearch,
            child: Text(
              'Try Again',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Try searching for',
            style: GoogleFonts.rajdhani(
              fontSize: 15,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Demon Slayer',
              'Squid Game',
              'Interstellar',
              'Jawan',
              'RRR',
              'Breaking Bad',
              'Solo Leveling',
              '3 Idiots',
              'Inception',
              'Attack on Titan',
              'Money Heist',
              'The Dark Knight',
              'KGF Chapter 2',
              'Pushpa',
              'Jujutsu Kaisen',
              'Business Proposal',
              'Parasite',
              'Your Name',
            ]
                .map((title) => GestureDetector(
                      onTap: () {
                        _textController.text = title;
                        _search.onSearchChanged(title);
                        _handleSearch();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBgLight),
                        ),
                        child: Text(
                          title,
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _handleSearch() {
    final query = _textController.text.trim();
    if (query.isEmpty) return;
    _focusNode.unfocus();
    _search.getRecommendations(
      title: query,
      userId: _auth.userId,
    );
  }
}
