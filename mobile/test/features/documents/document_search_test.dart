import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/documents_screen.dart';
import 'package:second_brain/features/documents/logic/document_service.dart';
import 'package:second_brain/features/documents/models/document.dart';
import 'package:second_brain/features/documents/widgets/document_filter.dart';
import 'package:second_brain/features/documents/widgets/document_summary.dart';

void main() {
  setUp(() {
    DocumentRepository.instance.resetSampleData();
  });

  group('Step 8F — Document Search & Polish Tests', () {
    test('DocumentService.filterDocuments matches name, category, description, and file name case-insensitively', () {
      final doc1 = Document(
        id: 'search_1',
        title: 'International Passport',
        category: DocumentCategory.identity,
        description: 'Official biometric travel document',
        fileName: 'passport_bio.pdf',
        fileType: 'PDF',
      );
      final doc2 = Document(
        id: 'search_2',
        title: 'Home Loan Deed',
        category: DocumentCategory.property,
        description: 'Mortgage contract for apartment',
        fileName: 'mortgage.pdf',
        fileType: 'PDF',
      );

      final list = [doc1, doc2];

      // Match by title (case-insensitive)
      expect(DocumentService.filterDocuments(documents: list, query: 'passport').length, 1);
      expect(DocumentService.filterDocuments(documents: list, query: 'PASSPORT').length, 1);

      // Match by category
      expect(DocumentService.filterDocuments(documents: list, query: 'property').length, 1);

      // Match by description
      expect(DocumentService.filterDocuments(documents: list, query: 'biometric').length, 1);

      // Match by file name
      expect(DocumentService.filterDocuments(documents: list, query: 'mortgage.pdf').length, 1);

      // Match with category filter + query
      final both = DocumentService.filterDocuments(
        documents: list,
        category: DocumentCategory.identity,
        query: 'passport',
      );
      expect(both.length, 1);

      // Category mismatch returns empty
      final none = DocumentService.filterDocuments(
        documents: list,
        category: DocumentCategory.education,
        query: 'passport',
      );
      expect(none.length, 0);
    });

    testWidgets('search UI toggles, filters immediately, and displays clear button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DocumentsScreen()),
      );
      await tester.pumpAndSettle();

      // Open search bar
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'degree');
      await tester.pumpAndSettle();

      expect(find.text('College Degree Certificate'), findsOneWidget);
      expect(find.text('Passport'), findsNothing);

      // Verify clear icon button is visible
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear icon button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // All documents restored
      expect(find.text('Passport'), findsOneWidget);
    });

    testWidgets('summary counts represent total repository state, unaffected by search filtering', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DocumentsScreen()),
      );
      await tester.pumpAndSettle();

      final totalBefore = DocumentService.totalCount;

      // Filter via search
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Passport');
      await tester.pumpAndSettle();

      // DocumentSummary still shows total count
      expect(find.byType(DocumentSummary), findsOneWidget);
      expect(find.descendant(of: find.byType(DocumentSummary), matching: find.text('$totalBefore')), findsOneWidget);
    });

    testWidgets('Empty State B: shows "No documents found" with "Clear Filters" button when query has no matches', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DocumentsScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'non_matching_search_xyz_123');
      await tester.pumpAndSettle();

      expect(find.text('No documents found'), findsOneWidget);
      expect(find.text('Try a different search or category.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Clear Filters'), findsOneWidget);

      // Tap Clear Filters
      await tester.tap(find.widgetWithText(OutlinedButton, 'Clear Filters'));
      await tester.pumpAndSettle();

      // Documents restored
      expect(find.text('Passport'), findsOneWidget);
    });

    testWidgets('search and category filtering work seamlessly together', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DocumentsScreen()),
      );
      await tester.pumpAndSettle();

      // Select Insurance category
      final insuranceChip = find.descendant(of: find.byType(DocumentFilter), matching: find.text('Insurance'));
      await tester.tap(insuranceChip);
      await tester.pumpAndSettle();

      // Open search and search for "vehicle"
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'vehicle');
      await tester.pumpAndSettle();

      // Shows Vehicle Insurance (which matches both Category: Insurance and Query: vehicle)
      expect(find.text('Vehicle Insurance'), findsOneWidget);
      expect(find.text('Health Insurance Policy'), findsNothing);
    });
  });
}
