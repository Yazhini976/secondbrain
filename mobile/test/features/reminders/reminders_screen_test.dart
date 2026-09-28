import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/home/home_screen.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/reminders_screen.dart';

void main() {
  group('Step 9A — RemindersScreen Widget Tests', () {
    setUp(() {
      ReminderRepository.instance.resetSampleData();
    });

    testWidgets('renders Reminders screen header, subtitle, sections, and items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RemindersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Important things to remember'), findsOneWidget);

      // Verify sections are visible
      expect(find.text('Due Today'), findsWidgets);
      expect(find.text('Overdue'), findsWidgets);
      expect(find.text('Upcoming'), findsWidgets);

      // Verify sample reminder titles
      expect(find.text('Pay monthly chit installment'), findsOneWidget);
      expect(find.text('Renew vehicle insurance'), findsOneWidget);
      expect(find.text('Call service center'), findsOneWidget);

      // Scroll to Completed section item
      await tester.scrollUntilVisible(find.text('Submit college document'), 100);
      expect(find.text('Submit college document'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
    });

    testWidgets('tapping completion checkbox updates reminder and moves it to Completed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RemindersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify overdue reminder (first in list) is not completed initially
      final overdueReminder = ReminderRepository.instance
          .getAll()
          .firstWhere((r) => r.id == 'rem_002');
      expect(overdueReminder.isCompleted, false);

      // Find the toggle semantics button for marking complete
      final completeButton = find.bySemanticsLabel('Mark reminder as complete').first;
      await tester.tap(completeButton);
      await tester.pumpAndSettle();

      // Verify repo updated
      final updatedReminder = ReminderRepository.instance.getById('rem_002');
      expect(updatedReminder?.isCompleted, true);
    });

    testWidgets('renders empty state when no reminders exist', (tester) async {
      // Clear all reminders
      final all = List<Reminder>.from(ReminderRepository.instance.getAll());
      for (final r in all) {
        ReminderRepository.instance.delete(r.id);
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: RemindersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No reminders yet'), findsOneWidget);
      expect(
        find.text('Add reminders for important dates and tasks.'),
        findsOneWidget,
      );
    });

    testWidgets('navigating to Reminders from Home header works smoothly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the reminders notification icon in header
      final notificationIcon = find.byIcon(Icons.notifications_outlined);
      expect(notificationIcon, findsOneWidget);
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();

      // Should be on Reminders screen
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Important things to remember'), findsOneWidget);
    });
  });
}
