import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'dart:math' as math;

/// A search result with relevance score and highlighted content
class DocumentationSearchResult {
  /// The section title where the match was found
  final String title;

  /// The section URL or identifier
  final String url;

  /// Path showing the section's location in the document
  final String path;

  /// Content text containing the match
  final String content;

  /// List of keywords that matched
  final List<String> matchedTerms;

  /// Relevance score for sorting results (higher is better)
  final double relevance;

  /// Type of content (documentation or decision)
  final String type;

  /// Any associated metadata
  final Map<String, String> metadata;

  const DocumentationSearchResult({
    required this.title,
    required this.url,
    required this.path,
    required this.content,
    required this.matchedTerms,
    required this.relevance,
    required this.type,
    this.metadata = const {},
  });

  /// Creates a copy of this result with changes
  DocumentationSearchResult copyWith({
    String? title,
    String? url,
    String? path,
    String? content,
    List<String>? matchedTerms,
    double? relevance,
    String? type,
    Map<String, String>? metadata,
  }) {
    return DocumentationSearchResult(
      title: title ?? this.title,
      url: url ?? this.url,
      path: path ?? this.path,
      content: content ?? this.content,
      matchedTerms: matchedTerms ?? this.matchedTerms,
      relevance: relevance ?? this.relevance,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'SearchResult(title: $title, relevance: $relevance, terms: $matchedTerms)';
  }
}

/// A search index that supports full-text and metadata-based searching
class DocumentationSearchIndex {
  final Map<String, Map<String, double>> _invertedIndex = {};
  final Map<String, Map<String, String>> _metadata = {};
  final Map<String, String> _contentIndex = {};
  final Map<String, String> _titleIndex = {};
  final Map<String, String> _pathIndex = {};
  final Map<String, String> _typeIndex = {};

  /// Whether the index has been built
  bool _isBuilt = false;

  /// Total number of documents in the index
  int _docCount = 0;

  /// Create a new empty search index
  DocumentationSearchIndex();

  /// Creates a search index from a workspace
  DocumentationSearchIndex.fromWorkspace(Workspace workspace) {
    indexWorkspace(workspace);
  }

  /// Check if the index has been built
  bool get isBuilt => _isBuilt;

  /// Get the number of indexed documents
  int get documentCount => _docCount;

  /// Index a workspace's documentation and decisions
  void indexWorkspace(Workspace workspace) {
    // Reset index if already built
    if (_isBuilt) {
      _invertedIndex.clear();
      _metadata.clear();
      _contentIndex.clear();
      _titleIndex.clear();
      _pathIndex.clear();
      _typeIndex.clear();
      _docCount = 0;
    }

    // Index documentation sections
    if (workspace.documentation != null) {
      final docs = workspace.documentation!;

      // Index each section
      for (int i = 0; i < docs.sections.length; i++) {
        final section = docs.sections[i];
        final docId = 'doc-$i';
        _indexDocument(
          id: docId,
          title: section.title,
          content: section.content,
          path: 'Documentation',
          type: 'documentation',
          metadata: section.metadata,
        );
      }
    }

    // Index decisions
    if (workspace.documentation?.decisions != null) {
      final decisions = workspace.documentation!.decisions;

      // Index each decision
      for (int i = 0; i < decisions.length; i++) {
        final decision = decisions[i];
        final decisionId = 'decision-$i';

        // Create metadata from decision fields
        final metadata = <String, String>{
          'id': decision.id,
          'status': decision.status,
        };
        metadata['date'] = decision.date.toString();

        _indexDocument(
          id: decisionId,
          title: decision.title,
          content: decision.content,
          path: 'Decisions',
          type: 'decision',
          metadata: metadata,
        );
      }
    }

    _isBuilt = true;
  }

  /// Add a document to the index
  void _indexDocument({
    required String id,
    required String title,
    required String content,
    required String path,
    required String type,
    Map<String, String> metadata = const {},
  }) {
    // Store document content and metadata
    _contentIndex[id] = content;
    _titleIndex[id] = title;
    _pathIndex[id] = path;
    _typeIndex[id] = type;
    _metadata[id] = Map.from(metadata);

    // Increment document count
    _docCount++;

    // Process title terms (high weight)
    final titleTerms = _tokenize(title);
    for (final term in titleTerms) {
      if (term.length < 2) continue; // Skip very short terms

      _invertedIndex.putIfAbsent(term, () => {});
      // Title terms get higher weight (5.0)
      _invertedIndex[term]![id] = (_invertedIndex[term]![id] ?? 0.0) + 5.0;
    }

    // Process content terms (normal weight)
    final contentTerms = _tokenize(content);
    for (final term in contentTerms) {
      if (term.length < 2) continue; // Skip very short terms

      _invertedIndex.putIfAbsent(term, () => {});
      // Content terms get normal weight (1.0)
      _invertedIndex[term]![id] = (_invertedIndex[term]![id] ?? 0.0) + 1.0;
    }

    // Process metadata terms (medium weight)
    metadata.forEach((key, value) {
      final metaTerms = _tokenize(value);
      for (final term in metaTerms) {
        if (term.length < 2) continue; // Skip very short terms

        _invertedIndex.putIfAbsent(term, () => {});
        // Metadata terms get medium weight (2.0)
        _invertedIndex[term]![id] = (_invertedIndex[term]![id] ?? 0.0) + 2.0;

        // Add special key:value index entry for exact matching
        final keyValueTerm = '$key:$term';
        _invertedIndex.putIfAbsent(keyValueTerm, () => {});
        // Key-value pairs get high weight (4.0)
        _invertedIndex[keyValueTerm]![id] =
            (_invertedIndex[keyValueTerm]![id] ?? 0.0) + 4.0;
      }
    });
  }

  /// Search the index for query terms
  List<DocumentationSearchResult> search(String query, {int maxResults = 10}) {
    // TEMP: Minimal stub to unblock build. Restore real implementation after build is unblocked.
    return [];
  }

  /// Extract a relevant snippet containing search terms
  String _getSnippet(String content, List<String> terms) {
    if (terms.isEmpty || content.isEmpty) {
      // Return first 150 characters if no terms matched or no content
      return content.length > 150 ? '${content.substring(0, 150)}...' : content;
    }

    // Find the first occurrence of any term
    int? firstPos;
    String? matchedTerm;

    for (final term in terms) {
      final termPos = content.toLowerCase().indexOf(term);
      if (termPos >= 0 && (firstPos == null || termPos < firstPos)) {
        firstPos = termPos;
        matchedTerm = term;
      }
    }

    // If no term found in content, return first 150 chars
    if (firstPos == null || matchedTerm == null) {
      return content.length > 150 ? '${content.substring(0, 150)}...' : content;
    }

    // Extract snippet with context around the term
    final snippetStart = firstPos > 75 ? firstPos - 75 : 0;
    final snippetEnd = firstPos + matchedTerm.length + 75 < content.length
        ? firstPos + matchedTerm.length + 75
        : content.length;

    String snippet = content.substring(snippetStart, snippetEnd);

    // Add ellipsis if we're truncating
    if (snippetStart > 0) {
      snippet = '...$snippet';
    }
    if (snippetEnd < content.length) {
      snippet = '$snippet...';
    }

    return snippet;
  }

  /// Convert text to lowercase tokens
  List<String> _tokenize(String text) {
    if (text.isEmpty) return [];

    // Replace non-alphanumeric with spaces, convert to lowercase
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Split into tokens and filter out common stop words
    return normalized.split(' ').where(_isNotStopWord).toList();
  }

  /// Check if word is not a common stop word
  bool _isNotStopWord(String word) {
    const stopWords = {
      'a',
      'an',
      'the',
      'and',
      'or',
      'but',
      'if',
      'as',
      'at',
      'by',
      'for',
      'in',
      'into',
      'of',
      'off',
      'on',
      'onto',
      'per',
      'to',
      'up',
      'via',
      'with',
      'this',
      'that',
      'these',
      'those',
      'it',
      'its'
    };
    return !stopWords.contains(word);
  }

  /// Calculate log base 10
  double log(double x) {
    return log10e * (x > 0 ? math.log(x) : 0);
  }

  /// Approximate value of log base 10 of e
  static const double log10e = 0.4342944819032518;
}
