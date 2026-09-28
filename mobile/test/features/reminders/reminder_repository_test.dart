import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/logic/reminder_service.dart';
import 'package:second_brain/features/reminders/logic/reminder_status.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';

void main() {
  group('Step 9A — Reminder Model & Logic Tests', () {
    final fixedNow = DateTime(2026, 9, 28, 12, 0);

    test('deriveReminderStatus returns completed when isCompleted is true', () {
      final status = deriveReminderStatus(
        reminderDateTime: fixedNow.subtract(const Duration(days: 2)),
        isCompleted: true,
        now: fixedNow,
      );
      expect(status, ReminderStatus.completed);
      expect(status.displayName, 'Completed');
    });

    test('deriveReminderStatus returns dueToday when date is today and uncompleted', () {
      final status = deriveReminderStatus(
        reminderDateTime: DateTime(2026, 9, 28, 18, 30),
        isCompleted: false,
        now: fixedNow,
      );
      expect(status, ReminderStatus.dueToday);
      expect(status.displayName, 'Due Today');
    });

    test('deriveReminderStatus returns overdue when date is in the past and uncompleted', () {
      final status = deriveReminderStatus(
        reminderDateTime: DateTime(2026, 9, 25, 10, 0),
        isCompleted: false,
        now: fixedNow,
      );
      expect(status, ReminderStatus.overdue);
      expect(status.displayName, 'Overdue');
    });

    test('deriveReminderStatus returns upcoming when date is in the future and uncompleted', () {
      final status = deriveReminderStatus(
        reminderDateTime: DateTime(2026, 10, 5, 14, 0),
        isCompleted: false,
        now: fixedNow,
      );
      expect(status, ReminderStatus.upcoming);
      expect(status.displayName, 'Upcoming');
    });

    test('formatReminderDateTime formats correctly for Today, Tomorrow, Yesterday, and specific dates', () {
      expect(
        formatReminderDateTime(DateTime(2026, 9, 28, 18, 0), now: fixedNow),
        'Today • 6:00 PM',
      );
      expect(
        formatReminderDateTime(DateTime(2026, 9, 29, 9, 30), now: fixedNow),
        'Tomorrow • 9:30 AM',
      );
      expect(
        formatReminderDateTime(DateTime(2026, 9, 27, 15, 0), now: fixedNow),
        'Yesterday • 3:00 PM',
      );
      expect(
        formatReminderDateTime(DateTime(2026, 10, 18, 10, 0), now: fixedNow),
        '18 Oct 2026 • 10:00 AM',
      );
    });

    test('ReminderService separates reminders into respective sections and sorts properly', () {
      final reminders = [
        Reminder(
          id: '1',
          title: 'Upcoming later',
          reminderDateTime: DateTime(2026, 10, 10),
          isCompleted: false,
        ),
        Reminder(
          id: '2',
          title: 'Upcoming sooner',
          reminderDateTime: DateTime(2026, 10, 2),
          isCompleted: false,
        ),
        Reminder(
          id: '3',
          title: 'Due today',
          reminderDateTime: DateTime(2026, 9, 28, 15, 0),
          isCompleted: false,
        ),
        Reminder(
          id: '4',
          title: 'Overdue older',
          reminderDateTime: DateTime(2026, 9, 20),
          isCompleted: false,
        ),
        Reminder(
          id: '5',
          title: 'Completed item',
          reminderDateTime: DateTime(2026, 9, 27),
          isCompleted: true,
        ),
      ];

      final overdue = ReminderService.getOverdueReminders(reminders, now: fixedNow);
      final dueToday = ReminderService.getDueTodayReminders(reminders, now: fixedNow);
      final upcoming = ReminderService.getUpcomingReminders(reminders, now: fixedNow);
      final completed = ReminderService.getCompletedReminders(reminders, now: fixedNow);

      expect(overdue.length, 1);
      expect(overdue.first.id, '4');

      expect(dueToday.length, 1);
      expect(dueToday.first.id, '3');

      expect(upcoming.length, 2);
      expect(upcoming.first.id, '2'); // Nearest first
      expect(upcoming.last.id, '1');

      expect(completed.length, 1);
      expect(completed.first.id, '5');
    });
  });

  group('Step 9A — ReminderRepository Tests', () {
    late ReminderRepository repository;

    setUp(() {
      repository = ReminderRepository.instance;
      repository.resetSampleData();
    });

    test('initializes with default sample reminders', () {
      final all = repository.getAll();
      expect(all.isNotEmpty, true);
      expect(all.any((r) => r.title.contains('chit installment')), true);
    });

    test('add, update, delete, and toggleComplete work reactively', () {
      int notifyCount = 0;
      repository.addListener(() => notifyCount++);

      final newReminder = Reminder(
        id: 'test_rem_1',
        title: 'Doctor appointment',
        reminderDateTime: DateTime(2026, 10, 1),
        category: ReminderCategory.personal,
        priority: ReminderPriority.high,
      );

      // Add
      repository.add(newReminder);
      expect(repository.getById('test_rem_1'), isNotNull);
      expect(notifyCount, 1);

      // Update
      final updated = newReminder.copyWith(title: 'Dentist appointment');
      repository.update(updated);
      expect(repository.getById('test_rem_1')?.title, 'Dentist appointment');
      expect(notifyCount, 2);

      // Toggle complete
      expect(repository.getById('test_rem_1')?.isCompleted, false);
      repository.toggleComplete('test_rem_1');
      expect(repository.getById('test_rem_1')?.isCompleted, true);
      expect(notifyCount, 3);

      // Delete
      repository.delete('test_rem_1');
      expect(repository.getById('test_rem_1'), isNull);
      expect(notifyCount, 4);
    });
  });
}
