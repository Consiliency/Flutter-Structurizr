import 'package:flutter/material.dart' as flutter hide Element, View;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/component.dart'
    as model_component;
import 'package:flutter_structurizr/domain/model/container.dart'
    as model_container;
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/presentation/widgets/element_explorer.dart';

/// Example demonstrating the ElementExplorer widget with context menu functionality
void main() {
  flutter.runApp(const ElementExplorerExampleApp());
}

/// Main application widget
class ElementExplorerExampleApp extends flutter.StatelessWidget {
  /// Creates a new example app
  const ElementExplorerExampleApp({flutter.Key? key}) : super(key: key);

  @override
  flutter.Widget build(flutter.BuildContext context) {
    return flutter.MaterialApp(
      title: 'ElementExplorer Example',
      theme: flutter.ThemeData(
        primarySwatch: flutter.Colors.blue,
        brightness: flutter.Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: flutter.ThemeData(
        brightness: flutter.Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: flutter.ThemeMode.system,
      home: const ElementExplorerExamplePage(),
    );
  }
}

/// Main page for the example
class ElementExplorerExamplePage extends flutter.StatefulWidget {
  /// Creates a new example page
  const ElementExplorerExamplePage({flutter.Key? key}) : super(key: key);

  @override
  flutter.State<ElementExplorerExamplePage> createState() =>
      _ElementExplorerExamplePageState();
}

class _ElementExplorerExamplePageState
    extends flutter.State<ElementExplorerExamplePage> {
  /// The currently selected element ID
  String? _selectedElementId;

  /// The most recent action performed
  String? _lastAction;

  /// Sample workspace for the example
  late final Workspace _workspace;

  /// Context menu items for the explorer
  late final List<ElementContextMenuItem> _contextMenuItems;

  @override
  void initState() {
    super.initState();
    _workspace = _createSampleWorkspace();
    _contextMenuItems = _createContextMenuItems();
  }

  /// Create a sample workspace with elements for the example
  Workspace _createSampleWorkspace() {
    // Create users
    final user = Person.create(
      name: 'User',
      description: 'A user of the system',
      tags: ['Person', 'External'],
    );

    final admin = Person.create(
      name: 'Administrator',
      description: 'System administrator',
      tags: ['Person', 'Internal'],
    );

    // Create the main software system
    final ecommerceSystem = SoftwareSystem.create(
      name: 'E-Commerce System',
      description: 'Handles online shopping and order management',
      tags: ['SoftwareSystem', 'Internal'],
    );

    // Create containers for the e-commerce system
    final webApp = model_container.Container(
      id: 'webApp',
      parentId: ecommerceSystem.id,
      name: 'Web Application',
      description: 'Provides the main web interface',
      technology: 'Flutter Web, Dart',
      tags: ['Container', 'WebApp'],
    );

    final mobileApp = model_container.Container(
      id: 'mobileApp',
      parentId: ecommerceSystem.id,
      name: 'Mobile Application',
      description: 'Native mobile application for iOS and Android',
      technology: 'Flutter, Dart',
      tags: ['Container', 'MobileApp'],
    );

    final apiGateway = model_container.Container(
      id: 'apiGateway',
      parentId: ecommerceSystem.id,
      name: 'API Gateway',
      description: 'Handles authentication and API routing',
      technology: 'Node.js, Express',
      tags: ['Container', 'Gateway'],
    );

    final database = model_container.Container(
      id: 'database',
      parentId: ecommerceSystem.id,
      name: 'Database',
      description: 'Stores product and order information',
      technology: 'PostgreSQL',
      tags: ['Container', 'Database'],
    );

    // Create components for the API Gateway
    final authComponent = model_component.Component(
      id: 'authComponent',
      parentId: apiGateway.id,
      name: 'Authentication Component',
      description: 'Handles user authentication and authorization',
      technology: 'JWT, OAuth2',
      tags: ['Component', 'Security'],
    );

    final routingComponent = model_component.Component(
      id: 'routingComponent',
      parentId: apiGateway.id,
      name: 'Routing Component',
      description: 'Routes API requests to appropriate services',
      technology: 'Express Router',
      tags: ['Component'],
    );

    // Create a supporting system
    final paymentSystem = SoftwareSystem.create(
      name: 'Payment Processing System',
      description: 'Processes credit card and other payment methods',
      tags: ['SoftwareSystem', 'External'],
    );

    // Update containers to include components
    final apiGatewayWithComponents = apiGateway.copyWith(
      components: [authComponent, routingComponent],
    );

    // Create the complete software system with containers
    final ecommerceSystemComplete = ecommerceSystem.copyWith(
      containers: [webApp, mobileApp, apiGatewayWithComponents, database],
    );

    // Create model with all elements
    final model = Model(
      people: [user, admin],
      softwareSystems: [ecommerceSystemComplete, paymentSystem],
    );

    // Create workspace
    return Workspace(
      id: 1,
      name: 'ElementExplorer Example',
      description:
          'Example workspace for demonstrating ElementExplorer with context menus',
      model: model,
    );
  }

  /// Create context menu items for the ElementExplorer
  List<ElementContextMenuItem> _createContextMenuItems() {
    return [
      const ElementContextMenuItem(
        id: 'view',
        label: 'View Details',
        icon: flutter.Icons.info_outline,
      ),
      const ElementContextMenuItem(
        id: 'edit',
        label: 'Edit Element',
        icon: flutter.Icons.edit,
      ),
      const ElementContextMenuItem(
        id: 'add_relationship',
        label: 'Add Relationship',
        icon: flutter.Icons.add_link,
      ),
      ElementContextMenuItem(
        id: 'delete',
        label: 'Delete Element',
        icon: flutter.Icons.delete,
        // Only enabled for components and containers
        filter: (element) =>
            element.type == 'Component' || element.type == 'Container',
      ),
      ElementContextMenuItem(
        id: 'add_container',
        label: 'Add Container',
        icon: flutter.Icons.add_box,
        // Only for software systems
        filter: (element) => element.type == 'SoftwareSystem',
      ),
      ElementContextMenuItem(
        id: 'add_component',
        label: 'Add Component',
        icon: flutter.Icons.add_circle,
        // Only for containers
        filter: (element) => element.type == 'Container',
      ),
    ];
  }

  @override
  flutter.Widget build(flutter.BuildContext context) {
    final theme = flutter.Theme.of(context);
    final colorScheme = theme.colorScheme;

    return flutter.Scaffold(
      appBar: flutter.AppBar(
        title: const flutter.Text('ElementExplorer Example'),
      ),
      body: flutter.Row(
        children: [
          // Left panel with ElementExplorer
          flutter.Container(
            width: 300,
            decoration: flutter.BoxDecoration(
              border: flutter.Border(
                right: flutter.BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: ElementExplorer(
              workspace: _workspace,
              selectedElementId: _selectedElementId,
              config: ElementExplorerConfig(
                initiallyExpanded: true,
                enableContextMenu: true,
                contextMenuItems: _contextMenuItems,
                backgroundColor: colorScheme.surface,
                selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                hoverColor: colorScheme.primary.withValues(alpha: 0.1),
                textColor: colorScheme.onSurface,
                badgeColor: colorScheme.primary,
                showTypeBadges: true,
                showDescriptions: true,
                width: 300,
              ),
              onElementSelected: (id, element) {
                setState(() {
                  _selectedElementId = id;
                  _lastAction = 'Selected: \\${element.name}';
                });
              },
              onContextMenuItemSelected: (itemId, elementId, element) {
                setState(() {
                  _selectedElementId = elementId;
                  _lastAction = 'Menu action: \\${itemId} on \\${element.name}';
                });
              },
            ),
          ),

          // Right panel with details
          flutter.Expanded(
            child: flutter.Padding(
              padding: const flutter.EdgeInsets.all(16.0),
              child: flutter.Column(
                crossAxisAlignment: flutter.CrossAxisAlignment.start,
                children: [
                  flutter.Text(
                    'ElementExplorer with Context Menu',
                    style: theme.textTheme.titleLarge,
                  ),
                  const flutter.SizedBox(height: 16),
                  flutter.Text(
                    'Instructions:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const flutter.SizedBox(height: 8),
                  const flutter.Text(
                    '• Click on elements to select them\n'
                    '• Right-click (or long-press on mobile) to show the context menu\n'
                    '• Different elements have different menu options\n'
                    '• Menu items can be filtered based on element type',
                  ),
                  const flutter.SizedBox(height: 24),
                  flutter.Text(
                    'Selected Element:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const flutter.SizedBox(height: 8),
                  if (_selectedElementId != null)
                    flutter.Card(
                      elevation: 2,
                      child: flutter.Padding(
                        padding: const flutter.EdgeInsets.all(16.0),
                        child: _buildSelectedElementDetails(),
                      ),
                    )
                  else
                    const flutter.Text('No element selected'),
                  const flutter.SizedBox(height: 24),
                  flutter.Text(
                    'Last Action:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const flutter.SizedBox(height: 8),
                  if (_lastAction != null)
                    flutter.Card(
                      elevation: 2,
                      color: colorScheme.primaryContainer,
                      child: flutter.Padding(
                        padding: const flutter.EdgeInsets.all(16.0),
                        child: flutter.Text(
                          _lastAction!,
                          style: flutter.TextStyle(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    )
                  else
                    const flutter.Text('No action performed yet'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the details view for the selected element
  flutter.Widget _buildSelectedElementDetails() {
    if (_selectedElementId == null) {
      return const flutter.Text('No element selected');
    }

    // Find the selected element
    final element = _findElementById(_selectedElementId!);
    if (element == null) {
      return flutter.Text('Element not found: $_selectedElementId');
    }

    // Display element details
    return flutter.Column(
      crossAxisAlignment: flutter.CrossAxisAlignment.start,
      children: [
        flutter.Text(
          element.name,
          style: const flutter.TextStyle(
            fontWeight: flutter.FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const flutter.SizedBox(height: 8),
        flutter.Row(
          children: [
            flutter.Container(
              padding: const flutter.EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: flutter.BoxDecoration(
                color: flutter.Colors.blue.withValues(alpha: 0.2),
                borderRadius: flutter.BorderRadius.circular(4),
              ),
              child: flutter.Text(
                element.type,
                style: const flutter.TextStyle(
                  fontWeight: flutter.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const flutter.SizedBox(width: 8),
            ...element.tags.map(
              (tag) => flutter.Padding(
                padding: const flutter.EdgeInsets.only(right: 4),
                child: flutter.Container(
                  padding: const flutter.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: flutter.BoxDecoration(
                    color: flutter.Colors.grey.withValues(alpha: 0.2),
                    borderRadius: flutter.BorderRadius.circular(4),
                  ),
                  child: flutter.Text(
                    tag,
                    style: const flutter.TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const flutter.SizedBox(height: 8),
        if (element.description != null)
          flutter.Text(
            element.description!,
            style: const flutter.TextStyle(
              fontStyle: flutter.FontStyle.italic,
            ),
          ),
        const flutter.SizedBox(height: 16),
        flutter.Text('ID: \\${element.id}'),
        if (element.parentId != null)
          flutter.Text('Parent ID: \\${element.parentId}'),
        const flutter.SizedBox(height: 8),
        const flutter.Text(
          'Available Context Menu Actions:',
          style: flutter.TextStyle(fontWeight: flutter.FontWeight.bold),
        ),
        const flutter.SizedBox(height: 4),
        ..._contextMenuItems
            .where((item) => item.filter == null || item.filter!(element))
            .map(
              (item) => flutter.Padding(
                padding: const flutter.EdgeInsets.symmetric(vertical: 2),
                child: flutter.Row(
                  children: [
                    if (item.icon != null) ...[
                      flutter.Icon(item.icon, size: 16),
                      const flutter.SizedBox(width: 4),
                    ],
                    flutter.Text(item.label),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  /// Find an element by ID in the workspace
  Element? _findElementById(String id) {
    return _workspace.model.getAllElements().firstWhere(
          (element) => element.id == id,
          orElse: () => throw Exception('Element not found: $id'),
        );
  }
}
