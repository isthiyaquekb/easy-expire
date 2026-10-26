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
  int urgentIntervalHours = ExpiryPolicy.defaultUrgentIntervalHours,
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
      // Prevent zero-day notifications from firing more frequently than the configured interval (default 2h / 120m)
      final requiredMinutes = urgentIntervalHours * 60;
      if (lastNotifiedAt != null) {
        final elapsedMinutes =
            referenceTime.difference(lastNotifiedAt).inMinutes;
        if (elapsedMinutes < requiredMinutes) {
          return ExpiryNotificationDecision(
            shouldNotify: false,
            tier: tier,
            daysRemaining: 0,
            title: '',
            body: '',
            reason:
                'Throttled: only $elapsedMinutes min elapsed since last alert (min $requiredMinutes min)',
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
      // Policy 2: Hourly reminder policy for already-expired products
      if (lastNotifiedAt != null) {
        final elapsedMinutes =
            referenceTime.difference(lastNotifiedAt).inMinutes;
        if (elapsedMinutes < 60) {
          return ExpiryNotificationDecision(
            shouldNotify: false,
            tier: tier,
            daysRemaining: daysRemaining,
            title: '',
            body: '',
            reason:
                'Throttled: only $elapsedMinutes min elapsed since last hourly alert (min 60 min)',
          );
        }
      }
      return ExpiryNotificationDecision(
        shouldNotify: true,
        tier: tier,
        daysRemaining: daysRemaining,
        title: 'Product Expired',
        body: '$productName has expired! Remove from inventory immediately.',
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

/// Computes the local digest fire time on [date].
/// Defaults to 08:00 AM local time per Policy 1, or computes based on
/// [storeOpeningTime] and [notifyLeadMinutes] when explicitly provided.
DateTime computeDigestFireTime({
  required DateTime date,
  String? storeOpeningTime,
  int? notifyLeadMinutes,
}) {
  if (storeOpeningTime != null && notifyLeadMinutes != null) {
    int hour = 10;
    int minute = 0;
    final parts = storeOpeningTime.split(':');
    if (parts.length >= 2) {
      hour = int.tryParse(parts[0].trim()) ?? 10;
      minute = int.tryParse(parts[1].trim()) ?? 0;
    }
    final baseTime = DateTime(date.year, date.month, date.day, hour, minute);
    return baseTime.subtract(Duration(minutes: notifyLeadMinutes));
  }
  return DateTime(
    date.year,
    date.month,
    date.day,
    ExpiryPolicy.dailyDigestHour,
    ExpiryPolicy.dailyDigestMinute,
  );
}

/// Formats the Urgent Digest title.
String formatUrgentDigestTitle(int count, {bool isCatchUp = false}) {
  final prefix = isCatchUp ? '[Catch-up] ' : '';
  if (count <= 1) {
    return '${prefix}Pull before opening: 1 item expires today';
  }
  return '${prefix}Pull before opening: $count items expire today';
}

/// Formats the Urgent Digest body (< 100 chars for lock screen).
String formatUrgentDigestBody(List<String> productNames) {
  if (productNames.isEmpty) return '';
  if (productNames.length == 1) {
    return '${productNames.first} expires today';
  }
  final top3 = productNames.take(3).join(', ');
  final remaining = productNames.length - 3;
  if (remaining > 0) {
    return '$top3 +$remaining more';
  }
  return top3;
}

/// Formats the Warning Digest title.
String formatWarningDigestTitle(int count, {bool isCatchUp = false}) {
  final prefix = isCatchUp ? '[Catch-up] ' : '';
  if (count <= 1) {
    return '${prefix}Check stock: 1 item expires within ${ExpiryPolicy.warningWindowDays} days';
  }
  return '${prefix}Check stock: $count items expire within ${ExpiryPolicy.warningWindowDays} days';
}

/// Formats the Warning Digest body (< 100 chars for lock screen).
String formatWarningDigestBody({
  required int count,
  required String nearestName,
  required int nearestDays,
}) {
  if (count <= 1) {
    final daysText = nearestDays == 1 ? 'tomorrow' : 'in $nearestDays days';
    return '$nearestName expires $daysText';
  }
  final nearestText =
      nearestDays == 1 ? '$nearestName tomorrow' : '$nearestName in $nearestDays days';
  return '$count products expire within ${ExpiryPolicy.warningWindowDays} days. Nearest: $nearestText';
}
