import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/constants/app_constants.dart';
import '../models/recommendation_model.dart';
import '../models/autocomplete_model.dart';

/// WHY a custom exception class?
/// So callers (controllers) can tell the difference between:
///   - "no internet" → show offline message
///   - "server waking up" → show cold start message
///   - "server error" → show generic error
/// Without this, every failure looks the same to the UI.
class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  const ApiException(this.message, this.type);
}

enum ApiErrorType {
  noInternet,
  coldStart, // Render free tier waking up (~30-50s)
  serverError,
  notFound,
}

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,

        /// WHY 60s timeout instead of 30s?
        /// Render free tier cold start takes 30-50 seconds.
        /// With 30s timeout, the first request after idle ALWAYS
        /// silently fails. 60s gives it room to wake up.
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    /// WHY only in debug mode?
    /// Prevents API keys / response data from leaking in production builds
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[API] $obj'),
        ),
      );
    }
  }

  /// WHY check connectivity only HERE (not before every call)?
  ///
  /// OLD approach: check connectivity → THEN make call
  /// Problem: adds 50-200ms latency to EVERY request including
  /// autocomplete (fires on every keystroke). Felt sluggish.
  ///
  /// NEW approach: try the call → if it fails with a network error,
  /// THEN check connectivity to give a better error message.
  /// Result: happy path (has internet) is instant, sad path still
  /// shows the right message. Best of both worlds!
  Future<bool> _hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result.first != ConnectivityResult.none;
  }

  // --------------------------------------------------
  // GET RECOMMENDATIONS
  // --------------------------------------------------

  Future<RecommendationResponse?> getRecommendations({
    required String title,
    String? contentType,
    int topK = 10,
    String? userId,
  }) async {
    try {
      final params = <String, dynamic>{
        'title': title,
        'top_k': topK,
      };
      if (contentType != null && contentType != 'any') {
        params['content_type'] = contentType;
      }
      if (userId != null) {
        params['user_id'] = userId;
      }

      final response = await _dio.get(
        AppConstants.recommendEndpoint,
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        return RecommendationResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[ApiService] DioException: ${e.message}');

      /// WHY check timeout specifically?
      /// A timeout on the FIRST call after idle = Render cold start.
      /// We bubble this up so the UI can show "Server waking up..."
      /// instead of a confusing generic error.
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        final hasNet = await _hasConnection();
        if (!hasNet) {
          throw const ApiException(
            'No internet connection. Please check your network.',
            ApiErrorType.noInternet,
          );
        }
        throw const ApiException(
          'Server is waking up ⏳ Please wait a moment and try again.\n(This only happens after a period of inactivity)',
          ApiErrorType.coldStart,
        );
      }

      if (e.type == DioExceptionType.connectionError) {
        final hasNet = await _hasConnection();
        if (!hasNet) {
          throw const ApiException(
            'No internet connection. Please check your network.',
            ApiErrorType.noInternet,
          );
        }
      }

      return null;
    } catch (e) {
      /// Re-throw our own exceptions so controllers can handle them
      if (e is ApiException) rethrow;
      debugPrint('[ApiService] Unexpected error: $e');
      return null;
    }
  }

  // --------------------------------------------------
  // AUTOCOMPLETE
  // --------------------------------------------------

  Future<List<AutocompleteModel>> getAutocomplete(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final response = await _dio.get(
        AppConstants.autocompleteEndpoint,
        queryParameters: {'query': query},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        return results
            .map((e) => AutocompleteModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      /// WHY swallow autocomplete errors silently?
      /// Autocomplete is a "nice to have" — if it fails, the user
      /// can still type and search manually. No need to alarm them.
      debugPrint('[ApiService] Autocomplete error: $e');
      return [];
    }
  }

  // --------------------------------------------------
  // CONTENT TYPES
  // --------------------------------------------------

  Future<Map<String, dynamic>> getContentTypes() async {
    try {
      final response = await _dio.get(AppConstants.contentTypesEndpoint);
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('[ApiService] ContentTypes error: $e');
      return {};
    }
  }
}
