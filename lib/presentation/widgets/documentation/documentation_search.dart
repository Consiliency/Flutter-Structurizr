import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';

/// A search result for documentation.
class DocumentationSearchResult {
  /// The section containing the result.
  final DocumentationSection? section;

  /// The decision containing the result.
  final Decision? decision;

  /// The matched text.
  final String matchedText;

  /// The context around the match.
  final String context;

  /// The index of the match in the content.
  final int matchIndex;

  /// Whether this is a decision.
  bool get isDecision => decision != null;

  /// Title of the result (either section title or decision title).
  String get title => decision?.title ?? section?.title ?? 'Unknown';

  /// Creates a new documentation search result.
  DocumentationSearchResult({
    this.section,
    this.decision,
    required this.matchedText,
    required this.context,
    required this.matchIndex,
  }) : assert(section != null || decision != null,
            'Either section or decision must be provided');

  @override
  String toString() {
    return 'DocumentationSearchResult{${isDecision ? 'decision=$decision' : 'section=$section'}, matchedText=$matchedText, matchIndex=$matchIndex}';
  }
}

/// A controller for managing documentation search.
class DocumentationSearchController extends ChangeNotifier {
  /// The current search query.
  String _query = '';

  /// The current search results.
  List<DocumentationSearchResult> _results = [];

  /// Whether search is currently in progress.
  bool _isSearching = false;

  /// The documentation being searched.
  Documentation? _documentation;

  /// The current search query.
  String get query => _query;

  /// The current search results.
  List<DocumentationSearchResult> get results => _results;

  /// Whether search is currently in progress.
  bool get isSearching => _isSearching;

  /// Sets the documentation to search.
  void setDocumentation(Documentation? documentation) {
    _documentation = documentation;
    if (_query.isNotEmpty) {
      search(_query);
    }
  }

  /// Performs a search with the given query.
  void search(String query) {
    if (_documentation == null || query.isEmpty) {
      _query = query;
      _results = [];
      notifyListeners();
      return;
    }

    _query = query;
    _isSearching = true;
    notifyListeners();

    // Perform the search asynchronously
    Future.microtask(() {
      final results = <DocumentationSearchResult>[];
      final lowercaseQuery = query.toLowerCase();

      // Search in sections
      for (final section in _documentation!.sections) {
        // Search in section title
        final titleLower = section.title.toLowerCase();
        if (titleLower.contains(lowercaseQuery)) {
          final titleMatchIndex = titleLower.indexOf(lowercaseQuery);
          results.add(DocumentationSearchResult(
            section: section,
            matchedText: section.title
                .substring(titleMatchIndex, titleMatchIndex + query.length),
            context: _highlightMatch(section.title, query),
            matchIndex: -1, // Title is special marker
          ));
        }

        // Search in section content
        final content = section.content.toLowerCase();
        int index = content.indexOf(lowercaseQuery);

        while (index != -1) {
          // Extract context around the match (up to 50 chars before and after)
          final startContext = index > 50 ? index - 50 : 0;
          final endContext = index + query.length + 50 < content.length
              ? index + query.length + 50
              : content.length;
          final contextText =
              section.content.substring(startContext, endContext);

          // Create a search result
          results.add(DocumentationSearchResult(
            section: section,
            matchedText: section.content.substring(index, index + query.length),
            context: '...${_highlightMatch(contextText, query)}...',
            matchIndex: index,
          ));

          // Find next match
          index = content.indexOf(lowercaseQuery, index + query.length);
        }
      }

      // Search in decisions
      for (final decision in _documentation!.decisions) {
        final content = decision.content.toLowerCase();
        int index = content.indexOf(lowercaseQuery);

        while (index != -1) {
          // Extract context around the match
          final startContext = index > 50 ? index - 50 : 0;
          final endContext = index + query.length + 50 < content.length
              ? index + query.length + 50
              : content.length;
          final contextText =
              decision.content.substring(startContext, endContext);

          // Create a search result
          results.add(DocumentationSearchResult(
            decision: decision,
            matchedText:
                decision.content.substring(index, index + query.length),
            context: '...${_highlightMatch(contextText, query)}...',
            matchIndex: index,
          ));

          // Find next match
          index = content.indexOf(lowercaseQuery, index + query.length);
        }

        // Also search in decision titles
        final titleLower = decision.title.toLowerCase();
        if (titleLower.contains(lowercaseQuery)) {
          results.add(DocumentationSearchResult(
            decision: decision,
            matchedText: decision.title.substring(
                titleLower.indexOf(lowercaseQuery),
                titleLower.indexOf(lowercaseQuery) + query.length),
            context: _highlightMatch(decision.title, query),
            matchIndex: 0, // Title is at the beginning
          ));
        }
      }

      // Sort results by relevance (title matches first, then by index)
      results.sort((a, b) {
        // Title matches come first (matchIndex == -1 for titles)
        final aIsTitle = a.matchIndex == -1;
        final bIsTitle = b.matchIndex == -1;

        if (aIsTitle && !bIsTitle) return -1;
        if (!aIsTitle && bIsTitle) return 1;

        // Then sort by section/decision order
        if (a.section != null && b.section != null) {
          return a.section!.order.compareTo(b.section!.order);
        }

        // Decisions come after sections
        if (a.section != null && b.decision != null) return -1;
        if (a.decision != null && b.section != null) return 1;

        // Sort decisions by date (newest first)
        if (a.decision != null && b.decision != null) {
          return b.decision!.date.compareTo(a.decision!.date);
        }

        // Default to sort by match index
        return a.matchIndex.compareTo(b.matchIndex);
      });

      _results = results;
      _isSearching = false;
      notifyListeners();
    });
  }

  /// Clears the current search.
  void clear() {
    _query = '';
    _results = [];
    _isSearching = false;
    notifyListeners();
  }

  /// Highlights the matched text in the context.
  String _highlightMatch(String text, String query) {
    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    final buffer = StringBuffer();

    int index = 0;
    int matchIndex = lowercaseText.indexOf(lowercaseQuery);

    while (matchIndex != -1) {
      // Add text before the match
      buffer.write(text.substring(index, matchIndex));

      // Add the highlighted match
      buffer.write(
          '**${text.substring(matchIndex, matchIndex + query.length)}**');

      // Update the index
      index = matchIndex + query.length;

      // Find the next match
      matchIndex = lowercaseText.indexOf(lowercaseQuery, index);
    }

    // Add any remaining text
    if (index < text.length) {
      buffer.write(text.substring(index));
    }

    return buffer.toString();
  }
}

/// A widget for searching documentation.
class DocumentationSearch extends StatefulWidget {
  /// The documentation to search.
  final Documentation documentation;

  /// The search controller.
  final DocumentationSearchController? controller;

  /// Called when a section is selected.
  final Function(int)? onSectionSelected;

  /// Called when a decision is selected.
  final Function(int)? onDecisionSelected;

  /// Whether to use dark mode.
  final bool isDarkMode;

  /// Creates a new documentation search widget.
  const DocumentationSearch({
    Key? key,
    required this.documentation,
    this.controller,
    this.onSectionSelected,
    this.onDecisionSelected,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<DocumentationSearch> createState() => _DocumentationSearchState();
}

class _DocumentationSearchState extends State<DocumentationSearch> {
  late TextEditingController _textController;
  late DocumentationSearchController _searchController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _searchController = widget.controller ?? DocumentationSearchController();
    _searchController.setDocumentation(widget.documentation);
  }

  @override
  void didUpdateWidget(DocumentationSearch oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.documentation != widget.documentation) {
      _searchController.setDocumentation(widget.documentation);
    }

    if (oldWidget.controller != widget.controller &&
        widget.controller != null) {
      _searchController = widget.controller!;
      _textController.text = _searchController.query;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    if (widget.controller == null) {
      _searchController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Search documentation...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _textController.clear();
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: (value) {
              _searchController.search(value);
            },
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _searchController,
            builder: (context, _) {
              if (_searchController.isSearching) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (_searchController.query.isEmpty) {
                return Center(
                  child: Text(
                    'Enter a search query to find content',
                    style: TextStyle(
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                );
              }

              if (_searchController.results.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color:
                            widget.isDarkMode ? Colors.white24 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results found for "${_searchController.query}"',
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: _searchController.results.length,
                itemBuilder: (context, index) {
                  final result = _searchController.results[index];

                  return ListTile(
                    title: Text(
                      result.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text.rich(
                      TextSpan(
                        children: _buildHighlightedText(result.context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: Icon(
                      result.isDecision ? Icons.assignment : Icons.description,
                      color: widget.isDarkMode
                          ? Colors.blue.shade300
                          : Colors.blue.shade700,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color:
                          widget.isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                    onTap: () {
                      if (result.isDecision) {
                        final index = widget.documentation.decisions
                            .indexOf(result.decision!);
                        if (index >= 0 && widget.onDecisionSelected != null) {
                          widget.onDecisionSelected!(index);
                        }
                      } else {
                        final index = widget.documentation.sections
                            .indexOf(result.section!);
                        if (index >= 0 && widget.onSectionSelected != null) {
                          widget.onSectionSelected!(index);
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds highlighted text spans for search results.
  List<InlineSpan> _buildHighlightedText(String highlightedText) {
    final spans = <InlineSpan>[];
    final parts = highlightedText.split('**');

    for (var i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // Regular text
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ));
      } else {
        // Highlighted text
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(
            color: widget.isDarkMode
                ? Colors.amber.shade300
                : Colors.amber.shade900,
            fontWeight: FontWeight.bold,
            backgroundColor: widget.isDarkMode
                ? Colors.amber.shade900.withValues(alpha: 0.2)
                : Colors.amber.shade100.withValues(alpha: 0.5),
          ),
        ));
      }
    }

    return spans;
  }
}
