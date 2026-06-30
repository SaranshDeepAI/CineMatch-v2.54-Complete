class AutocompleteModel {
  final String title;
  final String contentType;
  final double score;

  const AutocompleteModel({
    required this.title,
    required this.contentType,
    required this.score,
  });

  factory AutocompleteModel.fromJson(Map<String, dynamic> json) {
    return AutocompleteModel(
      title: json['title'] ?? '',
      contentType: json['content_type'] ?? 'movie',
      score: (json['score'] ?? 0.0).toDouble(),
    );
  }
}
