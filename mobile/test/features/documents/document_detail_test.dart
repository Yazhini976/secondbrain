import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/document_detail_screen.dart';
import 'package:second_brain/features/documents/documents_screen.dart';
import 'package:second_brain/features/documents/models/document.dart';

void main() {
  setUp(() {
    DocumentRepository.instance.resetSampleData();
  });

  group('Step 8C — DocumentDetailScreen Tests', () {
    testWidgets('renders document header, information fields, file info, and actions', (tester) async {
      final doc = Document(
        id: 'doc_detail_1',
        title: 'International Passport',
        category: DocumentCategory.identity,
        description: '10-year official travel passport',
        issueDate: DateTime(2020, 1, 15),
        expiryDate: DateTime(2030, 1, 14),
        fileName: 'passport_scan.pdf',
        fileType: 'PDF',
        fileSize: 204800,
        notes: 'Original in office locker',
      );
      DocumentRepository.instance.addDocument(doc);

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentDetailScreen(documentId: doc.id),
        ),
      );
      await tester.pumpAndSettle();

      // Screen title
      expect(find.text('Document Details'), findsOneWidget);

      // Header
      expect(find.text('International Passport'), findsWidgets);
      expect(find.text('Identity'), findsWidgets);
      expect(find.text('Active'), findsOneWidget);

      // Document Information Card
      expect(find.text('Document Information'), findsOneWidget);
      expect(find.text('10-year official travel passport'), findsOneWidget);
      expect(find.text('15 Jan 2020'), findsOneWidget);
      expect(find.text('Expires 14 Jan 2030'), findsOneWidget);
      expect(find.text('Original in office locker'), findsOneWidget);

      // File section with metadata
      expect(find.text('Document File'), findsWidgets);
      expect(find.text('passport_scan.pdf'), findsOneWidget);
      expect(find.text('PDF · 200 KB'), findsOneWidget);

      // Action buttons
      expect(find.widgetWithText(ElevatedButton, 'Edit Document'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Delete Document'), findsOneWidget);
    });

    testWidgets('handles empty optional fields cleanly without awkward blanks', (tester) async {
      final doc = Document(
        id: 'doc_empty_fields',
        title: 'Simple Note Document',
        category: DocumentCategory.other,
      );
      DocumentRepository.instance.addDocument(doc);

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentDetailScreen(documentId: doc.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No description'), findsOneWidget);
      expect(find.text('Not specified'), findsOneWidget);
      expect(find.text('No expiry date'), findsOneWidget);
      expect(find.text('No notes'), findsOneWidget);
      expect(find.text('No file attached yet'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Add File'), findsOneWidget);
    });

    testWidgets('tapping Add File shows placeholder SnackBar', (tester) async {
      final doc = Document(
        id: 'doc_no_file',
        title: 'Unattached File Document',
        category: DocumentCategory.property,
      );
      DocumentRepository.instance.addDocument(doc);

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentDetailScreen(documentId: doc.id),
        ),
      );
      await tester.pumpAndSettle();

      final addFileButton = find.widgetWithText(OutlinedButton, 'Add File');
      await tester.ensureVisible(addFileButton);
      await tester.tap(addFileButton);
      await tester.pumpAndSettle();

      expect(find.text('File attachment will be implemented in the next step.'), findsOneWidget);
    });

    testWidgets('edit flow pre-populates form, saves changes, and refreshes detail', (tester) async {
      final doc = Document(
        id: 'doc_to_edit_flow',
        title: 'Original Title',
        category: DocumentCategory.insurance,
        description: 'Original Description',
        notes: 'Original Notes',
      );
      DocumentRepository.instance.addDocument(doc);

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentDetailScreen(documentId: doc.id),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Edit Document button
      final editButton = find.widgetWithText(ElevatedButton, 'Edit Document');
      await tester.ensureVisible(editButton);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Verify on Edit Document screen
      expect(find.text('Edit Document'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Modify Document Name
      final nameField = find.widgetWithText(TextFormField, 'Document Name *');
      await tester.enterText(nameField, 'Updated Health Insurance');
      await tester.pumpAndSettle();

      // Save changes
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Changes');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify detail screen reflects the new title
      expect(find.text('Updated Health Insurance'), findsWidgets);
    });

    testWidgets('delete flow shows confirmation dialog and cancels without deleting', (tester) async {
      final doc = Document(
        id: 'doc_to_cancel_delete',
        title: 'Cancel Delete Doc',
        category: DocumentCategory.medical,
      );
      DocumentRepository.instance.addDocument(doc);

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentDetailScreen(documentId: doc.id),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete Document
      final deleteButton = find.widgetWithText(OutlinedButton, 'Delete Document');
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Verify dialog
      expect(find.text('Delete Document?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this document?'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Document still exists in repository
      expect(DocumentRepository.instance.getDocumentById('doc_to_cancel_delete'), isNotNull);
      expect(find.text('Cancel Delete Doc'), findsWidgets);
    });

    testWidgets('delete flow confirms deletion and removes document from repository', (tester) async {
      final doc = Document(
        id: 'doc_to_confirm_delete',
        title: 'Delete Confirm Doc',
        category: DocumentCategory.vehicle,
      );
      DocumentRepository.instance.addDocument(doc);

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentDetailScreen(documentId: doc.id),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete Document
      final deleteButton = find.widgetWithText(OutlinedButton, 'Delete Document');
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Confirm Delete
      final dialogDeleteButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      );
      await tester.tap(dialogDeleteButton);
      await tester.pumpAndSettle();

      // Verify removed from repository
      expect(DocumentRepository.instance.getDocumentById('doc_to_confirm_delete'), isNull);
    });

    testWidgets('displays Document not found screen when ID does not exist', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DocumentDetailScreen(documentId: 'non_existent_doc_id'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Document not found'), findsOneWidget);
      expect(find.text('Return to Documents'), findsOneWidget);
    });

    testWidgets('tapping document item in DocumentsScreen navigates to DocumentDetailScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DocumentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Passport or scroll to Aadhaar Card
      final itemFinder = find.text('Passport');
      await tester.ensureVisible(itemFinder);
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      expect(find.text('Document Details'), findsOneWidget);
      expect(find.text('Passport'), findsWidgets);
      expect(find.text('Document Information'), findsOneWidget);
    });
  });
}
