import 'package:flutter/material.dart' hide Container, Element, View;
import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/model/person.dart';
import 'package:flutter_structurizr/domain/model/relationship.dart';
import 'package:flutter_structurizr/domain/model/enterprise.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/structurizr_diagram.dart';
import 'package:flutter_structurizr/presentation/widgets/property_panel_fixed.dart' as fixed;
import 'package:flutter_structurizr/presentation/layout/automatic_layout.dart';

void main() {
  runApp(const IntegratedDemoApp());
}

class IntegratedDemoApp extends StatelessWidget {
  const IntegratedDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structurizr Demo',
      theme: ThemeData.dark(useMaterial3: true),
      home: const IntegratedDemoScreen(),
    );
  }
}

class IntegratedDemoScreen extends StatefulWidget {
  const IntegratedDemoScreen({super.key});

  @override
  State<IntegratedDemoScreen> createState() => _IntegratedDemoScreenState();
}

class _IntegratedDemoScreenState extends State<IntegratedDemoScreen> {
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
    final enterprise = Enterprise('Big Bank Inc.');
    
    final model = Model();
    
    // People
    final customer = Person(
      id: 'customer',
      name: 'Personal Banking Customer',
      description: 'A customer of the bank with personal banking accounts',
    );
    
    // Software Systems
    final internetBankingSystem = SoftwareSystem(
      id: 'internetBankingSystem',
      name: 'Internet Banking System',
      description: 'Allows customers to view their accounts and make payments',
    );
    
    final mainframeBankingSystem = SoftwareSystem(
      id: 'mainframeBankingSystem',
      name: 'Mainframe Banking System',
      description: 'Stores core banking information about customers, accounts, transactions, etc.',
    );
    
    final emailSystem = SoftwareSystem(
      id: 'emailSystem',
      name: 'Email System',
      description: 'The internal Microsoft Exchange email system',
    );
    
    // Relationships
    model.addRelationship(
      Relationship(
        id: 'rel1',
        sourceId: customer.id,
        destinationId: internetBankingSystem.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel2',
        sourceId: internetBankingSystem.id,
        destinationId: mainframeBankingSystem.id,
        description: 'Gets account information from',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel3',
        sourceId: internetBankingSystem.id,
        destinationId: emailSystem.id,
        description: 'Sends emails using',
      ),
    );
    
    // Add to model
    model.addPerson(customer);
    model.addSoftwareSystem(internetBankingSystem);
    model.addSoftwareSystem(mainframeBankingSystem);
    model.addSoftwareSystem(emailSystem);
    
    // Containers
    final webApplication = Container(
      id: 'webApplication',
      name: 'Web Application',
      description: 'Provides Internet banking functionality via the web',
      technology: 'Java and Spring MVC',
      parentId: internetBankingSystem.id,
    );
    
    final mobileApp = Container(
      id: 'mobileApp',
      name: 'Mobile App',
      description: 'Provides Internet banking functionality via a mobile app',
      technology: 'Flutter',
      parentId: internetBankingSystem.id,
    );
    
    final apiApplication = Container(
      id: 'apiApplication',
      name: 'API Application',
      description: 'Provides an API for the Internet banking functionality',
      technology: 'Java and Spring Boot',
      parentId: internetBankingSystem.id,
    );
    
    final database = Container(
      id: 'database',
      name: 'Database',
      description: 'Stores user registration information, hashed passwords, etc.',
      technology: 'PostgreSQL',
      parentId: internetBankingSystem.id,
    );
    
    // Add containers to the Internet Banking System
    internetBankingSystem.addContainer(webApplication);
    internetBankingSystem.addContainer(mobileApp);
    internetBankingSystem.addContainer(apiApplication);
    internetBankingSystem.addContainer(database);
    
    // Container relationships
    model.addRelationship(
      Relationship(
        id: 'rel4',
        sourceId: customer.id,
        destinationId: webApplication.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel5',
        sourceId: customer.id,
        destinationId: mobileApp.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel6',
        sourceId: webApplication.id,
        destinationId: apiApplication.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel7',
        sourceId: mobileApp.id,
        destinationId: apiApplication.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel8',
        sourceId: apiApplication.id,
        destinationId: database.id,
        description: 'Reads from and writes to',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel9',
        sourceId: apiApplication.id,
        destinationId: mainframeBankingSystem.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
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
    apiApplication.addComponent(signinController);
    apiApplication.addComponent(accountsSummaryController);
    apiApplication.addComponent(securityComponent);
    apiApplication.addComponent(mainframeFacade);
    apiApplication.addComponent(emailComponent);
    
    // Component relationships
    model.addRelationship(
      Relationship(
        id: 'rel11',
        sourceId: webApplication.id,
        destinationId: signinController.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel12',
        sourceId: webApplication.id,
        destinationId: accountsSummaryController.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel13',
        sourceId: mobileApp.id,
        destinationId: signinController.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel14',
        sourceId: mobileApp.id,
        destinationId: accountsSummaryController.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel15',
        sourceId: signinController.id,
        destinationId: securityComponent.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel16',
        sourceId: accountsSummaryController.id,
        destinationId: mainframeFacade.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel17',
        sourceId: securityComponent.id,
        destinationId: database.id,
        description: 'Reads from and writes to',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel18',
        sourceId: mainframeFacade.id,
        destinationId: mainframeBankingSystem.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel19',
        sourceId: signinController.id,
        destinationId: emailComponent.id,
        description: 'Uses',
      ),
    );
    
    model.addRelationship(
      Relationship(
        id: 'rel20',
        sourceId: emailComponent.id,
        destinationId: emailSystem.id,
        description: 'Uses',
      ),
    );
    
    // Create workspace with the model
    workspace = Workspace(
      id: 'banking-system',
      name: 'Banking System',
      description: 'A simple banking system example',
      model: model,
    );
    
    // Add styles
    final styles = Styles();
    
    // Person style
    styles.addElementStyle('Person').shape = 'Person';
    
    // Software System styles
    styles.addElementStyle('Software System').background = '#1168bd';
    styles.addElementStyle('Software System').color = '#ffffff';
    
    // Container styles
    styles.addElementStyle('Container').background = '#438dd5';
    styles.addElementStyle('Container').color = '#ffffff';
    
    // Component styles
    styles.addElementStyle('Component').background = '#85bbf0';
    styles.addElementStyle('Component').color = '#000000';
    
    // Add specific styles
    styles.addElementStyle('${mainframeBankingSystem.id}').background = '#999999';
    styles.addElementStyle('${emailSystem.id}').background = '#999999';
    
    // Database style
    styles.addElementStyle('database').shape = 'Cylinder';
    
    workspace.views = Views();
    
    // Add views
    systemContextView = ModelSystemContextView(
      key: 'SystemContext',
      softwareSystemId: internetBankingSystem.id,
      description: 'The system context diagram for the Internet Banking System',
      enterpriseBoundaryVisible: true,
    );
    workspace.views.systemContextViews.add(systemContextView);
    
    containerView = ModelContainerView(
      key: 'Containers',
      softwareSystemId: internetBankingSystem.id,
      description: 'The container diagram for the Internet Banking System',
    );
    workspace.views.containerViews.add(containerView);
    
    componentView = ModelComponentView(
      key: 'Components',
      containerId: apiApplication.id,
      description: 'The component diagram for the API Application',
    );
    workspace.views.componentViews.add(componentView);
    
    workspace.views.styles = styles;
    
    // Add auto layout for proper positioning
    AutomaticLayout.applyForceDirectedLayout(systemContextView, workspace);
    AutomaticLayout.applyForceDirectedLayout(containerView, workspace);
    AutomaticLayout.applyForceDirectedLayout(componentView, workspace);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Structurizr - $selectedViewName View'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeView,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'System Context',
                child: Text('System Context View'),
              ),
              const PopupMenuItem<String>(
                value: 'Container',
                child: Text('Container View'),
              ),
              const PopupMenuItem<String>(
                value: 'Component',
                child: Text('Component View'),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Diagram area (takes most of the space)
          Expanded(
            flex: 3,
            child: currentView != null
                ? StructurizrDiagram(
                    workspace: workspace,
                    view: currentView!,
                    onElementSelected: (elementId) {
                      // Handle element selection
                      print('Selected element: $elementId');
                    },
                  )
                : const Center(child: Text('No view selected')),
          ),
          
          // Properties panel (takes about 1/4 of the space)
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey.shade700),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Properties', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Text('Select an element in the diagram to view and edit its properties.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Workspace: ${workspace.name}'),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    onPressed: () {
                      // Zoom in functionality
                    },
                    tooltip: 'Zoom In',
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_out),
                    onPressed: () {
                      // Zoom out functionality
                    },
                    tooltip: 'Zoom Out',
                  ),
                  IconButton(
                    icon: const Icon(Icons.fit_screen),
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