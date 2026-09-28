import 'package:second_brain/features/reminders/models/reminder.dart';

/// Pure status derivation function.
///
/// Rules:
/// - Completed: isCompleted == true
/// - Due Today: !isCompleted && reminder falls on today's calendar date
/// - Overdue: !isCompleted && reminder date/time is before today's calendar date
/// - Upcoming: !isCompleted && reminder date/time is after today's calendar date
ReminderStatus deriveReminderStatus({
  required DateTime reminderDateTime,
  required bool isCompleted,
  DateTime? now,
}) {
  if (isCompleted) {
    return ReminderStatus.completed;
  }

  final current = now ?? DateTime.now();
  final startOfToday = DateTime(current.year, current.month, current.day);
  final endOfToday = DateTime(current.year, current.month, current.day, 23, 59, 59, 999);

  if (reminderDateTime.isBefore(startOfToday)) {
    return ReminderStatus.overdue;
  }

  if (reminderDateTime.isAfter(endOfToday)) {
    return ReminderStatus.upcoming;
  }

  return ReminderStatus.dueToday;
}

/// Formats a DateTime into a clean, human-readable date/time string.
///
/// Examples:
/// - "Today • 6:00 PM"
/// - "Tomorrow • 10:00 AM"
/// - "Yesterday • 3:30 PM"
/// - "18 Oct 2026 • 10:00 AM"
/// - "15 Sep 2026" (if time is exactly 00:00:00)
String formatReminderDateTime(DateTime dateTime, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final startOfToday = DateTime(current.year, current.month, current.day);
  final startOfTomorrow = startOfToday.add(const Duration(days: 1));
  final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
  final startOfTarget = DateTime(dateTime.year, dateTime.month, dateTime.day);

  final bool hasTime = !(dateTime.hour == 0 && dateTime.minute == 0 && dateTime.second == 0);
  final String timeStr = hasTime ? _formatTime(dateTime) : '';

  if (startOfTarget.isAtSameMomentAs(startOfToday)) {
    return hasTime ? 'Today • $timeStr' : 'Today';
  } else if (startOfTarget.isAtSameMomentAs(startOfTomorrow)) {
    return hasTime ? 'Tomorrow • $timeStr' : 'Tomorrow';
  } else if (startOfTarget.isAtSameMomentAs(startOfYesterday)) {
    return hasTime ? 'Yesterday • $timeStr' : 'Yesterday';
  }

  final dateStr = '${dateTime.day} ${_monthName(dateTime.month)} ${dateTime.year}';
  return hasTime ? '$dateStr • $timeStr' : dateStr;
}

String _formatTime(DateTime dateTime) {
  final int hour = dateTime.hour;
  final int minute = dateTime.minute;
  final String period = hour >= 12 ? 'PM' : 'AM';
  final int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final String minuteStr = minute.toString().padLeft(2, '0');
  return '$displayHour:$minuteStr $period';
}

String _monthName(int month) {
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
  if (month >= 1 && month <= 12) {
    return months[month - 1];
  }
  return '';
}
