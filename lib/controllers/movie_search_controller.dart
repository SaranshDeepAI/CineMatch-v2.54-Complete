import 'package:get/get.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../models/autocomplete_model.dart';
import '../models/recommendation_model.dart';
import '../core/constants/app_constants.dart';

class MovieSearchController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  /// Search state
  final RxString searchQuery = ''.obs;
  final RxString selectedType = 'any'.obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoadingSuggestions = false.obs;

  /// Results
  final RxList<AutocompleteModel> suggestions = <AutocompleteModel>[].obs;
  final Rxn<RecommendationResponse> recommendations =
      Rxn<RecommendationResponse>();

  /// Error state
  final RxString errorMessage = ''.obs;
  final RxBool notFound = false.obs;

  /// WHY a separate coldStart flag?
  /// Cold start is a special case — the server IS responding, just slowly.
  /// We want to show a different, friendlier message than a generic error:
  /// "Server waking up ⏳" instead of "Could not connect".
  final RxBool isColdStart = false.obs;

  /// WHY debounce?
  /// Without it, every single keystroke fires an API call.
  /// Debounce waits 400ms after user STOPS typing before calling API.
  /// Saves API calls and feels smoother! ⚡
  Worker? _debounceWorker;

  @override
  void onInit() {
    super.onInit();
    _debounceWorker = debounce(
      searchQuery,
      (String query) => _fetchSuggestions(query),
      time: const Duration(milliseconds: 400),
    );
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    super.onClose();
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      suggestions.clear();
    }
  }

  void setContentType(String type) {
    selectedType.value = type;
  }

  // --------------------------------------------------
  // AUTOCOMPLETE
  // --------------------------------------------------

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().length < 2) {
      suggestions.clear();
      return;
    }
    isLoadingSuggestions.value = true;
    try {
      final results = await _apiService.getAutocomplete(query);
      suggestions
          .assignAll(results.take(AppConstants.autocompleteLimit).toList());
    } finally {
      isLoadingSuggestions.value = false;
    }
  }

  // --------------------------------------------------
  // GET RECOMMENDATIONS
  // --------------------------------------------------

  Future<void> getRecommendations({
    required String title,
    required String userId,
  }) async {
    try {
      isSearching.value = true;
      errorMessage.value = '';
      notFound.value = false;
      isColdStart.value = false;
      suggestions.clear();

      final response = await _apiService.getRecommendations(
        title: title,
        contentType: selectedType.value == 'any' ? null : selectedType.value,
        userId: userId,
      );

      if (response == null) {
        errorMessage.value = 'Could not connect to server. Please try again.';
        return;
      }

      if (response.results.isEmpty) {
        notFound.value = true;
        return;
      }

      recommendations.value = response;

      /// Save search to Firestore for history + future RL
      await _firestoreService.saveSearchHistory(
        uid: userId,
        query: title,
        detectedType: response.detectedType,
        resultCount: response.count,
      );

      /// Navigate to recommendations screen
      Get.toNamed('/recommendations');
    } on ApiException catch (e) {
      /// WHY catch ApiException separately?
      /// This is our own custom exception from ApiService.
      /// We can show a specific, user-friendly message for each case.
      if (e.type == ApiErrorType.coldStart) {
        isColdStart.value = true;
        errorMessage.value = e.message;
      } else if (e.type == ApiErrorType.noInternet) {
        errorMessage.value =
            '📶 No internet connection. Please check your network.';
      } else {
        errorMessage.value = e.message;
      }
    } catch (e) {
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isSearching.value = false;
    }
  }

  void clearResults() {
    recommendations.value = null;
    suggestions.clear();
    searchQuery.value = '';
    errorMessage.value = '';
    notFound.value = false;
    isColdStart.value = false;
  }
}
