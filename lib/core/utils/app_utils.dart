class AppUtils {
  /// Converts star rating (1-5) to API vote type string
  /// Why? Our UI uses stars but the API expects "up"/"down"/"not_relevant"
  static String starsToVote(double stars) {
    if (stars >= 4) return 'up';
    if (stars >= 2) return 'down';
    return 'not_relevant';
  }

  /// Formats a DateTime to readable string like "Jun 9, 2026"
  static String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Capitalizes first letter of each word
  static String toTitleCase(String text) {
    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Truncates long text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Returns a greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
