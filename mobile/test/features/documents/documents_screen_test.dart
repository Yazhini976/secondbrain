import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/documents_screen.dart';
import 'package:second_brain/features/documents/logic/document_status.dart';
import 'package:second_brain/features/documents/models/document.dart';
import 'package:second_brain/features/documents/widgets/document_filter.dart';
import 'package:second_brain/features/documents/widgets/document_list_item.dart';
import 'package:second_brain/features/documents/widgets/document_summary.dart';

void main() {
  setUp(() {
    DocumentRepository.instance.resetSampleData();
  });

  group('Step 8A — Documents Logic & Model Tests', () {
    test('deriveDocumentStatus returns active when expiryDate is null', () {
      final status = deriveDocumentStatus(expiryDate: null);
      expect(status, DocumentStatus.active);
      expect(status.label, 'Active');
    });

    test('deriveDocumentStatus returns expired when expiryDate is in the past', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final status = deriveDocumentStatus(expiryDate: pastDate);
      expect(status, DocumentStatus.expired);
      expect(status.label, 'Expired');
    });

    test('deriveDocumentStatus returns expiringSoon when expiryDate is within 30 days', () {
      final soonDate = DateTime.now().add(const Duration(days: 10));
      final status = deriveDocumentStatus(expiryDate: soonDate);
      expect(status, DocumentStatus.expiringSoon);
      expect(status.label, 'Expiring Soon');
    });

    test('deriveDocumentStatus returns active when expiryDate is far in future', () {
      final futureDate = DateTime.now().add(const Duration(days: 90));
      final status = deriveDocumentStatus(expiryDate: futureDate);
      expect(status, DocumentStatus.active);
    });

    test('Document model copyWith works correctly', () {
      final doc = Document(
        id: 'doc_test',
        title: 'Original Title',
        category: DocumentCategory.identity,
      );
      final updated = doc.copyWith(title: 'Updated Title', category: DocumentCategory.financial);
      expect(updated.id, 'doc_test');
      expect(updated.title, 'Updated Title');
      expect(updated.category, DocumentCategory.financial);
    });

    test('DocumentRepository returns sample documents and supports CRUD', () {
      final repo = DocumentRepository.instance;
      final initialDocs = repo.getDocuments();
      expect(initialDocs.isNotEmpty, isTrue);

      final testDoc = Document(
        id: 'test_doc_unique',
        title: 'Test Passport',
        category: DocumentCategory.identity,
      );
      repo.addDocument(testDoc);
      expect(repo.getDocumentById('test_doc_unique'), isNotNull);

      repo.deleteDocument('test_doc_unique');
      expect(repo.getDocumentById('test_doc_unique'), isNull);
    });
  });

  group('Step 8A — DocumentsScreen Widget Tests', () {
    testWidgets('renders Documents header, summary, filter, list items, and Add button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DocumentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title and description
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Keep your important documents organised'), findsOneWidget);

      // Verify DocumentSummary widget
      expect(find.byType(DocumentSummary), findsOneWidget);
      expect(find.descendant(of: find.byType(DocumentSummary), matching: find.text('Total')), findsOneWidget);
      expect(find.descendant(of: find.byType(DocumentSummary), matching: find.text('Expiring Soon')), findsOneWidget);
      expect(find.descendant(of: find.byType(DocumentSummary), matching: find.text('Expired')), findsOneWidget);

      // Verify Category filter chips
      expect(find.byType(DocumentFilter), findsOneWidget);
      expect(find.descendant(of: find.byType(DocumentFilter), matching: find.text('All')), findsOneWidget);
      expect(find.descendant(of: find.byType(DocumentFilter), matching: find.text('Identity')), findsOneWidget);
      expect(find.descendant(of: find.byType(DocumentFilter), matching: find.text('Financial')), findsOneWidget);

      // Verify DocumentListItem widgets exist
      expect(find.byType(DocumentListItem), findsWidgets);

      // Verify Add Document button exists
      expect(find.widgetWithText(ElevatedButton, 'Add Document'), findsOneWidget);
    });

    testWidgets('filtering by category updates displayed documents', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DocumentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on 'Education' category chip in DocumentFilter
      final educationChip = find.descendant(of: find.byType(DocumentFilter), matching: find.text('Education'));
      await tester.tap(educationChip);
      await tester.pumpAndSettle();

      // Should show 'College Degree Certificate'
      expect(find.text('College Degree Certificate'), findsOneWidget);

      // Tap back on 'All' in DocumentFilter
      final allChip = find.descendant(of: find.byType(DocumentFilter), matching: find.text('All'));
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      expect(find.text('Aadhaar Card'), findsOneWidget);
    });

    testWidgets('search toggle filters documents by keyword', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DocumentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap search icon
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Aadhaar');
      await tester.pumpAndSettle();

      expect(find.text('Aadhaar Card'), findsOneWidget);
      expect(find.text('Passport'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), 'nonexistentquery12345');
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No documents found'), findsOneWidget);
    });

    testWidgets('tapping Add Document opens AddDocumentScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DocumentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final addButton = find.widgetWithText(ElevatedButton, 'Add Document');
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('Document Information'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Save Document'), findsOneWidget);
    });
  });
}
