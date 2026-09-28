import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/logic/document_status.dart';
import 'package:second_brain/features/documents/models/document.dart';
import 'package:second_brain/features/home/models/home_sample_data.dart';

/// Centralized domain service for document expiry metrics and Home attention items.
///
/// Keeps business logic outside the UI so neither HomeScreen nor DocumentsScreen
/// calculates document status independently.
class DocumentService {
  DocumentService._();

  static DocumentRepository get _repo => DocumentRepository.instance;

  static List<Document> getAllDocuments() => _repo.getDocuments();

  static List<Document> getActiveDocuments() => _repo.getActiveDocuments();

  static List<Document> getExpiringSoonDocuments() =>
      _repo.getExpiringSoonDocuments();

  static List<Document> getExpiredDocuments() => _repo.getExpiredDocuments();

  static int get totalCount => _repo.getDocuments().length;

  static int get expiringSoonCount => getExpiringSoonDocuments().length;

  static int get expiredCount => getExpiredDocuments().length;

  /// Returns real attention items for expiring and expired documents.
  static List<AttentionItem> getDocumentAttentionItems() {
    final items = <AttentionItem>[];

    // 1. Expiring soon documents
    for (final doc in getExpiringSoonDocuments()) {
      final statusText = doc.expiryDate != null
          ? getDocumentExpiryRelativeText(doc.expiryDate!)
          : 'Expiring Soon';

      items.add(
        AttentionItem(
          id: 'doc_${doc.id}',
          documentId: doc.id,
          title: doc.title,
          statusText: statusText,
          urgency: AttentionUrgency.upcoming,
          icon: doc.category.icon,
        ),
      );
    }

    // 2. Expired documents
    for (final doc in getExpiredDocuments()) {
      final statusText = doc.expiryDate != null
          ? getDocumentExpiryRelativeText(doc.expiryDate!)
          : 'Expired';

      items.add(
        AttentionItem(
          id: 'doc_${doc.id}',
          documentId: doc.id,
          title: doc.title,
          statusText: statusText,
          urgency: AttentionUrgency.overdue,
          icon: doc.category.icon,
        ),
      );
    }

    return items;
  }

  /// Filters and sorts documents by category and search query.
  ///
  /// Matches (case-insensitive):
  /// - Document name (title)
  /// - Category display name
  /// - Description
  /// - File name
  /// - File type
  ///
  /// Sorts recently updated documents first.
  static List<Document> filterDocuments({
    required List<Document> documents,
    DocumentCategory? category,
    String? query,
  }) {
    var result = List<Document>.from(documents);

    // 1. Category Filter
    if (category != null) {
      result = result.where((d) => d.category == category).toList();
    }

    // 2. Search Query Filter
    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      result = result.where((d) {
        final titleMatch = d.title.toLowerCase().contains(q);
        final categoryMatch = d.category.displayName.toLowerCase().contains(q);
        final descMatch = d.description?.toLowerCase().contains(q) ?? false;
        final fileMatch = d.fileName?.toLowerCase().contains(q) ?? false;
        final fileTypeMatch = d.fileType?.toLowerCase().contains(q) ?? false;

        return titleMatch ||
            categoryMatch ||
            descMatch ||
            fileMatch ||
            fileTypeMatch;
      }).toList();
    }

    // 3. Deterministic Sorting: Recently updated first, then by title
    result.sort((a, b) {
      final dateComp = b.updatedAt.compareTo(a.updatedAt);
      if (dateComp != 0) return dateComp;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return result;
  }
}

