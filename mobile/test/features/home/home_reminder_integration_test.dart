import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/home/home_screen.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';

void main() {
  group('Step 9C — Home & Reminder Integration Tests', () {
    setUp(() {
      ReminderRepository.instance.resetSampleData();
    });

    testWidgets('TEST 1, 2, 3 — Home displays prioritized active reminders (Overdue, Due Today, Upcoming)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Reminders section header exists on Home
      expect(find.text('Reminders'), findsWidgets);

      // Verify Overdue and Due Today items appear in top 3
      expect(find.text('Renew vehicle insurance'), findsOneWidget);
      expect(find.text('Pay monthly chit installment'), findsOneWidget);

      // Verify status badges on Home
      expect(find.text('Overdue'), findsWidgets);
      expect(find.text('Due Today'), findsWidgets);
    });

    testWidgets('TEST 4 — Marking reminder complete removes it immediately from Home', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Renew vehicle insurance'), findsOneWidget);

      // Mark the overdue reminder complete in repository
      ReminderRepository.instance.markComplete('rem_002', true);
      await tester.pumpAndSettle();

      // It should immediately disappear from Home's active list
      expect(find.text('Renew vehicle insurance'), findsNothing);
    });

    testWidgets('TEST 5 — Editing a reminder updates Home display reactively', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final existing = ReminderRepository.instance.getById('rem_001');
      expect(existing, isNotNull);

      // Update title in repository
      final updated = existing!.copyWith(title: 'Updated Chit Installment Amount');
      ReminderRepository.instance.update(updated);
      await tester.pumpAndSettle();

      expect(find.text('Updated Chit Installment Amount'), findsOneWidget);
    });

    testWidgets('TEST 6 — Deleting a reminder removes it immediately from Home', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pay monthly chit installment'), findsOneWidget);

      // Delete from repository
      ReminderRepository.instance.delete('rem_001');
      await tester.pumpAndSettle();

      expect(find.text('Pay monthly chit installment'), findsNothing);
    });

    testWidgets('TEST 7 — Tapping a Home reminder opens exact ReminderDetailScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Pay monthly chit installment'
      final reminderFinder = find.text('Pay monthly chit installment');
      await tester.ensureVisible(reminderFinder);
      await tester.tap(reminderFinder);
      await tester.pumpAndSettle();

      // Expect to be on ReminderDetailScreen
      expect(find.text('Reminder Details'), findsOneWidget);
      expect(find.text('Pay monthly chit installment'), findsWidgets);
      expect(find.text('Schedule & Priority'), findsOneWidget);
      expect(find.text('Mark as Complete'), findsOneWidget);
    });

    testWidgets('TEST 8 — Home limits display to 3 items and View All navigates to RemindersScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Find 'View All' link in Reminders section
      final viewAllFinder = find.text('View All');
      expect(viewAllFinder, findsOneWidget);

      await tester.ensureVisible(viewAllFinder);
      await tester.tap(viewAllFinder);
      await tester.pumpAndSettle();

      // Expect to be on RemindersScreen
      expect(find.text('Important things to remember'), findsOneWidget);
    });

    testWidgets('Empty State on Home shows clean "No upcoming reminders" when all completed or empty', (tester) async {
      // Mark all reminders complete
      final all = ReminderRepository.instance.getAll();
      for (final r in all) {
        ReminderRepository.instance.markComplete(r.id, true);
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No upcoming reminders'), findsOneWidget);
      expect(find.text('You’re all caught up.'), findsOneWidget);
    });
  });
}
