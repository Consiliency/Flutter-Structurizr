import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/asciidoc_renderer.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_graph.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_timeline.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_search.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/markdown_renderer.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/table_of_contents.dart';

/// View mode for documentation navigation.
enum DocumentationViewMode {
  documentation,
  decisions,
  decisionGraph,
  decisionTimeline,
  search,
}

/// A controller for managing documentation navigation state.
class DocumentationNavigatorController extends ChangeNotifier {
  /// Currently selected section index.
  int _currentSectionIndex = 0;

  /// Currently selected decision index.
  int _currentDecisionIndex = -1;

  /// Current view mode.
  DocumentationViewMode _viewMode = DocumentationViewMode.documentation;

  /// Whether the content panel is expanded (hiding the table of contents).
  bool _contentExpanded = false;

  /// Currently selected section index.
  int get currentSectionIndex => _currentSectionIndex;

  /// Currently selected decision index.
  int get currentDecisionIndex => _currentDecisionIndex;

  /// Current view mode.
  DocumentationViewMode get viewMode => _viewMode;

  /// Whether decisions are being viewed in detail mode.
  bool get viewingDecisions => _viewMode == DocumentationViewMode.decisions;

  /// Whether the content panel is expanded.
  bool get contentExpanded => _contentExpanded;

  /// Sets the current section index and notifies listeners.
  void navigateToSection(int index) {
    if (_currentSectionIndex != index || _viewMode != DocumentationViewMode.documentation) {
      _currentSectionIndex = index;
      _viewMode = DocumentationViewMode.documentation;
      notifyListeners();
    }
  }

  /// Sets the current decision index and notifies listeners.
  void navigateToDecision(int index) {
    if (_currentDecisionIndex != index || _viewMode != DocumentationViewMode.decisions) {
      _currentDecisionIndex = index;
      _viewMode = DocumentationViewMode.decisions;
      notifyListeners();
    }
  }

  /// Shows the decision graph view.
  void showDecisionGraph() {
    if (_viewMode != DocumentationViewMode.decisionGraph) {
      _viewMode = DocumentationViewMode.decisionGraph;
      notifyListeners();
    }
  }

  /// Shows the decision timeline view.
  void showDecisionTimeline() {
    if (_viewMode != DocumentationViewMode.decisionTimeline) {
      _viewMode = DocumentationViewMode.decisionTimeline;
      notifyListeners();
    }
  }

  /// Shows the search view.
  void showSearch() {
    if (_viewMode != DocumentationViewMode.search) {
      _viewMode = DocumentationViewMode.search;
      notifyListeners();
    }
  }

  /// Switches between documentation and decisions view.
  void toggleDecisionsView() {
    if (_viewMode == DocumentationViewMode.documentation) {
      _viewMode = DocumentationViewMode.decisions;
    } else if (_viewMode == DocumentationViewMode.decisions) {
      _viewMode = DocumentationViewMode.documentation;
    } else {
      // From other views, go back to documentation
      _viewMode = DocumentationViewMode.documentation;
    }
    notifyListeners();
  }

  /// Toggles content panel expansion.
  void toggleContentExpansion() {
    _contentExpanded = !_contentExpanded;
    notifyListeners();
  }
}

/// A widget for navigating documentation sections and architecture decisions.
class DocumentationNavigator extends StatefulWidget {
  /// The workspace containing the documentation.
  final Workspace workspace;

  /// The controller for managing navigation state.
  final DocumentationNavigatorController? controller;

  /// Initially selected documentation section.
  final int initialSectionIndex;

  /// Whether to use dark mode.
  final bool isDarkMode;

  /// Called when a diagram is selected from documentation.
  final Function(String)? onDiagramSelected;

  /// Whether to show the toolbar with additional controls.
  final bool showToolbar;

  /// Creates a new documentation navigator widget.
  const DocumentationNavigator({
    Key? key,
    required this.workspace,
    this.controller,
    this.initialSectionIndex = 0,
    this.isDarkMode = false,
    this.onDiagramSelected,
    this.showToolbar = true,
  }) : super(key: key);

  @override
  State<DocumentationNavigator> createState() => _DocumentationNavigatorState();
}

class _DocumentationNavigatorState extends State<DocumentationNavigator> {
  late DocumentationNavigatorController _controller;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DocumentationNavigatorController();
    _scrollController = ScrollController();

    if (widget.initialSectionIndex != 0) {
      _controller.navigateToSection(widget.initialSectionIndex);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentation = widget.workspace.documentation;

    if (documentation == null) {
      return const Center(
        child: Text('No documentation available for this workspace.'),
      );
    }

    // Sort sections by order
    final sections = List<DocumentationSection>.from(documentation.sections)
      ..sort((a, b) => a.order.compareTo(b.order));

    final decisions = documentation.decisions;
    final hasDecisions = decisions.isNotEmpty;
    final hasSections = sections.isNotEmpty;

    if (!hasSections && !hasDecisions) {
      return const Center(
        child: Text('No documentation or decisions available for this workspace.'),
      );
    }

    // Initialize the search controller if needed
    final searchController = DocumentationSearchController();
    if (documentation != null) {
      searchController.setDocumentation(documentation);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final viewMode = _controller.viewMode;
        final currentSection = viewMode == DocumentationViewMode.documentation && hasSections
            ? sections[_controller.currentSectionIndex]
            : null;
        final currentDecision = viewMode == DocumentationViewMode.decisions && hasDecisions
            ? decisions[_controller.currentDecisionIndex]
            : null;

        final bool showToc = !_controller.contentExpanded &&
            (hasSections || hasDecisions) &&
            viewMode != DocumentationViewMode.decisionGraph &&
            viewMode != DocumentationViewMode.decisionTimeline;

        return Column(
          children: [
            // Optional toolbar
            if (widget.showToolbar)
              _buildToolbar(hasSections, hasDecisions),

            // Main content area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left sidebar with table of contents
                  if (showToc)
                    SizedBox(
                      width: 280,
                      child: TableOfContents(
                        sections: sections,
                        decisions: decisions,
                        currentSectionIndex: _controller.currentSectionIndex,
                        currentDecisionIndex: _controller.currentDecisionIndex,
                        viewingDecisions: _controller.viewingDecisions,
                        onSectionSelected: _controller.navigateToSection,
                        onDecisionSelected: _controller.navigateToDecision,
                        onToggleView: _controller.toggleDecisionsView,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),

                  // Divider
                  if (showToc)
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                    ),

                  // Main content
                  Expanded(
                    child: _buildMainContent(viewMode, currentSection, currentDecision, searchController),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the toolbar with navigation and view controls.
  Widget _buildToolbar(bool hasSections, bool hasDecisions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade300,
          ),
        ),
        color: widget.isDarkMode
            ? Colors.grey.shade900
            : Colors.grey.shade50,
      ),
      child: Row(
        children: [
          // Navigation breadcrumbs
          Expanded(
            child: _buildBreadcrumbs(),
          ),

          // View controls
          if (hasSections)
            IconButton(
              icon: const Icon(Icons.description),
              tooltip: 'Documentation',
              color: _controller.viewMode == DocumentationViewMode.documentation
                  ? (widget.isDarkMode ? Colors.blue.shade300 : Colors.blue)
                  : (widget.isDarkMode ? Colors.white70 : Colors.black54),
              onPressed: () {
                _controller.navigateToSection(_controller.currentSectionIndex);
              },
            ),

          if (hasDecisions) ...[
            IconButton(
              icon: const Icon(Icons.assignment),
              tooltip: 'Decisions',
              color: _controller.viewMode == DocumentationViewMode.decisions
                  ? (widget.isDarkMode ? Colors.blue.shade300 : Colors.blue)
                  : (widget.isDarkMode ? Colors.white70 : Colors.black54),
              onPressed: () {
                if (_controller.currentDecisionIndex < 0 && decisions.isNotEmpty) {
                  _controller.navigateToDecision(0);
                } else {
                  _controller.navigateToDecision(_controller.currentDecisionIndex);
                }
              },
            ),

            IconButton(
              icon: const Icon(Icons.account_tree),
              tooltip: 'Decision Graph',
              color: _controller.viewMode == DocumentationViewMode.decisionGraph
                  ? (widget.isDarkMode ? Colors.blue.shade300 : Colors.blue)
                  : (widget.isDarkMode ? Colors.white70 : Colors.black54),
              onPressed: () {
                _controller.showDecisionGraph();
              },
            ),

            IconButton(
              icon: const Icon(Icons.timeline),
              tooltip: 'Decision Timeline',
              color: _controller.viewMode == DocumentationViewMode.decisionTimeline
                  ? (widget.isDarkMode ? Colors.blue.shade300 : Colors.blue)
                  : (widget.isDarkMode ? Colors.white70 : Colors.black54),
              onPressed: () {
                _controller.showDecisionTimeline();
              },
            ),
          ],

          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            color: _controller.viewMode == DocumentationViewMode.search
                ? (widget.isDarkMode ? Colors.blue.shade300 : Colors.blue)
                : (widget.isDarkMode ? Colors.white70 : Colors.black54),
            onPressed: () {
              _controller.showSearch();
            },
          ),

          IconButton(
            icon: Icon(_controller.contentExpanded ? Icons.fullscreen_exit : Icons.fullscreen),
            tooltip: _controller.contentExpanded ? 'Show navigation' : 'Expand content',
            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
            onPressed: () {
              _controller.toggleContentExpansion();
            },
          ),
        ],
      ),
    );
  }

  /// Builds breadcrumb navigation.
  Widget _buildBreadcrumbs() {
    final viewMode = _controller.viewMode;
    final List<Widget> crumbs = [];

    // Add documentation root
    crumbs.add(
      TextButton(
        onPressed: () {
          _controller.navigateToSection(0);
        },
        child: Text(
          'Documentation',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );

    // Add separator
    crumbs.add(
      Text(
        ' / ',
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white54 : Colors.black45,
        ),
      ),
    );

    // Add view-specific breadcrumb
    switch (viewMode) {
      case DocumentationViewMode.documentation:
        if (widget.workspace.documentation?.sections.isNotEmpty == true) {
          final section = widget.workspace.documentation!.sections[_controller.currentSectionIndex];
          crumbs.add(
            Expanded(
              child: Text(
                section.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
        break;

      case DocumentationViewMode.decisions:
        crumbs.add(
          TextButton(
            onPressed: () {
              // Show all decisions (i.e., timeline or graph)
              _controller.showDecisionTimeline();
            },
            child: Text(
              'Decisions',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );

        if (widget.workspace.documentation?.decisions.isNotEmpty == true &&
            _controller.currentDecisionIndex >= 0) {
          // Add another separator
          crumbs.add(
            Text(
              ' / ',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white54 : Colors.black45,
              ),
            ),
          );

          // Add current decision
          final decision = widget.workspace.documentation!.decisions[_controller.currentDecisionIndex];
          crumbs.add(
            Expanded(
              child: Text(
                decision.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
        break;

      case DocumentationViewMode.decisionGraph:
        crumbs.add(
          Expanded(
            child: Text(
              'Decision Graph',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
        break;

      case DocumentationViewMode.decisionTimeline:
        crumbs.add(
          Expanded(
            child: Text(
              'Decision Timeline',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
        break;

      case DocumentationViewMode.search:
        crumbs.add(
          Expanded(
            child: Text(
              'Search Documentation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
        break;
    }

    return Row(
      children: crumbs,
    );
  }

  /// Builds the main content area based on the current view mode.
  Widget _buildMainContent(
    DocumentationViewMode viewMode,
    DocumentationSection? currentSection,
    Decision? currentDecision,
    DocumentationSearchController searchController,
  ) {
    switch (viewMode) {
      case DocumentationViewMode.documentation:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Content header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: widget.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                  ),
                ),
                color: widget.isDarkMode
                    ? Colors.grey.shade900
                    : Colors.grey.shade50,
              ),
              child: _buildSectionHeader(currentSection),
            ),

            // Content body
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24.0),
                child: _buildSectionContent(currentSection),
              ),
            ),
          ],
        );

      case DocumentationViewMode.decisions:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Content header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: widget.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                  ),
                ),
                color: widget.isDarkMode
                    ? Colors.grey.shade900
                    : Colors.grey.shade50,
              ),
              child: _buildDecisionHeader(currentDecision),
            ),

            // Content body
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24.0),
                child: _buildDecisionContent(currentDecision),
              ),
            ),
          ],
        );

      case DocumentationViewMode.decisionGraph:
        if (widget.workspace.documentation?.decisions.isEmpty != false) {
          return const Center(
            child: Text('No decisions available to visualize'),
          );
        }

        return DecisionGraph(
          decisions: widget.workspace.documentation!.decisions,
          onDecisionSelected: _controller.navigateToDecision,
          isDarkMode: widget.isDarkMode,
        );

      case DocumentationViewMode.decisionTimeline:
        if (widget.workspace.documentation?.decisions.isEmpty != false) {
          return const Center(
            child: Text('No decisions available to visualize'),
          );
        }

        return DecisionTimeline(
          decisions: widget.workspace.documentation!.decisions,
          onDecisionSelected: _controller.navigateToDecision,
          isDarkMode: widget.isDarkMode,
        );

      case DocumentationViewMode.search:
        if (widget.workspace.documentation == null) {
          return const Center(
            child: Text('No documentation available to search'),
          );
        }

        return DocumentationSearch(
          documentation: widget.workspace.documentation!,
          controller: searchController,
          onSectionSelected: _controller.navigateToSection,
          onDecisionSelected: _controller.navigateToDecision,
          isDarkMode: widget.isDarkMode,
        );
    }
  }

  Widget _buildSectionHeader(DocumentationSection? section) {
    if (section == null) {
      return const Text('No section selected');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        if (section.filename != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Source: ${section.filename}',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        if (section.elementId != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Related to: ${section.elementId}',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionContent(DocumentationSection? section) {
    if (section == null) {
      return const SizedBox();
    }

    if (section.format == DocumentationFormat.asciidoc) {
      // Use our new AsciiDoc renderer
      return AsciidocRenderer(
        content: section.content,
        workspace: widget.workspace,
        onDiagramSelected: widget.onDiagramSelected,
        isDarkMode: widget.isDarkMode,
      );
    }

    // Render Markdown content
    return MarkdownRenderer(
      content: section.content,
      workspace: widget.workspace,
      onDiagramSelected: widget.onDiagramSelected,
      isDarkMode: widget.isDarkMode,
      enableSectionNumbering: true,
    );
  }

  Widget _buildDecisionHeader(Decision? decision) {
    if (decision == null) {
      return const Text('No decision selected');
    }

    // Map common decision statuses to colors
    Color statusColor;
    switch (decision.status.toLowerCase()) {
      case 'proposed':
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'superseded':
        statusColor = Colors.purple;
        break;
      case 'deprecated':
        statusColor = Colors.red;
        break;
      case 'rejected':
        statusColor = Colors.red.shade900;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                decision.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(widget.isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: statusColor.withOpacity(widget.isDarkMode ? 0.5 : 0.3),
                ),
              ),
              child: Text(
                decision.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'ID: ${decision.id} • Date: ${_formatDate(decision.date)}',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        if (decision.elementId != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Related to: ${decision.elementId}',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDecisionContent(Decision? decision) {
    if (decision == null) {
      return const SizedBox();
    }

    if (decision.format == DocumentationFormat.asciidoc) {
      // Use our new AsciiDoc renderer for decisions as well
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decision content in AsciiDoc format
          AsciidocRenderer(
            content: decision.content,
            workspace: widget.workspace,
            onDiagramSelected: widget.onDiagramSelected,
            isDarkMode: widget.isDarkMode,
          ),

          // Add linked decisions if any
          if (decision.links.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Linked Decisions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: decision.links.map((link) {
                    final linkedDecision = widget.workspace.documentation?.decisions
                        .firstWhere((d) => d.id == link, orElse: () => Decision(
                          id: link,
                          date: DateTime.now(),
                          status: 'Unknown',
                          title: link,
                          content: '',
                        ));

                    return ActionChip(
                      avatar: Icon(
                        Icons.link,
                        size: 16,
                        color: widget.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                      ),
                      label: Text(linkedDecision?.title ?? link),
                      onPressed: () {
                        if (linkedDecision != null) {
                          final index = widget.workspace.documentation?.decisions
                              .indexWhere((d) => d.id == link) ?? -1;
                          if (index >= 0) {
                            _controller.navigateToDecision(index);
                          }
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      );
    }

    // Render Markdown content
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Decision content
        MarkdownRenderer(
          content: decision.content,
          workspace: widget.workspace,
          onDiagramSelected: widget.onDiagramSelected,
          isDarkMode: widget.isDarkMode,
          enableSectionNumbering: false,
        ),
        
        // Add linked decisions if any
        if (decision.links.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Linked Decisions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: decision.links.map((link) {
                  final linkedDecision = widget.workspace.documentation?.decisions
                      .firstWhere((d) => d.id == link, orElse: () => Decision(
                        id: link, 
                        date: DateTime.now(), 
                        status: 'Unknown', 
                        title: link, 
                        content: '',
                      ));
                  
                  return ActionChip(
                    avatar: Icon(
                      Icons.link,
                      size: 16,
                      color: widget.isDarkMode ? Colors.blue.shade300 : Colors.blue,
                    ),
                    label: Text(linkedDecision?.title ?? link),
                    onPressed: () {
                      if (linkedDecision != null) {
                        final index = widget.workspace.documentation?.decisions
                            .indexWhere((d) => d.id == link) ?? -1;
                        if (index >= 0) {
                          _controller.navigateToDecision(index);
                        }
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}