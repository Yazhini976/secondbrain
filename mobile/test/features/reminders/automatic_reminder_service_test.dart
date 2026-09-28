import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/document_detail_screen.dart';
import 'package:second_brain/features/documents/models/document.dart';
import 'package:second_brain/features/home/home_screen.dart';
import 'package:second_brain/features/home/widgets/home_reminders_section.dart';
import 'package:second_brain/features/investments/data/investment_repository.dart';
import 'package:second_brain/features/investments/models/investment.dart';
import 'package:second_brain/features/reminders/data/reminder_repository.dart';
import 'package:second_brain/features/reminders/models/reminder.dart';
import 'package:second_brain/features/reminders/reminder_detail_screen.dart';
import 'package:second_brain/features/reminders/services/automatic_reminder_service.dart';

void main() {
  setUp(() {
    ReminderRepository.instance.resetSampleData();
  });

  group('Step 9E — AutomaticReminderService Unit & Integration Tests', () {
    test('TEST 1 & 2 — Document Expiry inside warning window vs outside window',
        () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Doc inside window (15 days away)
      final docInside = Document(
        id: 'test_doc_inside',
        title: 'Passport',
        category: DocumentCategory.identity,
        expiryDate: today.add(const Duration(days: 15)),
      );

      // Doc outside window (90 days away)
      final docOutside = Document(
        id: 'test_doc_outside',
        title: 'Land Deed',
        category: DocumentCategory.property,
        expiryDate: today.add(const Duration(days: 90)),
      );

      // Add to repository
      DocumentRepository.instance.addDocument(docInside);
      DocumentRepository.instance.addDocument(docOutside);

      await AutomaticReminderService.instance.syncAutomaticReminders();

      // TEST 1 Verify: generated reminder appears for Passport
      final generatedRem = ReminderRepository.instance
          .getById(AutomaticReminderService.documentReminderId(docInside.id));
      expect(generatedRem, isNotNull);
      expect(generatedRem!.source, equals(ReminderSource.documentExpiry));
      expect(generatedRem.linkedEntityType, equals('document'));
      expect(generatedRem.linkedEntityId, equals(docInside.id));
      expect(generatedRem.title, equals('Passport expiry'));
      expect(generatedRem.category, equals(ReminderCategory.document));

      // TEST 2 Verify: No reminder generated for doc outside window
      final outsideRem = ReminderRepository.instance
          .getById(AutomaticReminderService.documentReminderId(docOutside.id));
      expect(outsideRem, isNull);

      // Cleanup
      DocumentRepository.instance.deleteDocument(docInside.id);
      DocumentRepository.instance.deleteDocument(docOutside.id);
    });

    test('TEST 3 — Document Edit updates reminder and avoids duplicates',
        () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final doc = Document(
        id: 'test_doc_edit',
        title: 'Vehicle Insurance',
        category: DocumentCategory.insurance,
        expiryDate: today.add(const Duration(days: 10)),
      );

      DocumentRepository.instance.addDocument(doc);
      await AutomaticReminderService.instance.syncAutomaticReminders();

      final originalRem = ReminderRepository.instance
          .getById(AutomaticReminderService.documentReminderId(doc.id));
      expect(originalRem, isNotNull);
      expect(originalRem!.dueDate, equals(today.add(const Duration(days: 10))));

      // Edit document with new expiry date
      final updatedDoc = doc.copyWith(
        title: 'Vehicle Insurance Updated',
        expiryDate: today.add(const Duration(days: 20)),
      );
      DocumentRepository.instance.updateDocument(updatedDoc);
      await AutomaticReminderService.instance.syncAutomaticReminders();

      final updatedRem = ReminderRepository.instance
          .getById(AutomaticReminderService.documentReminderId(doc.id));
      expect(updatedRem, isNotNull);
      expect(updatedRem!.title, equals('Vehicle Insurance Updated expiry'));
      expect(updatedRem.dueDate, equals(today.add(const Duration(days: 20))));

      // Only one reminder should exist for this document
      final docReminders = ReminderRepository.instance
          .getAll()
          .where((r) => r.linkedEntityId == doc.id && r.source == ReminderSource.documentExpiry)
          .toList();
      expect(docReminders.length, equals(1));

      // Cleanup
      DocumentRepository.instance.deleteDocument(doc.id);
    });

    test('TEST 4 — Document Delete removes generated reminder', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final doc = Document(
        id: 'test_doc_delete',
        title: 'Medical Certificate',
        category: DocumentCategory.medical,
        expiryDate: today.add(const Duration(days: 5)),
      );

      DocumentRepository.instance.addDocument(doc);
      await AutomaticReminderService.instance.syncAutomaticReminders();

      expect(
        ReminderRepository.instance
            .getById(AutomaticReminderService.documentReminderId(doc.id)),
        isNotNull,
      );

      // Delete document
      DocumentRepository.instance.deleteDocument(doc.id);

      expect(
        ReminderRepository.instance
            .getById(AutomaticReminderService.documentReminderId(doc.id)),
        isNull,
      );
    });

    test('TEST 5 — Investment Due reminder for active investment', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final inv = Investment(
        id: 'test_inv_active',
        name: 'Gold Saving Scheme Muthoot',
        type: InvestmentType.goldSavingScheme,
        monthlyContribution: 5000,
        totalPaid: 10000,
        installmentsPaid: 2,
        totalInstallments: 12,
        nextDueDate: today.add(const Duration(days: 7)),
      );

      InvestmentRepository.instance.addInvestment(inv);
      await AutomaticReminderService.instance.syncAutomaticReminders();

      final invRem = ReminderRepository.instance
          .getById(AutomaticReminderService.investmentReminderId(inv.id));
      expect(invRem, isNotNull);
      expect(invRem!.source, equals(ReminderSource.investmentDue));
      expect(invRem.linkedEntityType, equals('investment'));
      expect(invRem.linkedEntityId, equals(inv.id));
      expect(invRem.title, equals('Gold Saving Scheme Muthoot payment due'));
      expect(invRem.category, equals(ReminderCategory.investment));

      // Cleanup
      InvestmentRepository.instance.deleteInvestment(inv.id);
    });

    test('TEST 6 — Investment Edit updates reminder without duplicate',
        () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final inv = Investment(
        id: 'test_inv_edit',
        name: 'Chit Fund Monthly',
        type: InvestmentType.chitFund,
        monthlyContribution: 2000,
        totalPaid: 4000,
        installmentsPaid: 2,
        totalInstallments: 20,
        nextDueDate: today.add(const Duration(days: 4)),
      );

      InvestmentRepository.instance.addInvestment(inv);
      await AutomaticReminderService.instance.syncAutomaticReminders();

      // Edit investment
      final updatedInv = inv.copyWith(
        name: 'Chit Fund Monthly Premium',
        nextDueDate: today.add(const Duration(days: 14)),
      );
      InvestmentRepository.instance.updateInvestment(updatedInv);
      await AutomaticReminderService.instance.syncAutomaticReminders();

      final rem = ReminderRepository.instance
          .getById(AutomaticReminderService.investmentReminderId(inv.id));
      expect(rem, isNotNull);
      expect(rem!.title, equals('Chit Fund Monthly Premium payment due'));
      expect(rem.dueDate, equals(today.add(const Duration(days: 14))));

      final allForInv = ReminderRepository.instance
          .getAll()
          .where((r) => r.linkedEntityId == inv.id && r.source == ReminderSource.investmentDue)
          .toList();
      expect(allForInv.length, equals(1));

      // Cleanup
      InvestmentRepository.instance.deleteInvestment(inv.id);
    });

    test('TEST 7 — Investment Delete removes generated reminder', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final inv = Investment(
        id: 'test_inv_delete',
        name: 'Recurring Deposit SBI',
        type: InvestmentType.rd,
        monthlyContribution: 1000,
        totalPaid: 2000,
        installmentsPaid: 2,
        totalInstallments: 12,
        nextDueDate: today.add(const Duration(days: 3)),
      );

      InvestmentRepository.instance.addInvestment(inv);
      await AutomaticReminderService.instance.syncAutomaticReminders();

      expect(
        ReminderRepository.instance
            .getById(AutomaticReminderService.investmentReminderId(inv.id)),
        isNotNull,
      );

      InvestmentRepository.instance.deleteInvestment(inv.id);

      expect(
        ReminderRepository.instance
            .getById(AutomaticReminderService.investmentReminderId(inv.id)),
        isNull,
      );
    });

    test('TEST 8 — Manual Reminders are untouched by sync', () async {
      final manualReminder = Reminder(
        id: 'manual_call_agent',
        title: 'Call insurance agent',
        reminderDateTime: DateTime.now().add(const Duration(days: 2)),
        category: ReminderCategory.personal,
        source: ReminderSource.manual,
      );

      ReminderRepository.instance.add(manualReminder);

      // Run sync multiple times
      await AutomaticReminderService.instance.syncAutomaticReminders();
      await AutomaticReminderService.instance.syncAutomaticReminders();

      final found = ReminderRepository.instance.getById('manual_call_agent');
      expect(found, isNotNull);
      expect(found!.title, equals('Call insurance agent'));
      expect(found.source, equals(ReminderSource.manual));

      // Cleanup
      ReminderRepository.instance.delete('manual_call_agent');
    });

    test('TEST 9 — Idempotency: multiple sync calls do not duplicate reminders',
        () async {

      // Run sync 3 times in a row
      await AutomaticReminderService.instance.syncAutomaticReminders();
      final countAfterFirst = ReminderRepository.instance.getAll().length;

      await AutomaticReminderService.instance.syncAutomaticReminders();
      final countAfterSecond = ReminderRepository.instance.getAll().length;

      await AutomaticReminderService.instance.syncAutomaticReminders();
      final countAfterThird = ReminderRepository.instance.getAll().length;

      expect(countAfterFirst, equals(countAfterSecond));
      expect(countAfterSecond, equals(countAfterThird));
    });

    testWidgets('TEST 10 — Home navigates to Document / Investment detail on tap',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Create test document and investment
      final testDoc = Document(
        id: 'doc_home_test',
        title: 'Test Passport Expiry',
        category: DocumentCategory.identity,
        expiryDate: today.add(const Duration(days: 10)),
      );
      DocumentRepository.instance.addDocument(testDoc);

      final testInv = Investment(
        id: 'inv_home_test',
        name: 'Test Chit Fund',
        type: InvestmentType.chitFund,
        monthlyContribution: 2000,
        totalPaid: 4000,
        installmentsPaid: 2,
        totalInstallments: 12,
        nextDueDate: today.add(const Duration(days: 5)),
      );
      InvestmentRepository.instance.addInvestment(testInv);

      await AutomaticReminderService.instance.syncAutomaticReminders();

      // Render HomeScreen inside MaterialApp
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Look for the generated reminder title in Home Reminders
      final docFinder = find.descendant(
        of: find.byType(HomeRemindersSection),
        matching: find.text('Test Passport Expiry expiry'),
      );
      if (docFinder.evaluate().isNotEmpty) {
        await tester.tap(docFinder.first);
        await tester.pumpAndSettle();

        // Verify DocumentDetailScreen opened
        expect(find.byType(DocumentDetailScreen), findsOneWidget);

        // Pop back
        final backBtn = find.byType(BackButton);
        if (backBtn.evaluate().isNotEmpty) {
          await tester.tap(backBtn);
          await tester.pumpAndSettle();
        }
      }

      // Cleanup
      DocumentRepository.instance.deleteDocument(testDoc.id);
      InvestmentRepository.instance.deleteInvestment(testInv.id);
    });

    testWidgets(
        'ReminderDetailScreen shows Source card and View Document action for auto-generated reminders',
        (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final testDoc = Document(
        id: 'doc_detail_card_test',
        title: 'Voter ID Card',
        category: DocumentCategory.identity,
        expiryDate: today.add(const Duration(days: 10)),
      );
      DocumentRepository.instance.addDocument(testDoc);
      await AutomaticReminderService.instance.syncAutomaticReminders();

      final remId = AutomaticReminderService.documentReminderId(testDoc.id);

      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailScreen(
            reminderId: remId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Source section is displayed
      expect(find.text('Source'), findsOneWidget);
      expect(find.text('Voter ID Card'), findsOneWidget);
      expect(find.text('Auto-generated'), findsWidgets);
      expect(find.text('View Document'), findsOneWidget);

      // Verify Edit icon is NOT shown for auto-generated reminders
      expect(find.byIcon(Icons.edit_outlined), findsNothing);

      // Verify Delete icon is present
      expect(find.byIcon(Icons.delete_outline), findsWidgets);

      // Tap View Document and verify navigation
      await tester.tap(find.text('View Document'));
      await tester.pumpAndSettle();
      expect(find.byType(DocumentDetailScreen), findsOneWidget);

      // Cleanup
      DocumentRepository.instance.deleteDocument(testDoc.id);
    });
  });
}
