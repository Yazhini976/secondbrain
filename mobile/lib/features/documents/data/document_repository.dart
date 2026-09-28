import 'package:flutter/foundation.dart';
import 'package:second_brain/features/documents/data/document_api.dart';
import 'package:second_brain/features/documents/logic/document_status.dart';
import 'package:second_brain/features/documents/models/document.dart';
import 'package:second_brain/features/reminders/services/automatic_reminder_service.dart';

/// Document Repository.
/// Domain layer abstraction between Flutter UI and FastAPI + PostgreSQL backend.
/// Extends [ChangeNotifier] so Home and Documents screens reactively rebuild.
class DocumentRepository extends ChangeNotifier {
  static final DocumentRepository instance = DocumentRepository._internal();

  final DocumentApi _api;
  List<Document> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;

  DocumentRepository._internal({DocumentApi? api})
      : _api = api ?? DocumentApi() {
    _documents = [];
  }

  factory DocumentRepository({DocumentApi? api}) {
    return DocumentRepository._internal(api: api);
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Document> getDocuments() => List.unmodifiable(_documents);

  /// Clears in-memory documents when switching users or logging out.
  void clear() {
    _documents = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads documents from backend with optional category filter.
  Future<List<Document>> loadDocuments({String? category, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteList = await _api.getDocuments(category: category, search: search);
      _documents = remoteList;
      _isLoading = false;
      notifyListeners();
      return _documents;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
      _isLoading = false;
      notifyListeners();
      return getDocuments();
    }
  }

  Document? getDocumentById(String id) {
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a document via backend API and updates local state.
  Future<Document> addDocument(Document doc) async {
    final existingIndex = _documents.indexWhere((d) => d.id == doc.id);
    if (existingIndex == -1) {
      _documents.add(doc);
    }
    notifyListeners();
    try {
      AutomaticReminderService.instance.syncDocument(doc);
    } catch (e) {
      debugPrint('Error triggering reminder sync on addDocument: $e');
    }

    try {
      final created = await _api.createDocument(doc);
      final idx = _documents.indexWhere((d) => d.id == doc.id || d.id == created.id);
      if (idx != -1) {
        _documents[idx] = created;
      } else {
        _documents.add(created);
      }
      notifyListeners();
      try {
        AutomaticReminderService.instance.syncDocument(created);
      } catch (_) {}
      return created;
    } catch (e) {
      return doc;
    }
  }

  /// Updates a document via backend API and updates local state.
  Future<Document> updateDocument(Document updated) async {
    final idx = _documents.indexWhere((d) => d.id == updated.id);
    if (idx != -1) {
      _documents[idx] = updated;
    } else {
      _documents.add(updated);
    }
    notifyListeners();
    try {
      AutomaticReminderService.instance.syncDocument(updated);
    } catch (e) {
      debugPrint('Error triggering reminder sync on updateDocument: $e');
    }

    try {
      final serverUpdated = await _api.updateDocument(updated);
      final index = _documents.indexWhere((d) => d.id == serverUpdated.id);
      if (index != -1) {
        _documents[index] = serverUpdated;
      } else {
        _documents.add(serverUpdated);
      }
      notifyListeners();
      try {
        AutomaticReminderService.instance.syncDocument(serverUpdated);
      } catch (_) {}
      return serverUpdated;
    } catch (e) {
      return updated;
    }
  }

  /// Deletes a document via backend API and updates local state.
  Future<void> deleteDocument(String id) async {
    _documents.removeWhere((d) => d.id == id);
    notifyListeners();
    try {
      AutomaticReminderService.instance.removeDocumentReminder(id);
    } catch (e) {
      debugPrint('Error triggering reminder sync on deleteDocument: $e');
    }

    try {
      await _api.deleteDocument(id);
    } catch (_) {}
  }

  List<Document> getActiveDocuments() => _documents
      .where((d) =>
          deriveDocumentStatus(expiryDate: d.expiryDate) ==
          DocumentStatus.active)
      .toList();

  List<Document> getExpiringSoonDocuments() => _documents
      .where((d) =>
          deriveDocumentStatus(expiryDate: d.expiryDate) ==
          DocumentStatus.expiringSoon)
      .toList();

  List<Document> getExpiredDocuments() => _documents
      .where((d) =>
          deriveDocumentStatus(expiryDate: d.expiryDate) ==
          DocumentStatus.expired)
      .toList();

  /// Resets the repository to initial sample data for testing.
  void resetSampleData() {
    _documents
      ..clear()
      ..addAll(_sampleDocuments);
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

final List<Document> _sampleDocuments = [
  Document(
    id: 'doc_001',
    title: 'Aadhaar Card',
    category: DocumentCategory.identity,
    description: 'Government issued identity document',
    issueDate: DateTime(2015, 3, 12),
    expiryDate: null,
    fileName: 'aadhaar_card.pdf',
    fileType: 'PDF',
    fileSize: 204800,
    notes: 'Stored physical copy in safe',
  ),
  Document(
    id: 'doc_002',
    title: 'Passport',
    category: DocumentCategory.identity,
    description: 'International travel document',
    issueDate: DateTime(2020, 6, 18),
    expiryDate: DateTime(2030, 6, 17),
    fileName: 'passport.pdf',
    fileType: 'PDF',
    fileSize: 512000,
    notes: 'Valid for 10 years',
  ),
  Document(
    id: 'doc_003',
    title: 'College Degree Certificate',
    category: DocumentCategory.education,
    description: 'Bachelor of Engineering — Computer Science',
    issueDate: DateTime(2022, 5, 15),
    expiryDate: null,
    fileName: 'degree_certificate.pdf',
    fileType: 'PDF',
    fileSize: 1024000,
  ),
  Document(
    id: 'doc_004',
    title: 'Bank Statement — Q2 2026',
    category: DocumentCategory.financial,
    description: 'SBI savings account statement April–June 2026',
    issueDate: DateTime(2026, 7, 1),
    expiryDate: null,
    fileName: 'bank_statement_q2_2026.pdf',
    fileType: 'PDF',
    fileSize: 307200,
  ),
  Document(
    id: 'doc_005',
    title: 'Property Registration',
    category: DocumentCategory.property,
    description: 'Registration deed for residential property',
    issueDate: DateTime(2019, 11, 4),
    expiryDate: null,
    fileName: 'property_registration.pdf',
    fileType: 'PDF',
    fileSize: 2097152,
    notes: 'Original stored with lawyer',
  ),
  Document(
    id: 'doc_006',
    title: 'Health Insurance Policy',
    category: DocumentCategory.insurance,
    description: 'Family floater health insurance — annual renewal',
    issueDate: DateTime(2025, 10, 12),
    expiryDate: DateTime(2026, 10, 11),
    fileName: 'health_insurance_2026.pdf',
    fileType: 'PDF',
    fileSize: 409600,
    notes: 'Renew before Oct 11',
  ),
  Document(
    id: 'doc_007',
    title: 'Vehicle Insurance',
    category: DocumentCategory.insurance,
    description: 'Comprehensive car insurance policy',
    issueDate: DateTime(2025, 10, 5),
    expiryDate: DateTime(2026, 10, 4),
    fileName: 'vehicle_insurance_2026.pdf',
    fileType: 'PDF',
    fileSize: 358400,
  ),
  Document(
    id: 'doc_008',
    title: 'Vehicle RC',
    category: DocumentCategory.vehicle,
    description: 'Registration Certificate — periodic renewal required',
    issueDate: DateTime(2021, 8, 4),
    expiryDate: DateTime(2026, 8, 3),
    fileName: 'vehicle_rc.pdf',
    fileType: 'PDF',
    fileSize: 153600,
    notes: 'RC renewal pending',
  ),
  Document(
    id: 'doc_009',
    title: 'Medical Report — General Checkup',
    category: DocumentCategory.medical,
    description: 'Annual general health checkup report',
    issueDate: DateTime(2025, 9, 10),
    expiryDate: DateTime(2026, 9, 9),
    fileName: 'medical_report_2025.pdf',
    fileType: 'PDF',
    fileSize: 716800,
    notes: 'Annual checkup recommended',
  ),
  Document(
    id: 'doc_010',
    title: 'PAN Card',
    category: DocumentCategory.identity,
    description: 'Permanent Account Number issued by Income Tax Dept.',
    issueDate: DateTime(2012, 7, 22),
    expiryDate: null,
    fileName: 'pan_card.jpg',
    fileType: 'JPG',
    fileSize: 102400,
  ),
];
