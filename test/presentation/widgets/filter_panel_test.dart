import 'package:flutter/material.dart' hide Container, Element;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/person.dart';
import 'package:flutter_structurizr/domain/model/software_system.dart';
import 'package:flutter_structurizr/presentation/widgets/filter_panel.dart';

void main() {
  // Create a test workspace
  final testModel = Model();
  
  // Add some elements with tags
  final person = Person(
    id: 'person1',
    name: 'User',
    tags: const ['Person', 'External'],
  );
  
  final system = SoftwareSystem(
    id: 'system1',
    name: 'System',
    tags: const ['System', 'Internal'],
  );
  
  testModel.addPerson(person);
  testModel.addSoftwareSystem(system);
  
  final testWorkspace = Workspace(
    id: 'test-workspace',
    name: 'Test Workspace',
    model: testModel,
  );

  testWidgets('FilterPanel displays properly', (WidgetTester tester) async {
    List<String>? updatedFilters;
    
    // Build the FilterPanel
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterPanel(
            workspace: testWorkspace,
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
    
    // Verify Element Types section exists
    expect(find.text('Element Types'), findsOneWidget);
    
    // Verify Tags section exists
    expect(find.text('Tags'), findsOneWidget);
    
    // Verify Apply Filters button exists
    expect(find.text('Apply Filters'), findsOneWidget);
  });

  testWidgets('FilterPanel shows element types from workspace', (WidgetTester tester) async {
    // Build the FilterPanel
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterPanel(
            workspace: testWorkspace,
            activeFilters: const [],
            onFiltersChanged: (_) {},
          ),
        ),
      ),
    );

    // Tap to expand Element Types section
    await tester.tap(find.text('Element Types'));
    await tester.pumpAndSettle();
    
    // Verify Person and SoftwareSystem element types are shown
    expect(find.text('Person'), findsOneWidget);
    expect(find.text('SoftwareSystem'), findsOneWidget);
  });

  testWidgets('FilterPanel shows tags from workspace', (WidgetTester tester) async {
    // Build the FilterPanel
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterPanel(
            workspace: testWorkspace,
            activeFilters: const [],
            onFiltersChanged: (_) {},
          ),
        ),
      ),
    );

    // Tap to expand Tags section
    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    
    // Verify tags are shown
    expect(find.text('External'), findsOneWidget);
    expect(find.text('Internal'), findsOneWidget);
    expect(find.text('Person'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
  });

  testWidgets('FilterPanel adds and removes filters correctly', (WidgetTester tester) async {
    List<String>? updatedFilters;
    
    // Build the FilterPanel
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterPanel(
            workspace: testWorkspace,
            activeFilters: const [],
            onFiltersChanged: (filters) {
              updatedFilters = filters;
            },
          ),
        ),
      ),
    );

    // Tap to expand Element Types section
    await tester.tap(find.text('Element Types'));
    await tester.pumpAndSettle();
    
    // Find checkboxes for Person type
    final personCheckbox = find.ancestor(
      of: find.text('Person'),
      matching: find.byType(CheckboxListTile),
    );
    
    // Tap to select Person filter
    await tester.tap(personCheckbox);
    await tester.pumpAndSettle();
    
    // Apply the filters
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    
    // Verify filters were updated with expected content
    expect(updatedFilters, isNotNull);
    expect(updatedFilters!.length, 1);
    expect(updatedFilters!.first, contains('Person'));
  });

  testWidgets('FilterPanel displays active filters', (WidgetTester tester) async {
    // Build the FilterPanel with initial active filters
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterPanel(
            workspace: testWorkspace,
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
            workspace: testWorkspace,
            activeFilters: const ['tag:External', 'type:Person'],
            onFiltersChanged: (filters) {
              updatedFilters = filters;
            },
          ),
        ),
      ),
    );

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

  testWidgets('FilterPanel search filters the available options', (WidgetTester tester) async {
    // Build the FilterPanel
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterPanel(
            workspace: testWorkspace,
            activeFilters: const [],
            onFiltersChanged: (_) {},
          ),
        ),
      ),
    );

    // Find the search field and enter a search term
    final searchField = find.ancestor(
      of: find.text('Search filters'),
      matching: find.byType(TextField),
    );
    
    // Enter search text
    await tester.enterText(searchField, 'External');
    await tester.pumpAndSettle();
    
    // Expand Tags section
    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    
    // Verify only matching tag is shown
    expect(find.text('External'), findsOneWidget);
    expect(find.text('Internal'), findsNothing);
  });
}