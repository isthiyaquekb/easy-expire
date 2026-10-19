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
}
