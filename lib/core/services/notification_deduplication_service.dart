import 'dart:developer';
import 'package:get_storage/get_storage.dart';

/// Service responsible for persisting and checking notification delivery state
/// to prevent duplicate or over-frequent alerts across app restarts.
class NotificationDeduplicationService {
  static const String _keyPrefix = 'notif_last_';

  final GetStorage _storage;

  NotificationDeduplicationService({GetStorage? storage})
    : _storage = storage ?? GetStorage();

  GetStorage get storage => _storage;

  String _buildKey(int notificationId) => '$_keyPrefix$notificationId';

  /// Retrieves the timestamp when [notificationId] was last shown or scheduled,
  /// or `null` if no prior delivery has occurred.
  DateTime? getLastNotified(int notificationId) {
    try {
      final value = _storage.read<String>(_buildKey(notificationId));
      if (value != null && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
    } catch (e) {
      log("Error reading notification timestamp for $notificationId: $e");
    }
    return null;
  }

  /// Records that a notification with [notificationId] was successfully scheduled or sent.
  Future<void> recordNotification(
    int notificationId,
    DateTime timestamp,
  ) async {
    try {
      await _storage.write(
        _buildKey(notificationId),
        timestamp.toIso8601String(),
      );
    } catch (e) {
      log("Error persisting notification timestamp for $notificationId: $e");
    }
  }

  /// Clears deduplication state for a specific [notificationId] (e.g. when product is deleted).
  Future<void> clearRecord(int notificationId) async {
    try {
      await _storage.remove(_buildKey(notificationId));
    } catch (e) {
      log("Error clearing notification record for $notificationId: $e");
    }
  }

  /// Clears all notification deduplication records from storage.
  Future<void> clearAll() async {
    try {
      final keys = _storage.getKeys<Iterable<String>>();
      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          await _storage.remove(key);
        }
      }
    } catch (e) {
      log("Error clearing all notification records: $e");
    }
  }
}
