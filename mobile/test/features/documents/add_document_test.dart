import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/documents/add_document_screen.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/documents_screen.dart';
import 'package:second_brain/features/documents/models/document.dart';

void main() {
  group('Step 8B — Add Document Tests', () {
    testWidgets('AddDocumentScreen renders all required and optional form fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddDocumentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Document'), findsOneWidget);
      expect(find.text('Document Information'), findsOneWidget);
      expect(find.text('Document Name *'), findsOneWidget);
      expect(find.text('Category *'), findsOneWidget);
      expect(find.text('Description (optional)'), findsOneWidget);
      expect(find.text('Dates'), findsOneWidget);
      expect(find.text('Issue Date (optional)'), findsOneWidget);
      expect(find.text('Expiry Date (optional)'), findsOneWidget);
      expect(find.text('Additional Details'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsOneWidget);
      expect(find.text('Document File'), findsWidgets);
      expect(find.text('No file attached'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Add File'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Save Document'), findsOneWidget);
    });

    testWidgets('validates required document name field when empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddDocumentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(ElevatedButton, 'Save Document');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Enter a document name.'), findsOneWidget);
    });

    testWidgets('tapping Add File shows placeholder SnackBar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddDocumentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final addFileButton = find.widgetWithText(OutlinedButton, 'Add File');
      await tester.ensureVisible(addFileButton);
      await tester.tap(addFileButton);
      await tester.pumpAndSettle();

      expect(find.text('File attachment will be implemented in the next step.'), findsOneWidget);
    });

    testWidgets('creates and saves new document successfully without file', (tester) async {
      final initialCount = DocumentRepository.instance.getDocuments().length;

      await tester.pumpWidget(
        const MaterialApp(
          home: AddDocumentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Document Name
      final nameField = find.widgetWithText(TextFormField, 'Document Name *');
      await tester.enterText(nameField, 'Voter ID Card');
      await tester.pumpAndSettle();

      // Enter Description
      final descField = find.widgetWithText(TextFormField, 'Description (optional)');
      await tester.enterText(descField, 'Official election commission voter card');
      await tester.pumpAndSettle();

      // Enter Notes
      final notesField = find.widgetWithText(TextFormField, 'Notes (optional)');
      await tester.enterText(notesField, 'Kept in blue folder');
      await tester.pumpAndSettle();

      // Tap Save
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Document');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final updatedDocs = DocumentRepository.instance.getDocuments();
      expect(updatedDocs.length, initialCount + 1);

      final savedDoc = updatedDocs.firstWhere((d) => d.title == 'Voter ID Card');
      expect(savedDoc.category, DocumentCategory.identity);
      expect(savedDoc.description, 'Official election commission voter card');
      expect(savedDoc.notes, 'Kept in blue folder');
      expect(savedDoc.expiryDate, isNull);
    });

    testWidgets('full navigation flow: DocumentsScreen -> Add Document -> Save -> appears in list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DocumentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Add Document button
      final addButton = find.widgetWithText(ElevatedButton, 'Add Document');
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Verify we are on Add Document screen
      expect(find.text('Document Information'), findsOneWidget);

      // Enter unique document title
      final nameField = find.widgetWithText(TextFormField, 'Document Name *');
      await tester.enterText(nameField, 'Work Permit 2026');
      await tester.pumpAndSettle();

      // Save document
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Document');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify we returned to DocumentsScreen and the new document appears
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Work Permit 2026'), findsOneWidget);
    });

    testWidgets('edit mode pre-populates fields and updates document', (tester) async {
      final sampleDoc = Document(
        id: 'doc_to_edit',
        title: 'Original Policy',
        category: DocumentCategory.insurance,
        description: 'Original description',
        notes: 'Original note',
      );
      DocumentRepository.instance.addDocument(sampleDoc);

      await tester.pumpWidget(
        MaterialApp(
          home: AddDocumentScreen(existing: sampleDoc),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Document'), findsOneWidget);
      expect(find.text('Original Policy'), findsOneWidget);
      expect(find.text('Original description'), findsOneWidget);
      expect(find.text('Original note'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Save Changes'), findsOneWidget);

      // Edit title
      final nameField = find.widgetWithText(TextFormField, 'Document Name *');
      await tester.enterText(nameField, 'Updated Health Policy');
      await tester.pumpAndSettle();

      // Save changes
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Changes');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final updated = DocumentRepository.instance.getDocumentById('doc_to_edit');
      expect(updated, isNotNull);
      expect(updated!.title, 'Updated Health Policy');
    });
  });
}
