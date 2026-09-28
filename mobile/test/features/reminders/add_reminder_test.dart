import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/reminders/add_reminder_screen.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';

void main() {
  group('Step 9B — Add & Edit Reminder Form Tests', () {
    setUp(() {
      ReminderRepository.instance.resetSampleData();
    });

    testWidgets('AddReminderScreen validates empty title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddReminderScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Reminder'), findsOneWidget);
      expect(find.text('Save Reminder'), findsOneWidget);

      // Tap Save without entering title
      await tester.tap(find.text('Save Reminder'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a reminder title'), findsOneWidget);
    });

    testWidgets('AddReminderScreen validates empty title and creates future reminder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddReminderScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter a valid title
      await tester.enterText(
        find.byType(TextFormField).first,
        'Future event reminder',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Reminder'));
      await tester.pumpAndSettle();

      final all = ReminderRepository.instance.getAll();
      expect(all.any((r) => r.title == 'Future event reminder'), isTrue);
    });

    testWidgets('AddReminderScreen creates and persists a valid new reminder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddReminderScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(
        find.widgetWithText(TextFormField, '').first,
        'Renew Passport Photo',
      );

      // Enter description
      await tester.enterText(
        find.widgetWithText(TextFormField, '').last,
        'Take 2 passport size photographs at studio',
      );

      // Select High Priority
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save Reminder'));
      await tester.pumpAndSettle();

      final created = ReminderRepository.instance
          .getAll()
          .firstWhere((r) => r.title == 'Renew Passport Photo');

      expect(created, isNotNull);
      expect(created.description, 'Take 2 passport size photographs at studio');
      expect(created.priority, ReminderPriority.high);
      expect(created.isCompleted, false);
    });

    testWidgets('Edit mode pre-populates fields and updates reminder without duplicate ID', (tester) async {
      final existingReminder = Reminder(
        id: 'edit_test_1',
        title: 'Original Title',
        description: 'Original Description',
        category: ReminderCategory.investment,
        priority: ReminderPriority.low,
        reminderDateTime: DateTime(2027, 1, 15, 10, 0),
        dueDate: DateTime(2027, 1, 15),
      );
      ReminderRepository.instance.add(existingReminder);

      await tester.pumpWidget(
        MaterialApp(
          home: AddReminderScreen(
            reminder: existingReminder,
            isEditMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Reminder'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Original Title'), findsOneWidget);
      expect(find.text('Original Description'), findsOneWidget);

      // Update title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Original Title'),
        'Updated Title',
      );

      // Change Priority to High
      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();

      // Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      final updated = ReminderRepository.instance.getById('edit_test_1');
      expect(updated, isNotNull);
      expect(updated?.title, 'Updated Title');
      expect(updated?.priority, ReminderPriority.high);
      expect(updated?.id, 'edit_test_1');
    });
  });
}
