// WHY a separate model?
// TMDB's detail endpoint returns a LOT of fields. This model
// picks only what we need for the detail screen — keeping it
// clean and easy to work with instead of passing raw Maps around.

class DetailModel {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final int? runtime; // minutes — movies only
  final int? episodes; // episode count — TV/anime/kdrama
  final List<String> genres;
  final List<CastMember> cast;
  final String? trailerKey; // YouTube video key
  final String contentType; // our app's content type label

  const DetailModel({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    this.releaseDate,
    this.runtime,
    this.episodes,
    required this.genres,
    required this.cast,
    this.trailerKey,
    required this.contentType,
  });

  /// Full poster URL at high resolution for detail screen
  String? get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null;

  /// Full backdrop URL — wider image for the top hero section
  String? get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : null;

  /// YouTube trailer URL — opened via url_launcher
  String? get trailerUrl =>
      trailerKey != null ? 'https://www.youtube.com/watch?v=$trailerKey' : null;

  /// Release year — cleaner than showing full date
  String get releaseYear {
    if (releaseDate == null || releaseDate!.isEmpty) return 'N/A';
    return releaseDate!.split('-').first;
  }

  /// Runtime formatted as "1h 45m" — only for movies
  String get runtimeFormatted {
    if (runtime == null || runtime == 0) return '';
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Star rating out of 5 — TMDB uses 10, we show 5
  double get starRating => voteAverage / 2;

  factory DetailModel.fromJson(
    Map<String, dynamic> json,
    List<CastMember> cast,
    String? trailerKey,
    String contentType,
  ) {
    final genreList = (json['genres'] as List<dynamic>? ?? [])
        .map((g) => g['name'].toString())
        .toList();

    return DetailModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      releaseDate: json['release_date'] ?? json['first_air_date'],
      runtime: json['runtime'],
      episodes: json['number_of_episodes'],
      genres: genreList,
      cast: cast,
      trailerKey: trailerKey,
      contentType: contentType,
    );
  }
}

class CastMember {
  final String name;
  final String character;
  final String? profilePath;

  const CastMember({
    required this.name,
    required this.character,
    this.profilePath,
  });

  String? get profileUrl => profilePath != null
      ? 'https://image.tmdb.org/t/p/w185$profilePath'
      : null;

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      name: json['name'] ?? '',
      character: json['character'] ?? '',
      profilePath: json['profile_path'],
    );
  }
}
