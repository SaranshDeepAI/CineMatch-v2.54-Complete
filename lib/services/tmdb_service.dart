import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/detail_model.dart';

class TmdbService {
  late final Dio _dio;

  /// WHY a Map cache?
  /// Home screen has 36 poster cards. Without this, every card fires
  /// its own TMDB network call = 36 simultaneous requests on load.
  /// With this cache, we fetch each title ONCE and return instantly after.
  final Map<String, String?> _posterCache = {};

  /// WHY an in-flight tracker?
  /// If two cards ask for the same title at the same millisecond,
  /// without this we'd fire 2 network calls. The second caller joins
  /// the first one's Future instead. Zero duplicate requests!
  final Map<String, Future<String?>> _inFlight = {};

  /// Cache for full detail lookups — so tapping the same card twice
  /// doesn't re-fetch from TMDB
  final Map<String, DetailModel> _detailCache = {};

  TmdbService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.tmdbBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  // --------------------------------------------------
  // POSTER URL (existing — unchanged)
  // --------------------------------------------------

  Future<String?> getPosterUrl(String title) async {
    if (_posterCache.containsKey(title)) return _posterCache[title];
    if (_inFlight.containsKey(title)) return _inFlight[title];

    final future = _fetchFromTmdb(title);
    _inFlight[title] = future;
    final result = await future;
    _posterCache[title] = result;
    _inFlight.remove(title);
    return result;
  }

  Future<String?> _fetchFromTmdb(String title) async {
    try {
      final response = await _dio.get(
        '/search/multi',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'query': title,
          'page': 1,
        },
      );
      if (response.statusCode == 200) {
        final results = response.data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final posterPath = results.first['poster_path'];
          if (posterPath != null) {
            return '${AppConstants.tmdbImageUrl}$posterPath';
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('[TmdbService] Poster error for "$title": $e');
      return null;
    }
  }

  Future<void> prefetchPosters(List<String> titles) async {
    final unique = titles.toSet().toList();
    await Future.wait(unique.map((title) => getPosterUrl(title)));
    debugPrint('[TmdbService] Prefetched ${unique.length} posters ✅');
  }

  int get cacheSize => _posterCache.length;
  void clearCache() => _posterCache.clear();

  // --------------------------------------------------
  // FULL DETAIL FETCH (new!)
  // --------------------------------------------------

  /// WHY two steps (search → details)?
  /// TMDB search gives us the numeric ID of the title.
  /// We then use that ID to fetch full details + credits + videos
  /// in parallel. Can't skip step 1 because we only have the title
  /// string from our recommender, not the TMDB ID.
  Future<DetailModel?> getDetails({
    required String title,
    required String contentType,
  }) async {
    // Return cached version if available — no need to re-fetch
    final cacheKey = '${title}_$contentType';
    if (_detailCache.containsKey(cacheKey)) {
      return _detailCache[cacheKey];
    }

    try {
      // Step 1 — search for the title to get its TMDB numeric ID
      final searchResp = await _dio.get(
        '/search/multi',
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'query': title,
          'page': 1,
        },
      );

      if (searchResp.statusCode != 200) return null;
      final results = searchResp.data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final tmdbId = first['id'];

      /// WHY check media_type?
      /// TMDB has separate endpoints for movies vs TV shows.
      /// /movie/{id} and /tv/{id} have different field names.
      /// We detect which one to call from the search result.
      final mediaType = first['media_type'] ?? _guessMediaType(contentType);

      // Step 2 — fetch details + credits + videos all in parallel
      /// WHY Future.wait?
      /// Sequential: 3 calls × ~300ms = ~900ms wait
      /// Parallel: all 3 fire at once = ~300ms wait. 3× faster! ⚡
      final futures = await Future.wait([
        _dio.get(
          '/$mediaType/$tmdbId',
          queryParameters: {'api_key': AppConstants.tmdbApiKey},
        ),
        _dio.get(
          '/$mediaType/$tmdbId/credits',
          queryParameters: {'api_key': AppConstants.tmdbApiKey},
        ),
        _dio.get(
          '/$mediaType/$tmdbId/videos',
          queryParameters: {'api_key': AppConstants.tmdbApiKey},
        ),
      ]);

      final detailResp = futures[0];
      final creditsResp = futures[1];
      final videosResp = futures[2];

      // Parse cast — top 5 only, skip ones with no profile photo
      final rawCast =
          (creditsResp.data['cast'] as List<dynamic>? ?? []).take(10).toList();
      final cast = rawCast
          .map((c) => CastMember.fromJson(c as Map<String, dynamic>))
          .where((c) => c.profilePath != null)
          .take(5)
          .toList();

      // Parse trailer — find official YouTube trailer first
      final videos = videosResp.data['results'] as List<dynamic>? ?? [];
      String? trailerKey;
      for (final v in videos) {
        if (v['site'] == 'YouTube' &&
            v['type'] == 'Trailer' &&
            v['official'] == true) {
          trailerKey = v['key'];
          break;
        }
      }
      // Fallback: any YouTube trailer if no official one found
      if (trailerKey == null) {
        for (final v in videos) {
          if (v['site'] == 'YouTube' && v['type'] == 'Trailer') {
            trailerKey = v['key'];
            break;
          }
        }
      }

      final detail = DetailModel.fromJson(
        detailResp.data as Map<String, dynamic>,
        cast,
        trailerKey,
        contentType,
      );

      // Cache so second tap is instant
      _detailCache[cacheKey] = detail;
      return detail;
    } catch (e) {
      debugPrint('[TmdbService] Detail error for "$title": $e');
      return null;
    }
  }

  /// WHY this helper?
  /// Our content types (anime, kdrama, bollywood) don't map 1:1
  /// to TMDB media types (movie/tv). We use this to make a best guess
  /// when TMDB search doesn't return a media_type field.
  String _guessMediaType(String contentType) {
    switch (contentType) {
      case 'movie':
      case 'bollywood':
      case 'indian_cinema':
        return 'movie';
      case 'tv':
      case 'anime':
      case 'kdrama':
        return 'tv';
      default:
        return 'movie';
    }
  }
}
