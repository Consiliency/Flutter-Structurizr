import 'package:flutter/material.dart' hide Container, Element;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/presentation/widgets/filter_panel.dart';
import 'package:flutter_structurizr/domain/view/views.dart';

class MockElement implements Element {
  @override
  final String id;
  
  @override
  final String name;
  
  @override
  final String? description;
  
  @override
  final List<String> tags;
  
  @override
  final Map<String, String> properties;
  
  @override
  final List<Relationship> relationships;
  
  @override
  final String? parentId;
  
  @override
  final String type;
  
  MockElement({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.tags = const [],
    this.properties = const {},
    this.relationships = const [],
    this.parentId,
  });
  
  @override
  Element addProperty(String key, String value) => this;
  
  @override
  Element addRelationship({
    required String destinationId,
    required String description,
    String? technology,
    List<String> tags = const [],
    Map<String, String> properties = const {},
  }) => this;
  
  @override
  Element addTag(String tag) => this;
  
  @override
  Element addTags(List<String> newTags) => this;
  
  @override
  Relationship? getRelationshipById(String relationshipId) => null;
  
  @override
  List<Relationship> getRelationshipsTo(String destinationId) => [];
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockModel implements Model {
  final List<Element> _elements = [];
  
  void addElement(Element element) => _elements.add(element);
  
  @override
  List<Element> getAllElements() => _elements;
  
  @override
  List<Relationship> getAllRelationships() => [];
  
  @override
  Element getElementById(String id) => _elements.firstWhere((e) => e.id == id);
  
  @override
  List<Relationship> get relationships => [];
  
  @override
  List<Element> get elements => _elements;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  
  @override
  get deploymentEnvironments => [];
  
  @override
  get deploymentNodes => [];
  
  @override
  get enterpriseName => null;
  
  @override
  get people => [];
  
  @override
  get softwareSystems => [];
}

class MockWorkspace implements Workspace {
  final MockModel _model;
  
  MockWorkspace(this._model);
  
  @override
  Model get model => _model;
  
  @override
  int get id => 1;
  
  @override
  Views get views => Views();
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  
  @override
  get configuration => null;
  
  @override
  get description => null;
  
  @override
  get documentation => null;
  
  @override
  get lastModifiedDate => null;
  
  @override
  get name => 'Mock Workspace';
  
  @override
  get revision => null;
  
  @override
  get thumbnail => null;
  
  @override
  get version => null;
}

void main() {
  // Create a test workspace
  final mockModel = MockModel();
  
  // Add some elements with tags
  final person = MockElement(
    id: 'person1',
    name: 'User',
    type: 'Person',
    tags: const ['Person', 'External'],
  );
  
  final system = MockElement(
    id: 'system1',
    name: 'System',
    type: 'SoftwareSystem',
    tags: const ['System', 'Internal'],
  );
  
  mockModel.addElement(person);
  mockModel.addElement(system);
  
  final mockWorkspace = MockWorkspace(mockModel);

  testWidgets('FilterPanel displays properly', (WidgetTester tester) async {
    List<String>? updatedFilters;
    
    // Build the FilterPanel
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterPanel(
            workspace: mockWorkspace,
            activeFilters: const [],
            onFiltersChanged: (filters) {
              updatedFilters = filters;
            },
          ),
        ),
      ),
    );

    // Verify the filter panel title is displayed
    expect(find.text('Filter Diagram'), findsOneWidget);
    
    // Verify search field is present
    expect(find.byType(TextField), findsAtLeastNWidgets(1));
    
    // Verify bottom buttons exists
    expect(find.text('Apply Filters'), findsOneWidget);
  });

  testWidgets('FilterPanel displays active filters', (WidgetTester tester) async {
    // Build the FilterPanel with initial active filters
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterPanel(
            workspace: mockWorkspace,
            activeFilters: const ['tag:External', 'type:Person'],
            onFiltersChanged: (_) {},
          ),
        ),
      ),
    );

    // Verify Active Filters section is visible
    expect(find.text('Active Filters'), findsOneWidget);
    
    // Verify active filter chips are displayed
    expect(find.text('tag:External'), findsOneWidget);
    expect(find.text('type:Person'), findsOneWidget);
    
    // Verify Clear All Filters button is visible
    expect(find.text('Clear All Filters'), findsOneWidget);
  });

  testWidgets('FilterPanel clears all filters', (WidgetTester tester) async {
    List<String>? updatedFilters;
    
    // Build the FilterPanel with initial active filters
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterPanel(
            workspace: mockWorkspace,
            activeFilters: const ['tag:External', 'type:Person'],
            onFiltersChanged: (filters) {
              updatedFilters = filters;
            },
          ),
        ),
      ),
    );
    
    // Verify both filters are displayed
    expect(find.text('tag:External'), findsOneWidget);
    expect(find.text('type:Person'), findsOneWidget);

    // Tap the Clear All Filters button
    await tester.tap(find.text('Clear All Filters'));
    await tester.pumpAndSettle();
    
    // Apply the filters (clear action won't automatically apply)
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    
    // Verify filters were cleared
    expect(updatedFilters, isNotNull);
    expect(updatedFilters, isEmpty);
  });

  testWidgets('FilterPanel applies changes on Apply button', (WidgetTester tester) async {
    List<String>? updatedFilters;
    
    // Build the FilterPanel
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterPanel(
            workspace: mockWorkspace,
            activeFilters: const [],
            onFiltersChanged: (filters) {
              updatedFilters = filters;
            },
          ),
        ),
      ),
    );

    // Verify Reset and Apply buttons exist
    expect(find.text('Reset to Default'), findsOneWidget);
    expect(find.text('Apply Filters'), findsOneWidget);
    
    // Apply the filters (should be empty at this point)
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    
    // Verify callback was called with empty list
    expect(updatedFilters, isNotNull);
    expect(updatedFilters, isEmpty);
  });
}