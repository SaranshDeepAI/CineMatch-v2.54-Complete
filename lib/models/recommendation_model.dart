class RecommendationModel {
  final String title;
  final String type;
  final double score;
  final int genreOverlap;
  final int rank;

  const RecommendationModel({
    required this.title,
    required this.type,
    required this.score,
    required this.genreOverlap,
    required this.rank,
  });

  /// Why fromJson? → converts raw API response map into this clean object
  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      title: json['title'] ?? '',
      type: json['type'] ?? 'movie',
      score: (json['score'] ?? 0.0).toDouble(),
      genreOverlap: json['genre_overlap'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }

  /// Why toMap? → when saving to Firestore we need a Map back
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'score': score,
      'genre_overlap': genreOverlap,
      'rank': rank,
    };
  }
}

/// Wraps the full API /recommend response
class RecommendationResponse {
  final String query;
  final String detectedType;
  final String filterApplied;
  final int fallbackLevel;
  final List<RecommendationModel> results;
  final int count;

  const RecommendationResponse({
    required this.query,
    required this.detectedType,
    required this.filterApplied,
    required this.fallbackLevel,
    required this.results,
    required this.count,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? [];
    return RecommendationResponse(
      query: json['query'] ?? '',
      detectedType: json['detected_type'] ?? '',
      filterApplied: json['filter_applied'] ?? 'auto',
      fallbackLevel: json['fallback_level'] ?? 0,
      count: json['count'] ?? 0,
      results: rawResults
          .map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
