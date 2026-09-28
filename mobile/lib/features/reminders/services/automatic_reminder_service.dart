import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/logic/document_status.dart';
import 'package:second_brain/features/documents/models/document.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/investments/logic/investment_status.dart';
import 'package:second_brain/features/investments/models/investment.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/services/notification_service.dart';

/// Central domain service responsible for generating, synchronizing, and cleaning
/// system-derived reminders from Documents (expiry) and Investments (next due date).
///
/// Follows strict architecture constraints:
/// - ReminderRepository remains the single source of truth for reminder records.
/// - NotificationService schedules and cancels local notifications.
/// - Never modifies or removes manual reminders.
/// - Fully idempotent: running multiple times does not produce duplicate reminders.
class AutomaticReminderService {
  final ReminderRepository _reminderRepo;
  final DocumentRepository _documentRepo;
  final InvestmentRepository _investmentRepo;
  final NotificationService _notificationService;

  AutomaticReminderService._internal({
    ReminderRepository? reminderRepo,
    DocumentRepository? documentRepo,
    InvestmentRepository? investmentRepo,
    NotificationService? notificationService,
  })  : _reminderRepo = reminderRepo ?? ReminderRepository.instance,
        _documentRepo = documentRepo ?? DocumentRepository.instance,
        _investmentRepo = investmentRepo ?? InvestmentRepository.instance,
        _notificationService =
            notificationService ?? NotificationService.instance;

  static final AutomaticReminderService instance =
      AutomaticReminderService._internal();

  /// Factory for testing with injected dependencies.
  factory AutomaticReminderService.forTest({
    required ReminderRepository reminderRepo,
    required DocumentRepository documentRepo,
    required InvestmentRepository investmentRepo,
    required NotificationService notificationService,
  }) {
    return AutomaticReminderService._internal(
      reminderRepo: reminderRepo,
      documentRepo: documentRepo,
      investmentRepo: investmentRepo,
      notificationService: notificationService,
    );
  }

  /// Prefix format for deterministic reminder IDs.
  static String documentReminderId(String documentId) => 'auto_doc_$documentId';
  static String investmentReminderId(String investmentId) =>
      'auto_inv_$investmentId';

  /// Primary synchronization method.
  ///
  /// Reconciles all active documents and investments with ReminderRepository.
  /// Safe to call repeatedly without creating duplicate entries.
  Future<void> syncAutomaticReminders({DateTime? now}) async {
    try {
      final currentNow = now ?? DateTime.now();
      final today = DateTime(
        currentNow.year,
        currentNow.month,
        currentNow.day,
      );

      // 1. Calculate required document expiry reminders.
      final requiredReminders = <String, Reminder>{};

      final documents = _documentRepo.getDocuments();
      for (final doc in documents) {
        final reminder = _buildDocumentReminder(doc, currentNow, today);
        if (reminder != null) {
          requiredReminders[reminder.id] = reminder;
        }
      }

      // 2. Calculate required investment due reminders.
      final investments = _investmentRepo.getInvestments();
      for (final inv in investments) {
        final reminder = _buildInvestmentReminder(inv, currentNow, today);
        if (reminder != null) {
          requiredReminders[reminder.id] = reminder;
        }
      }

      // 3. Find existing generated reminders in the repository.
      final existingReminders = _reminderRepo
          .getAll()
          .where((r) => r.source != ReminderSource.manual)
          .toList();

      // 4. Create or update required reminders.
      for (final required in requiredReminders.values) {
        final existing = _reminderRepo.getById(required.id);

        if (existing == null) {
          // New reminder needed.
          _reminderRepo.add(required);
          await _notificationService.scheduleReminder(required);
        } else {
          // Check if any fields changed. Preserve user-toggled completion if date is same.
          final isSameDate = existing.dueDate == required.dueDate &&
              existing.reminderDateTime == required.reminderDateTime;

          final shouldUpdate = existing.title != required.title ||
              existing.description != required.description ||
              !isSameDate;

          if (shouldUpdate) {
            final updated = required.copyWith(
              isCompleted: isSameDate ? existing.isCompleted : false,
            );
            _reminderRepo.update(updated);
            await _notificationService.rescheduleReminder(updated);
          }
        }
      }

      // 5. Remove stale generated reminders that are no longer required.
      // (e.g., document deleted, expiry moved out of warning period, investment completed).
      for (final existing in existingReminders) {
        if (!requiredReminders.containsKey(existing.id)) {
          await _notificationService.cancelReminder(existing.id);
          _reminderRepo.delete(existing.id);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('AutomaticReminderService sync error: $e\n$stackTrace');
      // Synchronization failure must never crash the caller.
    }
  }

  /// Builds a deterministic document expiry reminder if eligible.
  Reminder? _buildDocumentReminder(
    Document doc,
    DateTime now,
    DateTime today,
  ) {
    if (doc.expiryDate == null) return null;

    final status = deriveDocumentStatus(expiryDate: doc.expiryDate);
    // Only documents entering the configured warning period (Expiring Soon)
    // receive an automatic reminder. Expired documents or distant documents do not.
    if (status != DocumentStatus.expiringSoon) return null;

    final expiryDate = doc.expiryDate!;
    final expiryDateOnly =
        DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    // If expiry date has already passed today's calendar date, do not schedule.
    if (expiryDateOnly.isBefore(today)) return null;

    final reminderDateTime = _calculateReminderDateTime(
      expiryDateOnly,
      now,
      today,
    );

    final formattedDate = DateFormat('dd MMM yyyy').format(expiryDate);

    return Reminder(
      id: documentReminderId(doc.id),
      title: '${doc.title} expiry',
      description: 'Document expires on $formattedDate',
      dueDate: expiryDateOnly,
      reminderDateTime: reminderDateTime,
      category: ReminderCategory.document,
      priority: ReminderPriority.high,
      source: ReminderSource.documentExpiry,
      linkedEntityType: 'document',
      linkedEntityId: doc.id,
      isCompleted: false,
    );
  }

  /// Builds a deterministic investment due reminder if eligible.
  Reminder? _buildInvestmentReminder(
    Investment inv,
    DateTime now,
    DateTime today,
  ) {
    if (inv.nextDueDate == null) return null;

    final status = deriveStatus(
      installmentsPaid: inv.installmentsPaid,
      totalInstallments: inv.totalInstallments,
      nextDueDate: inv.nextDueDate,
    );

    // Completed investments receive no reminders.
    if (status == InvestmentStatus.completed) return null;

    final dueDate = inv.nextDueDate!;
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    // If next due date is in the past (overdue), do not schedule a future reminder.
    if (dueDateOnly.isBefore(today)) return null;

    final reminderDateTime = _calculateReminderDateTime(
      dueDateOnly,
      now,
      today,
    );

    final formattedDate = DateFormat('dd MMM yyyy').format(dueDate);

    return Reminder(
      id: investmentReminderId(inv.id),
      title: '${inv.name} payment due',
      description: 'Next installment due on $formattedDate',
      dueDate: dueDateOnly,
      reminderDateTime: reminderDateTime,
      category: ReminderCategory.investment,
      priority: status == InvestmentStatus.dueSoon
          ? ReminderPriority.high
          : ReminderPriority.medium,
      source: ReminderSource.investmentDue,
      linkedEntityType: 'investment',
      linkedEntityId: inv.id,
      isCompleted: false,
    );
  }

  /// Calculates the target reminder time for a given calendar date.
  ///
  /// Defaults to 9:00 AM on that date. If the date is today and 9:00 AM has
  /// already passed, schedules for 2 minutes from now to allow physical device testing.
  DateTime _calculateReminderDateTime(
    DateTime dateOnly,
    DateTime now,
    DateTime today,
  ) {
    if (dateOnly.isAtSameMomentAs(today)) {
      final defaultNineAm = DateTime(today.year, today.month, today.day, 9, 0);
      if (defaultNineAm.isAfter(now)) {
        return defaultNineAm;
      }
      return now.add(const Duration(minutes: 2));
    }
    return DateTime(dateOnly.year, dateOnly.month, dateOnly.day, 9, 0);
  }

  /// Synchronizes a specific document after add or update.
  Future<void> syncDocument(Document doc) async {
    await syncAutomaticReminders();
  }

  /// Removes an auto-generated reminder when a document is deleted.
  Future<void> removeDocumentReminder(String documentId) async {
    try {
      final remId = documentReminderId(documentId);
      _reminderRepo.delete(remId);
      await _notificationService.cancelReminder(remId);
    } catch (e) {
      debugPrint('Error removing document reminder: $e');
    }
  }

  /// Synchronizes a specific investment after add or update.
  Future<void> syncInvestment(Investment inv) async {
    await syncAutomaticReminders();
  }

  /// Removes an auto-generated reminder when an investment is deleted.
  Future<void> removeInvestmentReminder(String investmentId) async {
    try {
      final remId = investmentReminderId(investmentId);
      _reminderRepo.delete(remId);
      await _notificationService.cancelReminder(remId);
    } catch (e) {
      debugPrint('Error removing investment reminder: $e');
    }
  }
}
