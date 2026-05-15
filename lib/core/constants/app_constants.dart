/// Application-wide constants for VD Shift Manager
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'VD Shift Manager';
  static const String appSubtitle = 'Track shifts. Track growth.';
  static const String appVersion = '1.0.0';
  static const String userName = 'Vishrut';

  // Hive Box Names
  static const String shiftsBox = 'shifts_box';
  static const String settingsBox = 'settings_box';
  static const String syncBox = 'sync_box';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String shiftsCollection = 'shifts';

  // Settings Keys
  static const String themeKey = 'is_dark_mode';
  static const String lastSyncKey = 'last_sync_time';

  // Time Zones
  static const String indiaTimeZone = 'Asia/Kolkata';
  static const String londonTimeZone = 'Europe/London';
  static const double indiaUtcOffset = 5.5; // UTC+5:30
  static const double londonUtcOffset = 0.0; // UTC+0 (will adjust for BST)

  // Motivational Quote
  static const String motivationalQuote =
      'You can do all this stuff, just trust yourself ❤️';

  // Default Pay Rate
  static const double defaultPayPerHour = 12.0;
}
