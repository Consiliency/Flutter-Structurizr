import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_navigator.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram_controls.dart';
import 'package:flutter_structurizr/presentation/widgets/element_explorer.dart';
import 'package:flutter_structurizr/presentation/widgets/export/batch_export_dialog.dart';
import 'package:flutter_structurizr/presentation/widgets/export/export_dialog.dart';
import 'package:flutter_structurizr/presentation/widgets/structurizr_diagram.dart';

/// Tab options for the workspace page
enum WorkspaceTab {
  /// Diagrams view showing the diagram editor and controls
  diagrams,
  
  /// Documentation view showing documentation and ADRs
  documentation
}

/// A page that displays a Structurizr workspace with both diagram and documentation views
class WorkspacePage extends StatefulWidget {
  /// The workspace to display
  final Workspace workspace;

  /// Creates a new workspace page
  const WorkspacePage({
    Key? key,
    required this.workspace,
  }) : super(key: key);

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  // The currently selected tab
  WorkspaceTab _currentTab = WorkspaceTab.diagrams;

  // The currently selected view key
  String? _selectedViewKey;

  // The DocumentationNavigator controller
  final _documentationController = DocumentationNavigatorController();

  @override
  void initState() {
    super.initState();
    
    // Set initial view if available
    if (widget.workspace.views.systemContextViews.isNotEmpty) {
      _selectedViewKey = widget.workspace.views.systemContextViews.first.key;
    } else if (widget.workspace.views.containerViews.isNotEmpty) {
      _selectedViewKey = widget.workspace.views.containerViews.first.key;
    } else if (widget.workspace.views.componentViews.isNotEmpty) {
      _selectedViewKey = widget.workspace.views.componentViews.first.key;
    } else if (widget.workspace.views.deploymentViews.isNotEmpty) {
      _selectedViewKey = widget.workspace.views.deploymentViews.first.key;
    }
  }

  @override
  void dispose() {
    _documentationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workspace.name),
        actions: [
          // Export button
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: _selectedViewKey != null ? () {
              _showExportDialog();
            } : null,
          ),

          // Batch export button
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            tooltip: 'Batch Export',
            onPressed: () {
              _showBatchExportDialog();
            },
          ),
          
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              // TODO: Show settings dialog
            },
          ),
        ],
        bottom: TabBar(
          onTap: (index) {
            setState(() {
              _currentTab = WorkspaceTab.values[index];
            });
          },
          tabs: [
            Tab(
              icon: const Icon(Icons.account_tree),
              text: 'Diagrams',
              iconMargin: const EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: const Icon(Icons.description),
              text: 'Documentation',
              iconMargin: const EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
      ),
      body: _currentTab == WorkspaceTab.diagrams
          ? _buildDiagramsView(isDarkMode)
          : _buildDocumentationView(isDarkMode),
    );
  }

  Widget _buildDiagramsView(bool isDarkMode) {
    if (_selectedViewKey == null) {
      return const Center(
        child: Text('No views available in this workspace'),
      );
    }

    return Row(
      children: [
        // Element explorer sidebar
        SizedBox(
          width: 280,
          child: ElementExplorer(
            workspace: widget.workspace,
            selectedViewKey: _selectedViewKey,
            onViewSelected: (viewKey) {
              setState(() {
                _selectedViewKey = viewKey;
              });
            },
          ),
        ),
        
        // Divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
        
        // Main diagram area
        Expanded(
          child: Column(
            children: [
              // Diagram controls
              DiagramControls(
                onExport: () {
                  _showExportDialog();
                },
              ),
              
              // Diagram canvas
              Expanded(
                child: StructurizrDiagram(
                  workspace: widget.workspace,
                  viewKey: _selectedViewKey!,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentationView(bool isDarkMode) {
    return DocumentationNavigator(
      workspace: widget.workspace,
      controller: _documentationController,
      isDarkMode: isDarkMode,
      onDiagramSelected: (viewKey) {
        setState(() {
          _selectedViewKey = viewKey;
          _currentTab = WorkspaceTab.diagrams;
        });
      },
    );
  }

  /// Shows the export dialog for the current diagram
  void _showExportDialog() {
    if (_selectedViewKey == null) return;

    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        workspace: widget.workspace,
        viewKey: _selectedViewKey!,
      ),
    );
  }

  /// Shows the batch export dialog for multiple diagrams
  void _showBatchExportDialog() {
    showDialog(
      context: context,
      builder: (context) => BatchExportDialog(
        workspace: widget.workspace,
      ),
    );
  }
}