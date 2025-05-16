import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/person.dart';
import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/presentation/widgets/element_explorer.dart';

/// Example demonstrating the ElementExplorer widget with context menu functionality
void main() {
  runApp(const ElementExplorerExampleApp());
}

/// Main application widget
class ElementExplorerExampleApp extends StatelessWidget {
  /// Creates a new example app
  const ElementExplorerExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElementExplorer Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const ElementExplorerExamplePage(),
    );
  }
}

/// Main page for the example
class ElementExplorerExamplePage extends StatefulWidget {
  /// Creates a new example page
  const ElementExplorerExamplePage({Key? key}) : super(key: key);

  @override
  State<ElementExplorerExamplePage> createState() => _ElementExplorerExamplePageState();
}

class _ElementExplorerExamplePageState extends State<ElementExplorerExamplePage> {
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
    final webApp = Container.create(
      parentId: ecommerceSystem.id,
      name: 'Web Application',
      description: 'Provides the main web interface',
      technology: 'Flutter Web, Dart',
      tags: ['Container', 'WebApp'],
    );
    
    final mobileApp = Container.create(
      parentId: ecommerceSystem.id,
      name: 'Mobile Application',
      description: 'Native mobile application for iOS and Android',
      technology: 'Flutter, Dart',
      tags: ['Container', 'MobileApp'],
    );
    
    final apiGateway = Container.create(
      parentId: ecommerceSystem.id,
      name: 'API Gateway',
      description: 'Handles authentication and API routing',
      technology: 'Node.js, Express',
      tags: ['Container', 'Gateway'],
    );
    
    final database = Container.create(
      parentId: ecommerceSystem.id,
      name: 'Database',
      description: 'Stores product and order information',
      technology: 'PostgreSQL',
      tags: ['Container', 'Database'],
    );
    
    // Create components for the API Gateway
    final authComponent = Component.create(
      parentId: apiGateway.id,
      name: 'Authentication Component',
      description: 'Handles user authentication and authorization',
      technology: 'JWT, OAuth2',
      tags: ['Component', 'Security'],
    );
    
    final routingComponent = Component.create(
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
      description: 'Example workspace for demonstrating ElementExplorer with context menus',
      model: model,
    );
  }
  
  /// Create context menu items for the ElementExplorer
  List<ElementContextMenuItem> _createContextMenuItems() {
    return [
      const ElementContextMenuItem(
        id: 'view',
        label: 'View Details',
        icon: Icons.info_outline,
      ),
      const ElementContextMenuItem(
        id: 'edit',
        label: 'Edit Element',
        icon: Icons.edit,
      ),
      const ElementContextMenuItem(
        id: 'add_relationship',
        label: 'Add Relationship',
        icon: Icons.add_link,
      ),
      const ElementContextMenuItem(
        id: 'delete',
        label: 'Delete Element',
        icon: Icons.delete,
        // Only enabled for components and containers
        filter: (element) => element.type == 'Component' || element.type == 'Container',
      ),
      const ElementContextMenuItem(
        id: 'add_container',
        label: 'Add Container',
        icon: Icons.add_box,
        // Only for software systems
        filter: (element) => element.type == 'SoftwareSystem',
      ),
      const ElementContextMenuItem(
        id: 'add_component',
        label: 'Add Component',
        icon: Icons.add_circle,
        // Only for containers
        filter: (element) => element.type == 'Container',
      ),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ElementExplorer Example'),
      ),
      body: Row(
        children: [
          // Left panel with ElementExplorer
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
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
                selectedColor: colorScheme.primary.withOpacity(0.2),
                hoverColor: colorScheme.primary.withOpacity(0.1),
                textColor: colorScheme.onSurface,
                badgeColor: colorScheme.primary,
                showTypeBadges: true,
                showDescriptions: true,
                width: 300,
              ),
              onElementSelected: (id, element) {
                setState(() {
                  _selectedElementId = id;
                  _lastAction = 'Selected: ${element.name}';
                });
              },
              onContextMenuItemSelected: (itemId, elementId, element) {
                setState(() {
                  _selectedElementId = elementId;
                  _lastAction = 'Menu action: $itemId on ${element.name}';
                });
              },
            ),
          ),
          
          // Right panel with details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ElementExplorer with Context Menu',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Instructions:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Click on elements to select them\n'
                    '• Right-click (or long-press on mobile) to show the context menu\n'
                    '• Different elements have different menu options\n'
                    '• Menu items can be filtered based on element type',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Selected Element:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_selectedElementId != null)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildSelectedElementDetails(),
                      ),
                    )
                  else
                    const Text('No element selected'),
                  const SizedBox(height: 24),
                  Text(
                    'Last Action:',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_lastAction != null)
                    Card(
                      elevation: 2,
                      color: colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _lastAction!,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    )
                  else
                    const Text('No action performed yet'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the details view for the selected element
  Widget _buildSelectedElementDetails() {
    if (_selectedElementId == null) {
      return const Text('No element selected');
    }
    
    // Find the selected element
    final element = _findElementById(_selectedElementId!);
    if (element == null) {
      return Text('Element not found: $_selectedElementId');
    }
    
    // Display element details
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          element.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                element.type,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ...element.tags.map((tag) => 
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (element.description != null)
          Text(
            element.description!,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 16),
        Text('ID: ${element.id}'),
        if (element.parentId != null)
          Text('Parent ID: ${element.parentId}'),
        const SizedBox(height: 8),
        const Text(
          'Available Context Menu Actions:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ..._contextMenuItems
            .where((item) => item.filter == null || item.filter!(element))
            .map((item) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: 16),
                      const SizedBox(width: 4),
                    ],
                    Text(item.label),
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