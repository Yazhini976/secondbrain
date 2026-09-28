import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/logic/document_service.dart';
import 'package:second_brain/features/documents/logic/document_status.dart';
import 'package:second_brain/features/documents/models/document.dart';
import 'package:second_brain/features/home/home_screen.dart';
import 'package:second_brain/features/home/widgets/attention_section.dart';

void main() {
  Widget buildTestHome() {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(child: HomeScreen()),
      ),
    );
  }

  group('Step 8E — Document Expiry & Home Integration Tests', () {
    test('calculateDocumentStatus / deriveDocumentStatus returns deterministic status with date normalization', () {
      final now = DateTime.now();

      // Active (no expiry)
      expect(calculateDocumentStatus(null), DocumentStatus.active);

      // Active (far in future, 60 days)
      final farFuture = DateTime(now.year, now.month, now.day + 60);
      expect(calculateDocumentStatus(farFuture), DocumentStatus.active);

      // Expiring soon (10 days in future)
      final soon = DateTime(now.year, now.month, now.day + 10);
      expect(calculateDocumentStatus(soon), DocumentStatus.expiringSoon);

      // Expiring today (0 days difference) -> expiringSoon, not expired
      final today = DateTime(now.year, now.month, now.day);
      expect(calculateDocumentStatus(today), DocumentStatus.expiringSoon);

      // Expired (1 day in past)
      final past = DateTime(now.year, now.month, now.day - 1);
      expect(calculateDocumentStatus(past), DocumentStatus.expired);
    });

    test('getDocumentExpiryRelativeText formats relative text correctly', () {
      final now = DateTime.now();

      final past = DateTime(now.year, now.month, now.day - 3);
      expect(getDocumentExpiryRelativeText(past), 'Expired 3 days ago');

      final yesterday = DateTime(now.year, now.month, now.day - 1);
      expect(getDocumentExpiryRelativeText(yesterday), 'Expired yesterday');

      final today = DateTime(now.year, now.month, now.day);
      expect(getDocumentExpiryRelativeText(today), 'Expires today');

      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      expect(getDocumentExpiryRelativeText(tomorrow), 'Expires tomorrow');

      final soon = DateTime(now.year, now.month, now.day + 12);
      expect(getDocumentExpiryRelativeText(soon), 'Expires in 12 days');
    });

    testWidgets('TEST SCENARIO 1 & 4 — Active or no-expiry documents do not appear in Home attention', (tester) async {
      final activeDoc = Document(
        id: 'doc_active_test',
        title: 'Long-term Lease Agreement',
        category: DocumentCategory.property,
        expiryDate: DateTime.now().add(const Duration(days: 180)),
      );
      final noExpiryDoc = Document(
        id: 'doc_no_expiry_test',
        title: 'Birth Certificate Permanent',
        category: DocumentCategory.identity,
        expiryDate: null,
      );
      DocumentRepository.instance.addDocument(activeDoc);
      DocumentRepository.instance.addDocument(noExpiryDoc);

      await tester.pumpWidget(buildTestHome());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AttentionSection),
          matching: find.text('Long-term Lease Agreement'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(AttentionSection),
          matching: find.text('Birth Certificate Permanent'),
        ),
        findsNothing,
      );
    });

    testWidgets('TEST SCENARIO 2 — Expiring soon document appears in Home Needs Attention', (tester) async {
      final soonDoc = Document(
        id: 'doc_expiring_soon_test',
        title: 'Commercial Driving License',
        category: DocumentCategory.identity,
        expiryDate: DateTime.now().add(const Duration(days: 8)),
      );
      DocumentRepository.instance.addDocument(soonDoc);

      await tester.pumpWidget(buildTestHome());
      await tester.pumpAndSettle();

      final itemFinder = find.descendant(
        of: find.byType(AttentionSection),
        matching: find.text('Commercial Driving License'),
      );
      expect(itemFinder, findsOneWidget);
      expect(find.text('Expires in 8 days'), findsOneWidget);
    });

    testWidgets('TEST SCENARIO 3 — Expired document appears in Home Needs Attention as overdue', (tester) async {
      final expiredDoc = Document(
        id: 'doc_expired_test',
        title: 'Pet Vaccination Record',
        category: DocumentCategory.medical,
        expiryDate: DateTime.now().subtract(const Duration(days: 4)),
      );
      DocumentRepository.instance.addDocument(expiredDoc);

      await tester.pumpWidget(buildTestHome());
      await tester.pumpAndSettle();

      final itemFinder = find.descendant(
        of: find.byType(AttentionSection),
        matching: find.text('Pet Vaccination Record'),
      );
      expect(itemFinder, findsOneWidget);
      expect(find.text('Expired 4 days ago'), findsOneWidget);
    });

    testWidgets('TEST SCENARIO 5 — Reactive Edit: editing an active doc to expiring soon updates Home immediately', (tester) async {
      final doc = Document(
        id: 'doc_reactive_edit',
        title: 'Visa Extension Letter',
        category: DocumentCategory.identity,
        expiryDate: DateTime.now().add(const Duration(days: 120)), // Active initially
      );
      DocumentRepository.instance.addDocument(doc);

      await tester.pumpWidget(buildTestHome());
      await tester.pumpAndSettle();

      // Initially active, not in attention
      expect(
        find.descendant(
          of: find.byType(AttentionSection),
          matching: find.text('Visa Extension Letter'),
        ),
        findsNothing,
      );

      // Edit document so it expires in 5 days
      final updated = doc.copyWith(
        expiryDate: DateTime.now().add(const Duration(days: 5)),
      );
      DocumentRepository.instance.updateDocument(updated);
      await tester.pumpAndSettle();

      // Home immediately shows it without app restart!
      final itemFinder = find.descendant(
        of: find.byType(AttentionSection),
        matching: find.text('Visa Extension Letter'),
      );
      expect(itemFinder, findsOneWidget);
      expect(find.text('Expires in 5 days'), findsOneWidget);
    });

    testWidgets('TEST SCENARIO 6 — Reactive Delete: deleting an expiring doc updates Home immediately', (tester) async {
      final doc = Document(
        id: 'doc_reactive_delete',
        title: 'Temporary Work Permit',
        category: DocumentCategory.identity,
        expiryDate: DateTime.now().add(const Duration(days: 10)),
      );
      DocumentRepository.instance.addDocument(doc);

      await tester.pumpWidget(buildTestHome());
      await tester.pumpAndSettle();

      final itemFinder = find.descendant(
        of: find.byType(AttentionSection),
        matching: find.text('Temporary Work Permit'),
      );
      expect(itemFinder, findsOneWidget);

      // Delete document
      DocumentRepository.instance.deleteDocument('doc_reactive_delete');
      await tester.pumpAndSettle();

      // Home immediately removes it!
      expect(find.text('Temporary Work Permit'), findsNothing);
    });

    testWidgets('TEST SCENARIO 7 — Tapping document attention item in Home navigates to DocumentDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final doc = Document(
        id: 'doc_tap_target',
        title: 'International Driving Permit',
        category: DocumentCategory.identity,
        expiryDate: DateTime.now().add(const Duration(days: 15)),
      );
      DocumentRepository.instance.addDocument(doc);

      await tester.pumpWidget(buildTestHome());
      await tester.pumpAndSettle();

      final itemFinder = find.descendant(
        of: find.byType(AttentionSection),
        matching: find.text('International Driving Permit'),
      );
      expect(itemFinder, findsOneWidget);

      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      // Navigated to DocumentDetailScreen
      expect(find.text('Document Details'), findsOneWidget);
      expect(find.text('International Driving Permit'), findsWidgets);
      expect(find.text('Document Information'), findsOneWidget);
    });

    test('DocumentService calculates aggregate counts accurately', () {
      final total = DocumentService.totalCount;
      final expiring = DocumentService.expiringSoonCount;
      final expired = DocumentService.expiredCount;
      final active = DocumentService.getActiveDocuments().length;

      expect(total, active + expiring + expired);
      expect(DocumentService.getDocumentAttentionItems().length, expiring + expired);
    });
  });
}
