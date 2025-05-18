import 'package:flutter/material.dart' as flutter hide Element, View;
import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/domain/model/container.dart'
    as model_container;
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/model/person.dart';
import 'package:flutter_structurizr/domain/model/relationship.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/domain/style/styles.dart'
    as structurizr_style;
import 'package:flutter_structurizr/presentation/widgets/diagram/structurizr_diagram.dart';
import 'package:flutter_structurizr/domain/model/model.dart' as model;
import 'package:flutter_structurizr/domain/view/views.dart';

void main() {
  flutter.runApp(const IntegratedDemoApp());
}

class IntegratedDemoApp extends flutter.StatelessWidget {
  const IntegratedDemoApp({super.key});

  @override
  flutter.Widget build(flutter.BuildContext context) {
    return flutter.MaterialApp(
      title: 'Structurizr Demo',
      theme: flutter.ThemeData.dark(useMaterial3: true),
      home: const IntegratedDemoScreen(),
    );
  }
}

class IntegratedDemoScreen extends flutter.StatefulWidget {
  const IntegratedDemoScreen({super.key});

  @override
  flutter.State<IntegratedDemoScreen> createState() =>
      _IntegratedDemoScreenState();
}

class _IntegratedDemoScreenState extends flutter.State<IntegratedDemoScreen> {
  late Workspace workspace;
  late ModelSystemContextView systemContextView;
  late ModelContainerView containerView;
  late ModelComponentView componentView;
  String selectedViewName = 'System Context';
  ModelView? currentView;

  @override
  void initState() {
    super.initState();
    _initializeWorkspace();
    currentView = systemContextView;
  }

  void _initializeWorkspace() {
    // Create a simple banking system model
    // final enterprise = Enterprise(id: '1', name: 'Big Bank Inc.'); // Unused

    const modelInstance = model.Model();

    // People
    const customer = Person(
      id: 'customer',
      name: 'Personal Banking Customer',
      description: 'A customer of the bank with personal banking accounts',
    );

    // Software Systems
    const internetBankingSystem = SoftwareSystem(
      id: 'internetBankingSystem',
      name: 'Internet Banking System',
      description: 'Allows customers to view their accounts and make payments',
    );

    const mainframeBankingSystem = SoftwareSystem(
      id: 'mainframeBankingSystem',
      name: 'Mainframe Banking System',
      description:
          'Stores core banking information about customers, accounts, transactions, etc.',
    );

    const emailSystem = SoftwareSystem(
      id: 'emailSystem',
      name: 'Email System',
      description: 'The internal Microsoft Exchange email system',
    );

    // Relationships
    modelInstance.addRelationship(
      Relationship(
        id: 'rel1',
        sourceId: customer.id,
        destinationId: internetBankingSystem.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel2',
        sourceId: internetBankingSystem.id,
        destinationId: mainframeBankingSystem.id,
        description: 'Gets account information from',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel3',
        sourceId: internetBankingSystem.id,
        destinationId: emailSystem.id,
        description: 'Sends emails using',
      ),
    );

    // Add to model
    modelInstance.addPerson(customer);
    modelInstance.addSoftwareSystem(internetBankingSystem);
    modelInstance.addSoftwareSystem(mainframeBankingSystem);
    modelInstance.addSoftwareSystem(emailSystem);

    // Containers
    final webApplication = model_container.Container(
      id: 'webApplication',
      name: 'Web Application',
      description: 'Provides Internet banking functionality via the web',
      technology: 'Java and Spring MVC',
      parentId: internetBankingSystem.id,
    );

    final mobileApp = model_container.Container(
      id: 'mobileApp',
      name: 'Mobile App',
      description: 'Provides Internet banking functionality via a mobile app',
      technology: 'Flutter',
      parentId: internetBankingSystem.id,
    );

    final apiApplication = model_container.Container(
      id: 'apiApplication',
      name: 'API Application',
      description: 'Provides an API for the Internet banking functionality',
      technology: 'Java and Spring Boot',
      parentId: internetBankingSystem.id,
    );

    final database = model_container.Container(
      id: 'database',
      name: 'Database',
      description:
          'Stores user registration information, hashed passwords, etc.',
      technology: 'PostgreSQL',
      parentId: internetBankingSystem.id,
    );

    // Add containers to the Internet Banking System
    internetBankingSystem.addContainer(webApplication);
    internetBankingSystem.addContainer(mobileApp);
    internetBankingSystem.addContainer(apiApplication);
    internetBankingSystem.addContainer(database);

    // Container relationships
    modelInstance.addRelationship(
      Relationship(
        id: 'rel4',
        sourceId: customer.id,
        destinationId: webApplication.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel5',
        sourceId: customer.id,
        destinationId: mobileApp.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel6',
        sourceId: webApplication.id,
        destinationId: apiApplication.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel7',
        sourceId: mobileApp.id,
        destinationId: apiApplication.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel8',
        sourceId: apiApplication.id,
        destinationId: database.id,
        description: 'Reads from and writes to',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel9',
        sourceId: apiApplication.id,
        destinationId: mainframeBankingSystem.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel10',
        sourceId: apiApplication.id,
        destinationId: emailSystem.id,
        description: 'Sends emails using',
      ),
    );

    // Components (inside API Application)
    final signinController = Component(
      id: 'signinController',
      name: 'Sign In Controller',
      description: 'Allows users to sign in to the Internet Banking System',
      technology: 'Java and Spring MVC',
      parentId: apiApplication.id,
    );

    final accountsSummaryController = Component(
      id: 'accountsSummaryController',
      name: 'Accounts Summary Controller',
      description: 'Provides customers with a summary of their accounts',
      technology: 'Java and Spring MVC',
      parentId: apiApplication.id,
    );

    final securityComponent = Component(
      id: 'securityComponent',
      name: 'Security Component',
      description: 'Provides functionality related to signing in, etc.',
      technology: 'Java and Spring Security',
      parentId: apiApplication.id,
    );

    final mainframeFacade = Component(
      id: 'mainframeFacade',
      name: 'Mainframe Banking System Facade',
      description: 'A facade onto the mainframe banking system',
      technology: 'Java',
      parentId: apiApplication.id,
    );

    final emailComponent = Component(
      id: 'emailComponent',
      name: 'Email Component',
      description: 'Sends emails to customers',
      technology: 'Java and Spring',
      parentId: apiApplication.id,
    );

    // Add components to the API Application container
    apiApplication.components.addAll([
      signinController,
      accountsSummaryController,
      securityComponent,
      mainframeFacade,
      emailComponent,
    ]);

    // Component relationships
    modelInstance.addRelationship(
      Relationship(
        id: 'rel11',
        sourceId: webApplication.id,
        destinationId: signinController.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel12',
        sourceId: webApplication.id,
        destinationId: accountsSummaryController.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel13',
        sourceId: mobileApp.id,
        destinationId: signinController.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel14',
        sourceId: mobileApp.id,
        destinationId: accountsSummaryController.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel15',
        sourceId: signinController.id,
        destinationId: securityComponent.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel16',
        sourceId: accountsSummaryController.id,
        destinationId: mainframeFacade.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel17',
        sourceId: securityComponent.id,
        destinationId: database.id,
        description: 'Reads from and writes to',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel18',
        sourceId: mainframeFacade.id,
        destinationId: mainframeBankingSystem.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel19',
        sourceId: signinController.id,
        destinationId: emailComponent.id,
        description: 'Uses',
      ),
    );

    modelInstance.addRelationship(
      Relationship(
        id: 'rel20',
        sourceId: emailComponent.id,
        destinationId: emailSystem.id,
        description: 'Uses',
      ),
    );

    // Create workspace with the model
    workspace = const Workspace(
      id: 1,
      name: 'Banking System',
      description: 'A simple banking system example',
      model: modelInstance,
    );

    // Add styles
    const styles = structurizr_style.Styles();

    // Person style
    styles.addElementStyle(
      const structurizr_style.ElementStyle(
          tag: 'Person', shape: structurizr_style.Shape.person),
    );

    // Software System styles
    styles.addElementStyle(
      const structurizr_style.ElementStyle(
        tag: 'Software System',
        background: '#1168bd',
        color: '#ffffff',
      ),
    );

    // Container styles
    styles.addElementStyle(
      const structurizr_style.ElementStyle(
        tag: 'Container',
        background: '#438dd5',
        color: '#ffffff',
      ),
    );

    // Component styles
    styles.addElementStyle(
      const structurizr_style.ElementStyle(
        tag: 'Component',
        background: '#85bbf0',
        color: '#000000',
      ),
    );

    // Add specific styles
    styles.addElementStyle(
      structurizr_style.ElementStyle(
        tag: mainframeBankingSystem.id,
        background: '#999999',
      ),
    );
    styles.addElementStyle(
      structurizr_style.ElementStyle(
        tag: emailSystem.id,
        background: '#999999',
      ),
    );

    // Database style
    styles.addElementStyle(
      const structurizr_style.ElementStyle(
        tag: 'database',
        shape: structurizr_style.Shape.cylinder,
      ),
    );

    // Views
    const views = Views();

    // Add views
    systemContextView = ModelSystemContextView(
      key: 'SystemContext',
      softwareSystemId: internetBankingSystem.id,
      description: 'The system context diagram for the Internet Banking System',
      // Remove enterpriseBoundaryVisible if not supported
    );
    final updatedSystemContextViews = [
      ...views.systemContextViews,
      ModelSystemContextView(
        key: 'SystemContext',
        softwareSystemId: internetBankingSystem.id,
        description:
            'The system context diagram for the Internet Banking System',
      )
    ];

    containerView = ModelContainerView(
      key: 'Containers',
      softwareSystemId: internetBankingSystem.id,
      description: 'The container diagram for the Internet Banking System',
    );
    final updatedContainerViews = [
      ...views.containerViews,
      ModelContainerView(
        key: 'Containers',
        softwareSystemId: internetBankingSystem.id,
        description: 'The container diagram for the Internet Banking System',
      )
    ];

    componentView = ModelComponentView(
      key: 'Components',
      softwareSystemId: internetBankingSystem.id,
      containerId: apiApplication.id,
      description: 'The component diagram for the API Application',
    );
    final updatedComponentViews = [
      ...views.componentViews,
      ModelComponentView(
        key: 'Components',
        softwareSystemId: internetBankingSystem.id,
        containerId: apiApplication.id,
        description: 'The component diagram for the API Application',
      )
    ];

    final updatedViews = views.copyWith(
      systemContextViews: updatedSystemContextViews,
      containerViews: updatedContainerViews,
      componentViews: updatedComponentViews,
      styles: styles,
    );
    workspace = workspace.copyWith(views: updatedViews);

    // Remove or comment out auto layout if not implemented
    // layout.AutomaticLayout.applyForceDirectedLayout(systemContextView, workspace);
    // layout.AutomaticLayout.applyForceDirectedLayout(containerView, workspace);
    // layout.AutomaticLayout.applyForceDirectedLayout(componentView, workspace);
  }

  void _changeView(String viewName) {
    setState(() {
      selectedViewName = viewName;
      switch (viewName) {
        case 'System Context':
          currentView = systemContextView;
          break;
        case 'Container':
          currentView = containerView;
          break;
        case 'Component':
          currentView = componentView;
          break;
      }
    });
  }

  @override
  flutter.Widget build(flutter.BuildContext context) {
    return flutter.Scaffold(
      appBar: flutter.AppBar(
        title: flutter.Text('Structurizr - $selectedViewName View'),
        actions: [
          flutter.PopupMenuButton<String>(
            onSelected: _changeView,
            itemBuilder: (flutter.BuildContext context) => [
              const flutter.PopupMenuItem<String>(
                value: 'System Context',
                child: flutter.Text('System Context View'),
              ),
              const flutter.PopupMenuItem<String>(
                value: 'Container',
                child: flutter.Text('Container View'),
              ),
              const flutter.PopupMenuItem<String>(
                value: 'Component',
                child: flutter.Text('Component View'),
              ),
            ],
          ),
        ],
      ),
      body: flutter.Row(
        children: [
          // Diagram area (takes most of the space)
          flutter.Expanded(
            flex: 3,
            child: currentView != null
                ? StructurizrDiagram(
                    workspace: workspace,
                    view: currentView!,
                    onElementSelected: (id, element) {
                      // TODO('Replace with logging: Selected element: $id');
                    },
                  )
                : const flutter.Center(child: flutter.Text('No view selected')),
          ),

          // Properties panel (takes about 1/4 of the space)
          flutter.Expanded(
            flex: 1,
            child: flutter.Container(
              decoration: flutter.BoxDecoration(
                border: flutter.Border(
                  left: flutter.BorderSide(color: flutter.Colors.grey.shade700),
                ),
              ),
              child: const flutter.Padding(
                padding: flutter.EdgeInsets.all(8.0),
                child: flutter.Column(
                  crossAxisAlignment: flutter.CrossAxisAlignment.start,
                  children: [
                    flutter.Text('Properties',
                        style: flutter.TextStyle(
                            fontSize: 16, fontWeight: flutter.FontWeight.bold)),
                    flutter.SizedBox(height: 16),
                    flutter.Text(
                        'Select an element in the diagram to view and edit its properties.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: flutter.BottomAppBar(
        child: flutter.Padding(
          padding: const flutter.EdgeInsets.symmetric(horizontal: 16.0),
          child: flutter.Row(
            mainAxisAlignment: flutter.MainAxisAlignment.spaceBetween,
            children: [
              flutter.Text('Workspace: ${workspace.name}'),
              flutter.Row(
                children: [
                  flutter.IconButton(
                    icon: const flutter.Icon(flutter.Icons.zoom_in),
                    onPressed: () {
                      // Zoom in functionality
                    },
                    tooltip: 'Zoom In',
                  ),
                  flutter.IconButton(
                    icon: const flutter.Icon(flutter.Icons.zoom_out),
                    onPressed: () {
                      // Zoom out functionality
                    },
                    tooltip: 'Zoom Out',
                  ),
                  flutter.IconButton(
                    icon: const flutter.Icon(flutter.Icons.fit_screen),
                    onPressed: () {
                      // Fit to screen functionality
                    },
                    tooltip: 'Fit to Screen',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
