import 'package:flutter/material.dart' hide Element, View;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_navigator.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram_controls.dart';
import 'package:flutter_structurizr/presentation/widgets/element_explorer.dart';
import 'package:flutter_structurizr/presentation/widgets/export/batch_export_dialog.dart';
import 'package:flutter_structurizr/presentation/widgets/export/export_dialog.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/structurizr_diagram.dart';

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
  
  // Key to access the diagram state
  final GlobalKey<StructurizrDiagramState> _diagramKey = GlobalKey();
  
  // Current workspace (may be updated for vertex changes)
  late Workspace _currentWorkspace;

  @override
  void initState() {
    super.initState();
    
    // Initialize with the provided workspace
    _currentWorkspace = widget.workspace;

    // Debug: print all available views
    print('DEBUG: WorkspacePage initState - checking available views');
    print(
        'DEBUG: SystemContextViews count: ${_currentWorkspace.views.systemContextViews.length}');
    if (_currentWorkspace.views.systemContextViews.isNotEmpty) {
      print(
          'DEBUG: First SystemContextView key: ${_currentWorkspace.views.systemContextViews.first.key}');
      print(
          'DEBUG: First SystemContextView title: ${_currentWorkspace.views.systemContextViews.first.title}');
      print(
          'DEBUG: First SystemContextView elements count: ${_currentWorkspace.views.systemContextViews.first.elements.length}');
    }

    // Set initial view if available
    if (_currentWorkspace.views.systemContextViews.isNotEmpty) {
      _selectedViewKey = _currentWorkspace.views.systemContextViews.first.key;
      print('DEBUG: Selected view key: $_selectedViewKey');
    } else if (_currentWorkspace.views.containerViews.isNotEmpty) {
      _selectedViewKey = _currentWorkspace.views.containerViews.first.key;
    } else if (_currentWorkspace.views.componentViews.isNotEmpty) {
      _selectedViewKey = _currentWorkspace.views.componentViews.first.key;
    } else if (_currentWorkspace.views.deploymentViews.isNotEmpty) {
      _selectedViewKey = _currentWorkspace.views.deploymentViews.first.key;
    }

    print('DEBUG: Final selected view key: $_selectedViewKey');
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentWorkspace.name),
          actions: [
            // Export button
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export',
              onPressed: _selectedViewKey != null
                  ? () {
                      _showExportDialog();
                    }
                  : null,
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
              const Tab(
                icon: Icon(Icons.account_tree),
                text: 'Diagrams',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              const Tab(
                icon: Icon(Icons.description),
                text: 'Documentation',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
            ],
          ),
        ),
        body: _currentTab == WorkspaceTab.diagrams
            ? _buildDiagramsView(isDarkMode)
            : _buildDocumentationView(isDarkMode),
      ),
    );
  }

  Widget _buildDiagramsView(bool isDarkMode) {
    print(
        'DEBUG: _buildDiagramsView called with selectedViewKey: $_selectedViewKey');

    if (_selectedViewKey == null) {
      print('DEBUG: No selected view key, showing no views message');
      return const Center(
        child: Text('No views available in this workspace'),
      );
    }

    final selectedView = _currentWorkspace.views.getViewByKey(_selectedViewKey!);
    print('DEBUG: Retrieved view by key: ${selectedView?.key}');
    print('DEBUG: View is null: ${selectedView == null}');
    if (selectedView != null) {
      print('DEBUG: View elements count: ${selectedView.elements.length}');
      print(
          'DEBUG: View relationships count: ${selectedView.relationships.length}');
    }

    return Row(
      children: [
        // Element explorer sidebar
        SizedBox(
          width: 280,
          child: ElementExplorer(
            workspace: _currentWorkspace,
            selectedView: _selectedViewKey != null
                ? _currentWorkspace.views.getViewByKey(_selectedViewKey!)
                : null,
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
          flex: 3,
          child: _selectedViewKey != null
              ? Stack(
                  children: [
                    // Diagram canvas (fills entire space)
                    Container(
                      constraints: const BoxConstraints.expand(),
                      child: () {
                        final view = _currentWorkspace.views
                            .getViewByKey(_selectedViewKey!)!;
                        print('DEBUG: [WorkspacePage] Passing view to StructurizrDiagram');
                        print('DEBUG: [WorkspacePage] View key: ${view.key}');
                        print('DEBUG: [WorkspacePage] View elements: ${view.elements.length}');
                        print('DEBUG: [WorkspacePage] View relationships: ${view.relationships.length}');
                        return StructurizrDiagram(
                          key: _diagramKey,
                          workspace: _currentWorkspace,
                          view: view,
                          config: const StructurizrDiagramConfig(
                            isEditable: true, // Re-enable element dragging
                            enablePanAndZoom: true,
                            showGrid: true,
                            fitToScreen: true,
                            centerOnStart: true,
                          ),
                          onRelationshipVerticesChanged: (relationshipId, vertices) {
                            print('DEBUG: WorkspacePage - Relationship vertices changed for $relationshipId, ${vertices.length} vertices');
                            // Update the view with new vertices
                            _updateRelationshipVertices(relationshipId, vertices);
                          },
                        );
                      }(),
                    ),

                    // Diagram controls (positioned at bottom right)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? Colors.grey.shade900.withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: DiagramControls(
                          onZoomIn: () {
                            // Zoom in centered on canvas
                            final state = _diagramKey.currentState;
                            if (state != null) {
                              final currentZoom = state.getZoomScale();
                              final newZoom = (currentZoom * 1.2).clamp(0.1, 3.0);
                              
                              // Calculate center of viewport
                              final RenderBox? box = _diagramKey.currentContext?.findRenderObject() as RenderBox?;
                              if (box != null) {
                                final center = Offset(box.size.width / 2, box.size.height / 2);
                                
                                // Calculate the diagram point at center
                                final currentPan = state.getPanOffset();
                                final diagramPoint = (center - currentPan) / currentZoom;
                                
                                // Calculate new pan to keep center point stationary
                                final newPan = center - diagramPoint * newZoom;
                                
                                // Apply the zoom with animation
                                state.animateToZoomAndPan(newZoom, newPan);
                              }
                            }
                          },
                          onZoomOut: () {
                            // Zoom out centered on canvas
                            final state = _diagramKey.currentState;
                            if (state != null) {
                              final currentZoom = state.getZoomScale();
                              final newZoom = (currentZoom / 1.2).clamp(0.1, 3.0);
                              
                              // Calculate center of viewport
                              final RenderBox? box = _diagramKey.currentContext?.findRenderObject() as RenderBox?;
                              if (box != null) {
                                final center = Offset(box.size.width / 2, box.size.height / 2);
                                
                                // Calculate the diagram point at center
                                final currentPan = state.getPanOffset();
                                final diagramPoint = (center - currentPan) / currentZoom;
                                
                                // Calculate new pan to keep center point stationary
                                final newPan = center - diagramPoint * newZoom;
                                
                                // Apply the zoom with animation
                                state.animateToZoomAndPan(newZoom, newPan);
                              }
                            }
                          },
                          onResetView: () {
                            // Reset to default zoom and center
                            final state = _diagramKey.currentState;
                            state?.animateToZoomAndPan(1.0, Offset.zero);
                          },
                          onFitToScreen: () {
                            // Fit all elements to screen
                            final state = _diagramKey.currentState;
                            state?.fitToScreen();
                          },
                          // Custom config can be added here
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text(
                    'No view selected',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDocumentationView(bool isDarkMode) {
    return DocumentationNavigator(
      workspace: _currentWorkspace,
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
        workspace: _currentWorkspace,
        viewKey: _selectedViewKey!,
      ),
    );
  }

  /// Shows the batch export dialog for multiple diagrams
  void _showBatchExportDialog() {
    showDialog(
      context: context,
      builder: (context) => BatchExportDialog(
        workspace: _currentWorkspace,
      ),
    );
  }
  
  /// Updates relationship vertices in the current view
  void _updateRelationshipVertices(String relationshipId, List<Vertex> vertices) {
    setState(() {
      final view = _currentWorkspace.views.getViewByKey(_selectedViewKey!);
      if (view == null) return;
      
      final relationshipIndex = view.relationships.indexWhere((r) => r.id == relationshipId);
      if (relationshipIndex == -1) return;
      
      // Create updated relationship view
      final updatedRelationshipView = view.relationships[relationshipIndex].copyWith(
        vertices: vertices,
      );
      
      // Create updated relationships list
      final updatedRelationships = List<RelationshipView>.from(view.relationships);
      updatedRelationships[relationshipIndex] = updatedRelationshipView;
      
      // Create updated view with new relationships
      View updatedView;
      if (view is SystemContextView) {
        updatedView = view.copyWith(relationships: updatedRelationships);
      } else if (view is ContainerView) {
        updatedView = view.copyWith(relationships: updatedRelationships);
      } else if (view is ComponentView) {
        updatedView = view.copyWith(relationships: updatedRelationships);
      } else if (view is DeploymentView) {
        updatedView = view.copyWith(relationships: updatedRelationships);
      } else {
        // For other view types, just return
        return;
      }
      
      // Update the views in the workspace
      Views updatedViews;
      if (view is SystemContextView) {
        final viewIndex = _currentWorkspace.views.systemContextViews.indexWhere((v) => v.key == view.key);
        if (viewIndex != -1) {
          final updatedSystemContextViews = List<SystemContextView>.from(_currentWorkspace.views.systemContextViews);
          updatedSystemContextViews[viewIndex] = updatedView as SystemContextView;
          updatedViews = _currentWorkspace.views.copyWith(systemContextViews: updatedSystemContextViews);
        } else {
          return;
        }
      } else if (view is ContainerView) {
        final viewIndex = _currentWorkspace.views.containerViews.indexWhere((v) => v.key == view.key);
        if (viewIndex != -1) {
          final updatedContainerViews = List<ContainerView>.from(_currentWorkspace.views.containerViews);
          updatedContainerViews[viewIndex] = updatedView as ContainerView;
          updatedViews = _currentWorkspace.views.copyWith(containerViews: updatedContainerViews);
        } else {
          return;
        }
      } else if (view is ComponentView) {
        final viewIndex = _currentWorkspace.views.componentViews.indexWhere((v) => v.key == view.key);
        if (viewIndex != -1) {
          final updatedComponentViews = List<ComponentView>.from(_currentWorkspace.views.componentViews);
          updatedComponentViews[viewIndex] = updatedView as ComponentView;
          updatedViews = _currentWorkspace.views.copyWith(componentViews: updatedComponentViews);
        } else {
          return;
        }
      } else if (view is DeploymentView) {
        final viewIndex = _currentWorkspace.views.deploymentViews.indexWhere((v) => v.key == view.key);
        if (viewIndex != -1) {
          final updatedDeploymentViews = List<DeploymentView>.from(_currentWorkspace.views.deploymentViews);
          updatedDeploymentViews[viewIndex] = updatedView as DeploymentView;
          updatedViews = _currentWorkspace.views.copyWith(deploymentViews: updatedDeploymentViews);
        } else {
          return;
        }
      } else {
        return;
      }
      
      // Create updated workspace
      _currentWorkspace = _currentWorkspace.copyWith(views: updatedViews);
      
      print('DEBUG: Successfully updated workspace with new relationship vertices');
    });
  }
}
