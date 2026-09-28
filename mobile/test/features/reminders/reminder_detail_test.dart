import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/reminder_detail_screen.dart';
import 'package:second_brain/features/reminders/reminders_screen.dart';

void main() {
  group('Step 9B — Reminder Detail & Actions Tests', () {
    setUp(() {
      ReminderRepository.instance.resetSampleData();
    });

    testWidgets('renders ReminderDetailScreen with complete fields and derived status', (tester) async {
      final reminder = Reminder(
        id: 'detail_test_1',
        title: 'Renew Passport Insurance',
        description: 'Complete policy documents',
        category: ReminderCategory.document,
        priority: ReminderPriority.high,
        reminderDateTime: DateTime(2027, 5, 20, 14, 30),
      );
      ReminderRepository.instance.add(reminder);

      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailScreen(reminderId: reminder.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reminder Details'), findsOneWidget);
      expect(find.text('Renew Passport Insurance'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Complete policy documents'), findsOneWidget);
      expect(find.text('20 May 2027'), findsOneWidget);
      expect(find.text('2:30 PM'), findsOneWidget);
      expect(find.text('Mark as Complete'), findsOneWidget);
    });

    testWidgets('tapping Mark as Complete toggles reminder completion reactively', (tester) async {
      final reminder = Reminder(
        id: 'detail_test_2',
        title: 'Electricity Bill',
        category: ReminderCategory.personal,
        reminderDateTime: DateTime(2027, 6, 1, 10, 0),
        isCompleted: false,
      );
      ReminderRepository.instance.add(reminder);

      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailScreen(reminderId: reminder.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark as Complete'), findsOneWidget);

      await tester.tap(find.text('Mark as Complete'));
      await tester.pumpAndSettle();

      expect(find.text('Mark as Incomplete'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      final repoDoc = ReminderRepository.instance.getById('detail_test_2');
      expect(repoDoc?.isCompleted, isTrue);
    });

    testWidgets('Delete reminder shows confirmation dialog and cancels without deleting', (tester) async {
      final reminder = Reminder(
        id: 'detail_test_3',
        title: 'Delete Cancel Test',
        reminderDateTime: DateTime(2027, 7, 1),
      );
      ReminderRepository.instance.add(reminder);

      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailScreen(reminderId: reminder.id),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete action in appbar
      await tester.tap(find.byTooltip('Delete Reminder'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Reminder?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this reminder?'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(ReminderRepository.instance.getById('detail_test_3'), isNotNull);
    });

    testWidgets('Delete reminder confirms and removes reminder from repository', (tester) async {
      final reminder = Reminder(
        id: 'detail_test_4',
        title: 'Delete Confirm Test',
        reminderDateTime: DateTime(2027, 7, 1),
      );
      ReminderRepository.instance.add(reminder);

      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailScreen(reminderId: reminder.id),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete action in appbar
      await tester.tap(find.byTooltip('Delete Reminder'));
      await tester.pumpAndSettle();

      // Tap Delete confirmation
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(ReminderRepository.instance.getById('detail_test_4'), isNull);
    });

    testWidgets('tapping reminder item in RemindersScreen navigates to ReminderDetailScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RemindersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap an item (e.g. Renew vehicle insurance)
      final itemFinder = find.text('Renew vehicle insurance');
      await tester.ensureVisible(itemFinder);
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      expect(find.text('Reminder Details'), findsOneWidget);
      expect(find.text('Renew vehicle insurance'), findsWidgets);
      expect(find.text('Schedule & Priority'), findsOneWidget);
    });
  });
}
