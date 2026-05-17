class AppConstants {
  static const String appName = 'tvOnline';
  static const String appVersion = '1.0.0';

  // Cache durations
  static const Duration catalogCacheDuration = Duration(hours: 6);
  static const Duration imageCacheDuration = Duration(days: 30);
  static const Duration apiCacheDuration = Duration(minutes: 30);

  // Pagination
  static const int pageSize = 50;
  static const int carouselItemCount = 20;

  // Player
  static const Duration seekDuration = Duration(seconds: 10);
  static const Duration controlsTimeout = Duration(seconds: 4);

  // UI
  static const double cardAspectRatioPortrait = 2 / 3;
  static const double cardAspectRatioLandscape = 16 / 9;
  static const double borderRadius = 8.0;
  static const double borderRadiusLarge = 14.0;

  // Shared prefs keys
  static const String keyServerUrl = 'server_url';
  static const String keyUsername = 'username';
  static const String keyPassword = 'password';
  static const String keyUserInfo = 'user_info';
  static const String keySelectedProfile = 'selected_profile';
  static const String keyVideoQuality = 'video_quality';
  static const String keySubtitleLanguage = 'subtitle_language';
  static const String keyAudioLanguage = 'audio_language';
  static const String keyWatchHistory = 'watch_history';
  static const String keyWatchlist = 'watchlist';
  static const String keyThemeMode = 'theme_mode';
}
