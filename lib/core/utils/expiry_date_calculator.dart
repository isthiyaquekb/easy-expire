/// Pure domain utility for expiry date calculations, notification tier determination,
/// and deterministic notification ID generation.
library;

import 'package:easyexpire/core/constant/expiry_policy.dart';

/// Notification schedule tier based on days remaining until expiry.
enum ExpiryNotificationTier {
  /// In the warning window (1..warningWindowDays) - at most once per calendar day at 09:00.
  dailyReminder,

  /// Exactly 0 calendar days remaining (expiring today, min 2-hour interval).
  zeroDayReminder,

  /// Safely beyond warning window (> warningWindowDays). No notification.
  safe,

  /// Less than 0 calendar days remaining (already expired, cancel reminders).
  expired,
}

/// Result of evaluating whether an item should trigger a notification at [referenceTime].
class ExpiryNotificationDecision {
  final bool shouldNotify;
  final ExpiryNotificationTier tier;
  final int daysRemaining;
  final String title;
  final String body;
  final String? reason;

  const ExpiryNotificationDecision({
    required this.shouldNotify,
    required this.tier,
    required this.daysRemaining,
    required this.title,
    required this.body,
    this.reason,
  });
}

/// Normalises both dates to their calendar date (year, month, day) in UTC
/// to avoid daylight-saving time (DST) shifts and time-of-day biases.
///
/// Returns:
/// - Positive integer if [expiryDate] is on a future calendar day.
/// - `0` if [expiryDate] and [referenceDate] share the exact same calendar day.
/// - Negative integer if [expiryDate] is on a past calendar day.
int calculateCalendarDaysRemaining(
  DateTime expiryDate,
  DateTime referenceDate,
) {
  // Use UTC calendar dates so that every day is exactly 24 hours (86,400s),
  // completely eliminating DST discrepancies and midnight boundary artifacts.
  final utcExpiry = DateTime.utc(
    expiryDate.year,
    expiryDate.month,
    expiryDate.day,
  );
  final utcReference = DateTime.utc(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  );

  return utcExpiry.difference(utcReference).inDays;
}

/// Determines the notification tier for a given [daysRemaining] using [ExpiryPolicy].
ExpiryNotificationTier getExpiryTier(int daysRemaining) {
  if (ExpiryPolicy.isExpired(daysRemaining)) {
    return ExpiryNotificationTier.expired;
  } else if (ExpiryPolicy.isUrgent(daysRemaining)) {
    return ExpiryNotificationTier.zeroDayReminder;
  } else if (ExpiryPolicy.isWarning(daysRemaining)) {
    return ExpiryNotificationTier.dailyReminder;
  } else {
    return ExpiryNotificationTier.safe;
  }
}

/// Evaluates whether an expiring product should trigger a notification at [referenceTime],
/// respecting deduplication rules and [ExpiryPolicy]:
/// - Daily warning reminders (`1 <= daysRemaining <= warningWindowDays`): At most once per calendar day.
/// - Zero-day urgent reminders (`daysRemaining == 0`): At most once every 2 hours (120 minutes).
/// - Safe items (`daysRemaining > warningWindowDays`): No notifications.
/// - Expired items (`daysRemaining < 0`): No notifications, cancel existing schedules.
ExpiryNotificationDecision evaluateNotificationSchedule({
  required String productName,
  required DateTime expiryDate,
  required DateTime referenceTime,
  DateTime? lastNotifiedAt,
}) {
  final daysRemaining = calculateCalendarDaysRemaining(
    expiryDate,
    referenceTime,
  );
  final tier = getExpiryTier(daysRemaining);

  switch (tier) {
    case ExpiryNotificationTier.dailyReminder:
      // Prevent repeated daily notifications for the same item on the same calendar day
      if (lastNotifiedAt != null) {
        final daysSinceLastNotified = calculateCalendarDaysRemaining(
          referenceTime,
          lastNotifiedAt,
        );
        if (daysSinceLastNotified == 0) {
          return ExpiryNotificationDecision(
            shouldNotify: false,
            tier: tier,
            daysRemaining: daysRemaining,
            title: '',
            body: '',
            reason: 'Already notified today ($daysRemaining days remaining)',
          );
        }
      }

      final bodyText =
          daysRemaining == 1
              ? '$productName will expire tomorrow!'
              : '$productName will expire in $daysRemaining days!';

      return ExpiryNotificationDecision(
        shouldNotify: true,
        tier: tier,
        daysRemaining: daysRemaining,
        title: 'Product Expiry Alert',
        body: bodyText,
      );

    case ExpiryNotificationTier.zeroDayReminder:
      // Prevent zero-day notifications from firing more frequently than once every 2 hours
      if (lastNotifiedAt != null) {
        final elapsedMinutes =
            referenceTime.difference(lastNotifiedAt).inMinutes;
        if (elapsedMinutes < 120) {
          return ExpiryNotificationDecision(
            shouldNotify: false,
            tier: tier,
            daysRemaining: 0,
            title: '',
            body: '',
            reason:
                'Throttled: only $elapsedMinutes min elapsed since last alert (min 120 min)',
          );
        }
      }

      return ExpiryNotificationDecision(
        shouldNotify: true,
        tier: tier,
        daysRemaining: 0,
        title: 'Product Expires TODAY',
        body: '$productName is expiring today!',
      );

    case ExpiryNotificationTier.safe:
      return ExpiryNotificationDecision(
        shouldNotify: false,
        tier: tier,
        daysRemaining: daysRemaining,
        title: '',
        body: '',
        reason:
            'Product is safe ($daysRemaining days remaining > ${ExpiryPolicy.warningWindowDays})',
      );

    case ExpiryNotificationTier.expired:
      return ExpiryNotificationDecision(
        shouldNotify: false,
        tier: tier,
        daysRemaining: daysRemaining,
        title: '',
        body: '',
        reason: 'Product has already expired; cancel future reminders',
      );
  }
}

/// Derives a stable, deterministic 31-bit integer notification ID from [key]
/// using the 32-bit FNV-1a hash algorithm.
///
/// Unlike Dart's `Object.hashCode`, this returns the identical integer across
/// executions, app restarts, platforms, and devices.
int generateStableNotificationId(String key) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < key.length; i++) {
    hash ^= key.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  // Return non-negative 31-bit integer for maximum compatibility with
  // Android NotificationManager and iOS UNUserNotificationCenter.
  return hash & 0x7FFFFFFF;
}
