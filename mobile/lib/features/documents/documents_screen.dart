import 'package:flutter/material.dart';
import 'package:second_brain/core/theme/app_colors.dart';
import 'package:second_brain/core/theme/app_spacing.dart';
import 'package:second_brain/features/documents/add_document_screen.dart';
import 'package:second_brain/features/documents/data/document_repository.dart';
import 'package:second_brain/features/documents/document_detail_screen.dart';
import 'package:second_brain/features/documents/logic/document_service.dart';
import 'package:second_brain/features/documents/models/document.dart';
import 'package:second_brain/features/documents/widgets/document_filter.dart';
import 'package:second_brain/features/documents/widgets/document_list_item.dart';
import 'package:second_brain/features/documents/widgets/document_summary.dart';

/// Main Documents screen — overview, category filtering, search, and list.
/// Fully integrated with deterministic status, search, and distinct empty states.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  DocumentCategory? _selectedCategory;
  String _searchQuery = '';
  bool _searchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    DocumentRepository.instance.addListener(_onRepoChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        DocumentRepository.instance.loadDocuments();
      }
    });
  }

  @override
  void dispose() {
    DocumentRepository.instance.removeListener(_onRepoChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<Document> get _allDocuments =>
      DocumentRepository.instance.getDocuments();

  List<Document> get _filteredDocuments {
    return DocumentService.filterDocuments(
      documents: _allDocuments,
      category: _selectedCategory,
      query: _searchQuery,
    );
  }

  Future<void> _openAddDocument() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddDocumentScreen()),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _openDocumentDetail(Document doc) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(
          documentId: doc.id,
          documentTitle: doc.title,
          category: doc.category,
        ),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DocumentRepository.instance,
      builder: (context, _) {
        final docs = _filteredDocuments;
        final hasAnyDocs = _allDocuments.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Search bar (visible when toggled)
              if (_searchVisible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    AppSpacing.space8,
                    AppSpacing.space16,
                    0,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by name, category, file...',
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: AppColors.mutedText),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  size: 18, color: AppColors.mutedText),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: AppColors.mutedText),
                              onPressed: _toggleSearch,
                            ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.primaryBrightBlue),
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Documents',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Keep your important documents organised',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Search toggle
                          IconButton(
                            onPressed: _toggleSearch,
                            icon: Icon(
                              _searchVisible
                                  ? Icons.search_off
                                  : Icons.search,
                              color: AppColors.secondaryText,
                            ),
                            tooltip: 'Search',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space16),

                      // Overall Repository Summary (never altered by search/filter)
                      DocumentSummary(
                        total: DocumentService.totalCount,
                        expiringSoon: DocumentService.expiringSoonCount,
                        expired: DocumentService.expiredCount,
                      ),
                      const SizedBox(height: AppSpacing.space16),

                      // Category filter
                      DocumentFilter(
                        selected: _selectedCategory,
                        onChanged: (cat) =>
                            setState(() => _selectedCategory = cat),
                      ),
                      const SizedBox(height: AppSpacing.space16),

                      // List or appropriate empty state
                      if (docs.isEmpty)
                        if (!hasAnyDocs)
                          _buildNoDocumentsYetState()
                        else
                          _buildNoSearchResultsState()
                      else
                        ...docs.map(
                          (d) => DocumentListItem(
                            document: d,
                            onTap: () => _openDocumentDetail(d),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.space16),

                      // Add Document primary button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBlue,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _openAddDocument,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text(
                            'Add Document',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Empty State A: When no documents exist in the repository at all
  Widget _buildNoDocumentsYetState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.folder_open_outlined,
              size: 44, color: AppColors.mutedText),
          const SizedBox(height: AppSpacing.space12),
          const Text(
            'No documents yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          const Text(
            'Add your important documents to keep\neverything organized.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          OutlinedButton.icon(
            onPressed: _openAddDocument,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Document'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkBlue,
              side: const BorderSide(color: AppColors.darkBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty State B: When documents exist, but search/filter returned no results
  Widget _buildNoSearchResultsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.search_off_outlined,
              size: 44, color: AppColors.mutedText),
          const SizedBox(height: AppSpacing.space12),
          const Text(
            'No documents found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          const Text(
            'Try a different search or category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
            label: const Text('Clear Filters'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkBlue,
              side: const BorderSide(color: AppColors.darkBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
