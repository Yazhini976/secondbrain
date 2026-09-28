import 'package:second_brain/core/network/api_client.dart';
import 'package:second_brain/features/documents/models/document.dart';

/// Remote data source for Documents API endpoints.
class DocumentApi {
  final ApiClient _client;

  DocumentApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches documents from backend with optional category and search filters.
  Future<List<Document>> getDocuments({String? category, String? search}) async {
    final queryParams = <String, String>{};
    if (category != null && category.trim().isNotEmpty) {
      queryParams['category'] = category.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _client.get(
      '/documents',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final List<dynamic> list = response as List<dynamic>;
    return list
        .map((json) => Document.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches single document metadata by ID.
  Future<Document> getDocument(String id) async {
    final response = await _client.get('/documents/$id');
    return Document.fromJson(response as Map<String, dynamic>);
  }

  /// Creates a new document metadata record via POST request.
  Future<Document> createDocument(Document document) async {
    final response = await _client.post('/documents', body: document.toJson());
    return Document.fromJson(response as Map<String, dynamic>);
  }

  /// Updates an existing document metadata record via PATCH request.
  Future<Document> updateDocument(Document document) async {
    final response =
        await _client.patch('/documents/${document.id}', body: document.toJson());
    return Document.fromJson(response as Map<String, dynamic>);
  }

  /// Deletes a document record via DELETE request.
  Future<void> deleteDocument(String id) async {
    await _client.delete('/documents/$id');
  }
}
