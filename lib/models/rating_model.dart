import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String queryTitle;
  final String recommendedTitle;
  final String recommendedType;
  final double stars; // 1-5 from UI
  final String vote; // "up"/"down"/"not_relevant" derived from stars
  final String? review; // optional text review
  final int rank; // position in recommendation list
  final double apiScore; // hybrid score from API
  final DateTime timestamp;

  const RatingModel({
    required this.id,
    required this.queryTitle,
    required this.recommendedTitle,
    required this.recommendedType,
    required this.stars,
    required this.vote,
    this.review,
    required this.rank,
    required this.apiScore,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'queryTitle': queryTitle,
      'recommendedTitle': recommendedTitle,
      'recommendedType': recommendedType,
      'stars': stars,
      'vote': vote,
      'review': review,
      'rank': rank,
      'apiScore': apiScore,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] ?? '',
      queryTitle: map['queryTitle'] ?? '',
      recommendedTitle: map['recommendedTitle'] ?? '',
      recommendedType: map['recommendedType'] ?? '',
      stars: (map['stars'] ?? 0.0).toDouble(),
      vote: map['vote'] ?? 'not_relevant',
      review: map['review'],
      rank: map['rank'] ?? 0,
      apiScore: (map['apiScore'] ?? 0.0).toDouble(),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as dynamic).toDate()
          : DateTime.now(),
    );
  }
}
