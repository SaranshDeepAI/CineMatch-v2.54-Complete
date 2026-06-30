class AppConstants {
  // --- API ---
  static const String baseUrl = 'https://cinematch-v2-api.onrender.com';
  static const String recommendEndpoint = '/recommend';
  static const String autocompleteEndpoint = '/autocomplete';
  static const String contentTypesEndpoint = '/content-types';

  // --- Firestore Collections ---
  static const String usersCollection = 'users';
  static const String preferencesCollection = 'user_preferences';
  static const String searchHistoryCollection = 'search_history';
  static const String ratingsCollection = 'ratings';
  static const String watchlistCollection = 'watchlist';
  // --- TMDB ---
  static const String tmdbApiKey = '2addbc2bf90cc62db27bf11d93d670f6';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageUrl = 'https://image.tmdb.org/t/p/w500';
  // --- Content Types ---
  static const List<String> contentTypes = [
    'any',
    'movie',
    'tv',
    'anime',
    'kdrama',
    'bollywood',
    'indian_cinema',
  ];

  // --- Content Type Display Names ---
  static const Map<String, String> contentTypeLabels = {
    'any': 'All',
    'movie': 'Movies',
    'tv': 'TV Shows',
    'anime': 'Anime',
    'kdrama': 'K-Drama',
    'bollywood': 'Bollywood',
    'indian_cinema': 'Indian Cinema',
  };

  // --- Content Type Emojis (for UI cards) ---
  static const Map<String, String> contentTypeEmojis = {
    'any': '🎬',
    'movie': '🎥',
    'tv': '📺',
    'anime': '⛩️',
    'kdrama': '🎭',
    'bollywood': '💃',
    'indian_cinema': '🎞️',
  };

  // --- Shared Preferences Keys ---
  static const String prefUserId = 'user_id';
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefThemeMode = 'theme_mode';

  // --- App Info ---
  static const String appName = 'CineMatch';
  static const String appTagline = 'Your AI Powered Watch Guide';
  static const int recommendationCount = 10;
  static const int autocompleteLimit = 8;
}
