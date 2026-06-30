import 'dart:async';
import 'package:get/get.dart';
import '../services/firestore_service.dart';
import '../models/recommendation_model.dart';
import '../models/rating_model.dart';
import '../core/utils/app_utils.dart';

class RecommendationController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  /// Tracks which items have been rated — key is title, value is stars
  final RxMap<String, double> ratedItems = <String, double>{}.obs;

  /// Tracks which items are in watchlist
  final RxMap<String, bool> watchlistItems = <String, bool>{}.obs;
  final RxBool isSaving = false.obs;
  final RxString statusMessage = ''.obs;

  /// Fix #20 — store timer so we can cancel it on dispose
  /// Why? → If controller is destroyed within 2 seconds, the callback
  /// fires on a dead observable and causes errors
  Timer? _statusTimer;

  // --------------------------------------------------
  // SUBMIT RATING
  // --------------------------------------------------

  Future<void> submitRating({
    required String uid,
    required String queryTitle,
    required RecommendationModel recommendation,
    required double stars,
    String? review,
  }) async {
    try {
      isSaving.value = true;

      final rating = RatingModel(
        id: _firestoreService.generateId(),
        queryTitle: queryTitle,
        recommendedTitle: recommendation.title,
        recommendedType: recommendation.type,
        stars: stars,
        vote: AppUtils.starsToVote(stars),
        review: review,
        rank: recommendation.rank,
        apiScore: recommendation.score,
        timestamp: DateTime.now(),
      );

      await _firestoreService.saveRating(uid: uid, rating: rating);

      ratedItems[recommendation.title] = stars;

      statusMessage.value = '⭐ Rating saved!';

      /// Fix #20 — cancel previous timer before starting new one
      _statusTimer?.cancel();
      _statusTimer = Timer(
        const Duration(seconds: 2),
        () => statusMessage.value = '',
      );
    } catch (e) {
      statusMessage.value = 'Failed to save rating. Try again.';
    } finally {
      isSaving.value = false;
    }
  }

  // --------------------------------------------------
  // WATCHLIST
  // --------------------------------------------------

  Future<void> toggleWatchlist({
    required String uid,
    required String title,
    required String contentType,
  }) async {
    final isInWatchlist = watchlistItems[title] ?? false;

    try {
      if (isInWatchlist) {
        await _firestoreService.removeFromWatchlist(
          uid: uid,
          title: title,
        );
        watchlistItems[title] = false;
        statusMessage.value = 'Removed from watchlist';
      } else {
        await _firestoreService.addToWatchlist(
          uid: uid,
          title: title,
          contentType: contentType,
        );
        watchlistItems[title] = true;
        statusMessage.value = '✅ Added to watchlist!';
      }

      /// Fix #20 — cancel previous timer before starting new one
      _statusTimer?.cancel();
      _statusTimer = Timer(
        const Duration(seconds: 2),
        () => statusMessage.value = '',
      );
    } catch (e) {
      statusMessage.value = 'Action failed. Please try again.';
    }
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  bool isRated(String title) => ratedItems.containsKey(title);
  double getRating(String title) => ratedItems[title] ?? 0.0;
  bool inWatchlist(String title) => watchlistItems[title] ?? false;

  void clearState() {
    ratedItems.clear();
    watchlistItems.clear();
    statusMessage.value = '';
    _statusTimer?.cancel();
  }

  @override
  void onClose() {
    /// Fix #20 — cancel timer when controller is destroyed
    /// so it doesn't fire on a dead observable
    _statusTimer?.cancel();
    super.onClose();
  }
}
