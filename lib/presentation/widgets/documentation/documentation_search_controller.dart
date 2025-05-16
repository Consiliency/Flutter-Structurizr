import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_search_index.dart';

/// Controller for documentation search functionality
class DocumentationSearchController extends ChangeNotifier {
  /// The workspace containing documentation to search
  final Workspace? workspace;
  
  /// The search index for efficient searching
  late DocumentationSearchIndex _searchIndex;
  
  /// Whether search functionality is enabled
  final bool enabled;
  
  /// Current search query
  String _query = '';
  
  /// Current search results
  List<DocumentationSearchResult> _results = [];
  
  /// Whether a search is currently in progress
  bool _searching = false;
  
  /// Whether the search box is currently focused/expanded
  bool _expanded = false;
  
  /// Debounce timer for efficient searching
  Timer? _debounceTimer;
  
  /// Current search filters
  final Map<String, String> _filters = {};
  
  /// Create a new documentation search controller
  DocumentationSearchController({
    required this.workspace,
    this.enabled = true,
  }) {
    _searchIndex = DocumentationSearchIndex.fromWorkspace(workspace ?? Workspace.empty());
  }
  
  /// Current search query
  String get query => _query;
  
  /// Set search query and trigger search
  set query(String value) {
    if (_query != value) {
      _query = value;
      _triggerSearch();
      notifyListeners();
    }
  }
  
  /// Current search results
  List<DocumentationSearchResult> get results => _results;
  
  /// Whether a search is currently in progress
  bool get isSearching => _searching;
  
  /// Whether the search box is currently focused/expanded
  bool get isExpanded => _expanded;
  
  /// Set expanded state of search box
  set isExpanded(bool value) {
    if (_expanded != value) {
      _expanded = value;
      notifyListeners();
    }
  }
  
  /// Current search filters
  Map<String, String> get filters => Map.unmodifiable(_filters);
  
  /// Add a filter to the search
  void addFilter(String field, String value) {
    if (_filters[field] != value) {
      _filters[field] = value;
      _triggerSearch();
      notifyListeners();
    }
  }
  
  /// Remove a filter from the search
  void removeFilter(String field) {
    if (_filters.containsKey(field)) {
      _filters.remove(field);
      _triggerSearch();
      notifyListeners();
    }
  }
  
  /// Clear all filters
  void clearFilters() {
    if (_filters.isNotEmpty) {
      _filters.clear();
      _triggerSearch();
      notifyListeners();
    }
  }
  
  /// Trigger a search with debouncing
  void _triggerSearch() {
    // Cancel any pending search
    _debounceTimer?.cancel();
    
    // Skip search if disabled
    if (!enabled) return;
    
    // Set searching state
    _searching = true;
    notifyListeners();
    
    // Debounce search to avoid rapid updates
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _search();
    });
  }
  
  /// Perform the actual search
  void _search() {
    final effectiveQuery = _buildQueryString();
    
    // Skip empty searches
    if (effectiveQuery.trim().isEmpty) {
      _results = [];
      _searching = false;
      notifyListeners();
      return;
    }
    
    // Perform search in search index
    _results = _searchIndex.search(effectiveQuery, maxResults: 20);
    _searching = false;
    notifyListeners();
  }
  
  /// Build the full query string including filters
  String _buildQueryString() {
    final buffer = StringBuffer(_query);
    
    // Add filters to query
    _filters.forEach((field, value) {
      // Add space before field filter
      if (buffer.isNotEmpty) buffer.write(' ');
      
      // Add filter in field:value format
      buffer.write('$field:"$value"');
    });
    
    return buffer.toString();
  }
  
  /// Force a rebuild of the search index
  void rebuildIndex() {
    _searchIndex = DocumentationSearchIndex.fromWorkspace(workspace ?? Workspace.empty());
    if (_query.isNotEmpty) {
      _triggerSearch();
    }
  }
  
  /// Get the document index for a search result
  /// Returns the index of the section or decision, or -1 if not found
  int getDocumentIndex(DocumentationSearchResult result) {
    if (result.url.startsWith('doc-')) {
      // Parse documentation index
      final index = int.tryParse(result.url.substring(4));
      return index ?? -1;
    } else if (result.url.startsWith('decision-')) {
      // Parse decision index
      final index = int.tryParse(result.url.substring(9));
      return index ?? -1;
    }
    return -1;
  }
  
  /// Check if result is a documentation section
  bool isDocumentationResult(DocumentationSearchResult result) {
    return result.type == 'documentation';
  }
  
  /// Check if result is a decision
  bool isDecisionResult(DocumentationSearchResult result) {
    return result.type == 'decision';
  }
  
  /// Clear search query and results
  void clear() {
    _query = '';
    _results = [];
    _filters.clear();
    _expanded = false;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}