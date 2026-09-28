import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/reminder_detail_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service responsible for local Android notification initialization,
/// permission requests, and scheduling/cancelling reminder notifications.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  static const String channelId = 'second_brain_reminders';
  static const String channelName = 'Second Brain Reminders';
  static const String channelDescription =
      'Notifications for reminders and important dates.';

  /// Initializes timezone database and local notification plugin.
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_isInitialized) return;
    _navigatorKey = navigatorKey;

    try {
      // 1. Timezone configuration
      tz.initializeTimeZones();
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      } catch (e) {
        // Fallback — keep UTC if plugin unavailable in test/web environment.
        debugPrint('NotificationService: Defaulting timezone ($e)');
      }

      // 2. Platform initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // FLN 22+ uses named parameters for initialize().
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            _handleNotificationTap(response.payload!);
          }
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  /// Requests notification permission on Android 13+ (API 33+).
  Future<bool> requestPermissions() async {
    if (!_isInitialized) return false;
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService requestPermissions error: $e');
      return false;
    }
  }

  /// Derives a deterministic 31-bit positive integer from the reminder ID.
  int getNotificationId(String reminderId) {
    return reminderId.hashCode.abs() & 0x7FFFFFFF;
  }

  /// Schedules a local notification for a future uncompleted reminder.
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_isInitialized) return;
    if (reminder.isCompleted) return;

    final now = DateTime.now();
    if (!reminder.reminderDateTime.isAfter(now)) {
      // Past or overdue reminders are not scheduled.
      return;
    }

    try {
      final notificationId = getNotificationId(reminder.id);
      final scheduledTz =
          tz.TZDateTime.from(reminder.reminderDateTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: AppColors.darkBlue,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      // Privacy-conscious notification body:
      // Auto-generated reminders use generic text to avoid exposing
      // document names or investment details on the lock screen.
      final String notificationBody = switch (reminder.source) {
        ReminderSource.documentExpiry =>
          'A document expiry date is approaching.',
        ReminderSource.investmentDue =>
          'An investment payment is approaching.',
        ReminderSource.manual => reminder.title,
      };

      // FLN 22+ uses named parameters for zonedSchedule().
      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Second Brain',
        body: notificationBody,
        scheduledDate: scheduledTz,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: reminder.id,
      );
    } catch (e) {
      debugPrint('NotificationService scheduleReminder error: $e');
    }
  }

  /// Cancels any scheduled notification for the specified reminder ID.
  Future<void> cancelReminder(String reminderId) async {
    if (!_isInitialized) return;
    try {
      // FLN 22+ uses named parameter id: for cancel().
      await _notificationsPlugin.cancel(id: getNotificationId(reminderId));
    } catch (e) {
      debugPrint('NotificationService cancelReminder error: $e');
    }
  }

  /// Cancels the existing notification and reschedules the new one if eligible.
  Future<void> rescheduleReminder(Reminder reminder) async {
    await cancelReminder(reminder.id);
    if (!reminder.isCompleted &&
        reminder.reminderDateTime.isAfter(DateTime.now())) {
      await scheduleReminder(reminder);
    }
  }

  /// Cancels all scheduled reminder notifications.
  Future<void> cancelAllReminderNotifications() async {
    if (!_isInitialized) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService cancelAllReminderNotifications error: $e');
    }
  }

  /// Handles notification tap and navigates directly to ReminderDetailScreen.
  void _handleNotificationTap(String reminderId) {
    final nav = _navigatorKey?.currentState;
    if (nav != null) {
      nav.push(
        MaterialPageRoute(
          builder: (_) => ReminderDetailScreen(
            reminderId: reminderId,
          ),
        ),
      );
    }
  }
}
