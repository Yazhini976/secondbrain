import 'package:second_brain/features/reminders/logic/reminder_status.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';

/// Pure domain helper functions for the Reminder module.
/// Decouples business logic, sorting, and status grouping from UI widgets.
abstract final class ReminderService {
  /// Calculates the derived status for a given reminder.
  static ReminderStatus calculateReminderStatus(
    Reminder reminder, {
    DateTime? now,
  }) {
    return deriveReminderStatus(
      reminderDateTime: reminder.reminderDateTime,
      isCompleted: reminder.isCompleted,
      now: now,
    );
  }

  /// Filters overdue uncompleted reminders (before today).
  /// Sorted by earliest due date first.
  static List<Reminder> getOverdueReminders(
    List<Reminder> reminders, {
    DateTime? now,
  }) {
    return reminders
        .where((r) =>
            calculateReminderStatus(r, now: now) == ReminderStatus.overdue)
        .toList()
      ..sort((a, b) => a.reminderDateTime.compareTo(b.reminderDateTime));
  }

  /// Filters reminders due on today's calendar date.
  /// Sorted by earliest due date/time first.
  static List<Reminder> getDueTodayReminders(
    List<Reminder> reminders, {
    DateTime? now,
  }) {
    return reminders
        .where((r) =>
            calculateReminderStatus(r, now: now) == ReminderStatus.dueToday)
        .toList()
      ..sort((a, b) => a.reminderDateTime.compareTo(b.reminderDateTime));
  }

  /// Filters upcoming future reminders (after today).
  /// Sorted by nearest due date/time first.
  static List<Reminder> getUpcomingReminders(
    List<Reminder> reminders, {
    DateTime? now,
  }) {
    return reminders
        .where((r) =>
            calculateReminderStatus(r, now: now) == ReminderStatus.upcoming)
        .toList()
      ..sort((a, b) => a.reminderDateTime.compareTo(b.reminderDateTime));
  }

  /// Filters completed reminders.
  /// Sorted by most recently updated/completed first.
  static List<Reminder> getCompletedReminders(
    List<Reminder> reminders, {
    DateTime? now,
  }) {
    return reminders
        .where((r) =>
            calculateReminderStatus(r, now: now) == ReminderStatus.completed)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Returns all active (uncompleted) reminders sorted in sequence:
  /// Overdue -> Due Today -> Upcoming (earliest first).
  static List<Reminder> sortActiveReminders(
    List<Reminder> reminders, {
    DateTime? now,
  }) {
    final overdue = getOverdueReminders(reminders, now: now);
    final dueToday = getDueTodayReminders(reminders, now: now);
    final upcoming = getUpcomingReminders(reminders, now: now);
    return [...overdue, ...dueToday, ...upcoming];
  }

  /// Returns top prioritized active reminders for Home display (default max 3).
  /// Order: Overdue -> Due Today -> Upcoming.
  static List<Reminder> getHomeReminders(
    List<Reminder> reminders, {
    int limit = 3,
    DateTime? now,
  }) {
    final active = sortActiveReminders(reminders, now: now);
    if (active.length <= limit) {
      return active;
    }
    return active.sublist(0, limit);
  }

  /// Total count of all reminders.
  static int totalCount(List<Reminder> reminders) => reminders.length;

  /// Count of active uncompleted reminders.
  static int activeCount(List<Reminder> reminders, {DateTime? now}) =>
      reminders.where((r) => !r.isCompleted).length;

  /// Count of overdue reminders.
  static int overdueCount(List<Reminder> reminders, {DateTime? now}) =>
      getOverdueReminders(reminders, now: now).length;

  /// Count of due today reminders.
  static int dueTodayCount(List<Reminder> reminders, {DateTime? now}) =>
      getDueTodayReminders(reminders, now: now).length;

  /// Count of upcoming reminders.
  static int upcomingCount(List<Reminder> reminders, {DateTime? now}) =>
      getUpcomingReminders(reminders, now: now).length;

  /// Count of completed reminders.
  static int completedCount(List<Reminder> reminders, {DateTime? now}) =>
      getCompletedReminders(reminders, now: now).length;
}
