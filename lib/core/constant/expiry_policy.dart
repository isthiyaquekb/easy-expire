/// Single source of truth for product expiration status, warning window thresholds,
/// and categorization helpers across the entire application.
class ExpiryPolicy {
  /// The rolling warning window threshold in calendar days.
  /// Items expiring within 1..warningWindowDays trigger daily warning reminders.
  static const int warningWindowDays = 4;

  /// Returns true if the product has already expired (negative days remaining).
  static bool isExpired(int daysRemaining) => daysRemaining < 0;

  /// Returns true if the product expires today (exactly 0 calendar days remaining).
  static bool isUrgent(int daysRemaining) => daysRemaining == 0;

  /// Returns true if the product is in the warning window (1 to warningWindowDays).
  static bool isWarning(int daysRemaining) =>
      daysRemaining >= 1 && daysRemaining <= warningWindowDays;

  /// Returns true if the product is safely beyond the warning window.
  static bool isSafe(int daysRemaining) => daysRemaining > warningWindowDays;

  /// Daily store opening digest delivery hour (08:00 AM local time).
  static const int dailyDigestHour = 8;

  /// Daily store opening digest delivery minute.
  static const int dailyDigestMinute = 0;

  /// Default urgent reminder interval for items expiring today (2 hours).
  static const int defaultUrgentIntervalHours = 2;

  /// Alternative configurable urgent reminder interval for items expiring today (4 hours).
  static const int alternativeUrgentIntervalHours = 4;

  /// Hourly reminder interval for already-expired products (1 hour).
  static const int expiredReminderIntervalHours = 1;

  /// Duration for which user notification dismissal suppresses alerts for a product (24 hours).
  static const Duration dismissalSuppressionDuration = Duration(hours: 24);
}
