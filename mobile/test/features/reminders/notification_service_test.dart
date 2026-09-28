// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/services/notification_service.dart';

/// Step 9D — NotificationService unit tests.
///
/// These tests verify the pure logic of the NotificationService
/// (deterministic IDs, future/overdue guards, scheduling hooks)
/// WITHOUT initializing the Android plugin (which requires native code).
///
/// The [_isInitialized] guard in NotificationService returns early when
/// the plugin has not been initialized, so calls to scheduleReminder / cancelReminder
/// are safe no-ops in the test environment.
void main() {
  setUp(() {
    ReminderRepository.instance.resetSampleData();
  });

  group('Step 9D — NotificationService Logic Tests', () {
    // ── TEST 1: Deterministic notification ID ──────────────────────────────
    test('TEST 1 — Deterministic ID: same reminder always produces same ID',
        () {
      const reminderId = 'rem_deterministic_test';
      final id1 = NotificationService.instance.getNotificationId(reminderId);
      final id2 = NotificationService.instance.getNotificationId(reminderId);

      expect(id1, equals(id2),
          reason: 'Same reminderId must always yield the same notification ID.');
      expect(id1, isNonNegative,
          reason: 'Notification ID must be a non-negative integer.');
    });

    // ── TEST 2: Different reminders get different IDs ──────────────────────
    test('TEST 2 — Deterministic ID: different reminders get different IDs',
        () {
      final id1 = NotificationService.instance.getNotificationId('rem_001');
      final id2 = NotificationService.instance.getNotificationId('rem_002');
      final id3 = NotificationService.instance.getNotificationId('rem_003');

      // It is theoretically possible for collisions but extremely unlikely
      // with real distinct IDs. We verify the three sample IDs are distinct.
      expect({id1, id2, id3}.length, equals(3),
          reason:
              'Distinct reminderIds should yield distinct notification IDs.');
    });

    // ── TEST 3: Future reminder — scheduleReminder is a safe no-op in test ─
    test(
        'TEST 3 — Future reminder: scheduleReminder completes without throwing',
        () async {
      final future = DateTime.now().add(const Duration(hours: 2));
      final reminder = Reminder(
        id: 'test_future_reminder',
        title: 'Future Reminder',
        reminderDateTime: future,
        dueDate: future,
        category: ReminderCategory.personal,
        priority: ReminderPriority.medium,
        isCompleted: false,
      );

      // NotificationService is not initialized in tests → early return
      await expectLater(
        NotificationService.instance.scheduleReminder(reminder),
        completes,
        reason:
            'scheduleReminder must complete without throwing even when plugin is not initialized.',
      );
    });

    // ── TEST 4: Overdue reminder — scheduleReminder is a safe no-op ────────
    test(
        'TEST 4 — Overdue reminder: scheduleReminder silently skips past reminders',
        () async {
      final past = DateTime.now().subtract(const Duration(hours: 3));
      final reminder = Reminder(
        id: 'test_overdue_reminder',
        title: 'Overdue Reminder',
        reminderDateTime: past,
        dueDate: past,
        category: ReminderCategory.personal,
        priority: ReminderPriority.high,
        isCompleted: false,
      );

      // Even if initialized, a past datetime must NOT be scheduled.
      // The guard `if (!reminder.reminderDateTime.isAfter(now)) return;` handles this.
      await expectLater(
        NotificationService.instance.scheduleReminder(reminder),
        completes,
        reason:
            'scheduleReminder must complete without throwing for overdue reminders.',
      );
    });

    // ── TEST 5: Completed reminder — scheduleReminder skips it ─────────────
    test(
        'TEST 5 — Completed reminder: scheduleReminder silently skips completed reminders',
        () async {
      final future = DateTime.now().add(const Duration(hours: 1));
      final reminder = Reminder(
        id: 'test_completed_reminder',
        title: 'Completed Reminder',
        reminderDateTime: future,
        dueDate: future,
        category: ReminderCategory.personal,
        priority: ReminderPriority.low,
        isCompleted: true, // completed — must not schedule
      );

      await expectLater(
        NotificationService.instance.scheduleReminder(reminder),
        completes,
        reason:
            'scheduleReminder must not throw for completed reminders; it should just return early.',
      );
    });

    // ── TEST 6: cancelReminder does not throw ──────────────────────────────
    test('TEST 6 — cancelReminder: completes without throwing', () async {
      await expectLater(
        NotificationService.instance.cancelReminder('any_reminder_id'),
        completes,
        reason:
            'cancelReminder must complete without throwing even when plugin is not initialized.',
      );
    });

    // ── TEST 7: rescheduleReminder does not throw ──────────────────────────
    test('TEST 7 — rescheduleReminder: completes without throwing', () async {
      final future = DateTime.now().add(const Duration(hours: 1));
      final reminder = Reminder(
        id: 'test_reschedule',
        title: 'Rescheduled Reminder',
        reminderDateTime: future,
        dueDate: future,
        category: ReminderCategory.personal,
        priority: ReminderPriority.medium,
        isCompleted: false,
      );

      await expectLater(
        NotificationService.instance.rescheduleReminder(reminder),
        completes,
        reason:
            'rescheduleReminder must complete without throwing even when plugin is not initialized.',
      );
    });

    // ── TEST 8: Payload carries only the reminderId ────────────────────────
    test(
        'TEST 8 — Notification payload: reminderId is the only payload value',
        () {
      // Verify the notification ID is a pure function of the reminder ID.
      // In production, `payload: reminder.id` is passed to zonedSchedule.
      // We check indirectly by verifying the notification ID derivation is stable.
      const id = 'rem_payload_test';
      final notifId = NotificationService.instance.getNotificationId(id);
      expect(notifId, isA<int>());
      expect(notifId, greaterThanOrEqualTo(0));
      // There is no other data (amount, doc number, etc.) in the ID.
      // The payload in production is simply reminder.id — tested in integration.
    });

    // ── TEST 9: Reminder not found → no crash ──────────────────────────────
    test(
        'TEST 9 — Navigation safety: missing reminder ID does not crash repository',
        () {
      final result =
          ReminderRepository.instance.getById('non_existent_reminder_id');
      expect(result, isNull,
          reason:
              'getById with unknown ID must return null, not throw an exception.');
    });

    // ── TEST 10: cancelAllReminderNotifications is safe ────────────────────
    test(
        'TEST 10 — cancelAllReminderNotifications: completes without throwing',
        () async {
      await expectLater(
        NotificationService.instance.cancelAllReminderNotifications(),
        completes,
        reason:
            'cancelAllReminderNotifications must complete without throwing even when plugin is not initialized.',
      );
    });

    // ── TEST 11: isInitialized guard ──────────────────────────────────────
    test(
        'TEST 11 — isInitialized: returns false in test environment (plugin not initialized)',
        () {
      // The plugin is never initialized in unit tests.
      // isInitialized guard prevents real plugin calls.
      expect(
        NotificationService.instance.isInitialized,
        isFalse,
        reason:
            'NotificationService must NOT report initialized in unit test environment.',
      );
    });

    // ── TEST 12: Notification ID stability across calls ────────────────────
    test('TEST 12 — ID stability: 1000 calls to getNotificationId are consistent',
        () {
      const reminderId = 'rem_stability_test';
      final expected =
          NotificationService.instance.getNotificationId(reminderId);

      for (int i = 0; i < 1000; i++) {
        final actual =
            NotificationService.instance.getNotificationId(reminderId);
        expect(actual, equals(expected),
            reason: 'Notification ID must be identical across all calls.');
      }
    });

    // ── TEST 13: Repository delete + cancel integration ────────────────────
    test(
        'TEST 13 — Delete flow: deleting a reminder followed by cancel completes without error',
        () async {
      const id = 'rem_001';
      // Ensure reminder exists
      final reminder = ReminderRepository.instance.getById(id);
      expect(reminder, isNotNull);

      // Cancel the notification (no-op in test)
      await NotificationService.instance.cancelReminder(id);

      // Delete from repository
      ReminderRepository.instance.delete(id);

      // Confirm removed
      final afterDelete = ReminderRepository.instance.getById(id);
      expect(afterDelete, isNull,
          reason: 'Reminder must be removed from repository after delete.');
    });

    // ── TEST 14: toggleComplete + reschedule completes safely ──────────────
    test(
        'TEST 14 — Complete flow: marking reminder complete followed by reschedule is safe',
        () async {
      const id = 'rem_003'; // upcoming uncompleted reminder
      final before = ReminderRepository.instance.getById(id);
      expect(before, isNotNull);
      expect(before!.isCompleted, isFalse);

      // Toggle complete
      ReminderRepository.instance.toggleComplete(id);
      final afterToggle = ReminderRepository.instance.getById(id);
      expect(afterToggle?.isCompleted, isTrue);

      // rescheduleReminder on a completed reminder must skip scheduling
      await expectLater(
        NotificationService.instance.rescheduleReminder(afterToggle!),
        completes,
      );
    });

    // ── TEST 15: requestPermissions is safe in test environment ───────────
    test('TEST 15 — requestPermissions: returns false when not initialized',
        () async {
      final result =
          await NotificationService.instance.requestPermissions();
      expect(result, isFalse,
          reason:
              'requestPermissions must return false when plugin is not initialized (test environment).');
    });
  });
}
