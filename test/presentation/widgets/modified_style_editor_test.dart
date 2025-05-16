import 'package:flutter/material.dart' hide Container, Element;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/presentation/widgets/property_panel.dart';

// Create mock classes for testing because the actual Element class is abstract
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
  final String type = 'MockElement';
  
  MockElement({
    required this.id,
    required this.name,
    this.description,
    this.tags = const [],
    this.properties = const {},
    this.relationships = const [],
    this.parentId,
  });
  
  @override
  Element addProperty(String key, String value) {
    // Not implemented for test
    return this;
  }
  
  @override
  Element addRelationship({
    required String destinationId,
    required String description,
    String? technology,
    List<String> tags = const [],
    Map<String, String> properties = const {},
  }) {
    // Not implemented for test
    return this;
  }
  
  @override
  Element addTag(String tag) {
    // Not implemented for test
    return this;
  }
  
  @override
  Element addTags(List<String> newTags) {
    // Not implemented for test
    return this;
  }
  
  @override
  Relationship? getRelationshipById(String relationshipId) {
    // Not implemented for test
    return null;
  }
}

class MockRelationship implements Relationship {
  @override
  final String id;
  
  @override
  final String sourceId;
  
  @override
  final String destinationId;
  
  @override
  final String? description;
  
  @override
  final String? technology;
  
  @override
  final List<String> tags;
  
  @override
  final Map<String, String> properties;
  
  MockRelationship({
    required this.id,
    required this.sourceId,
    required this.destinationId,
    this.description,
    this.technology,
    this.tags = const [],
    this.properties = const {},
  });
}

void main() {
  // Create test elements
  final testElement = MockElement(
    id: 'test-element',
    name: 'Test Element',
    tags: const ['TestTag'],
  );

  // Create test styles
  final testElementStyle = ElementStyle(
    tag: 'TestTag',
    background: const Color(0xFFFF0000),
    color: const Color(0xFFFFFFFF),
    shape: Shape.box,
    border: Border.solid,
    strokeWidth: 1,
    fontSize: 12,
    opacity: 100,
  );

  final testStyles = Styles(
    elements: [testElementStyle],
    relationships: [],
  );

  testWidgets('PropertyPanel displays element styles correctly', (WidgetTester tester) async {
    // Track style changes
    ElementStyle? updatedStyle;
    
    // Build the PropertyPanel
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyPanel(
            selectedElement: testElement,
            styles: testStyles,
            onElementPropertyChanged: (element, property, value) {
              if (property == 'style') {
                updatedStyle = value as ElementStyle;
              }
            },
          ),
        ),
      ),
    );

    // Verify initial styles tab exists
    expect(find.text('Styles'), findsOneWidget);
    
    // Tap on Styles tab
    await tester.tap(find.text('Styles'));
    await tester.pumpAndSettle();
    
    // Verify element style section is visible
    expect(find.text('Element Style'), findsOneWidget);
  });

  testWidgets('PropertyPanel displays relationship styles correctly', (WidgetTester tester) async {
    // Create test relationship
    final testRelationship = MockRelationship(
      id: 'test-relationship',
      sourceId: 'source',
      destinationId: 'destination',
      description: 'Test relationship',
      tags: const ['TestRelTag'],
    );

    // Create test relationship style
    final testRelationshipStyle = RelationshipStyle(
      tag: 'TestRelTag',
      color: const Color(0xFF0000FF),
      thickness: 2,
      style: LineStyle.solid,
      routing: StyleRouting.direct,
      position: 50,
      opacity: 100,
    );

    final testStyles = Styles(
      elements: [],
      relationships: [testRelationshipStyle],
    );

    // Track style changes
    RelationshipStyle? updatedStyle;
    
    // Build the PropertyPanel
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyPanel(
            selectedRelationship: testRelationship,
            styles: testStyles,
            onRelationshipPropertyChanged: (relationship, property, value) {
              if (property == 'style') {
                updatedStyle = value as RelationshipStyle;
              }
            },
          ),
        ),
      ),
    );

    // Verify initial styles tab exists
    expect(find.text('Styles'), findsOneWidget);
    
    // Tap on Styles tab
    await tester.tap(find.text('Styles'));
    await tester.pumpAndSettle();
    
    // Verify relationship style section is visible
    expect(find.text('Relationship Style'), findsOneWidget);
  });

  testWidgets('PropertyPanel shows empty state when no styles available', (WidgetTester tester) async {
    // Build the PropertyPanel with no styles
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyPanel(
            selectedElement: testElement,
            styles: null, // No styles provided
          ),
        ),
      ),
    );

    // Tap on Styles tab
    await tester.tap(find.text('Styles'));
    await tester.pumpAndSettle();
    
    // Verify empty state is shown
    expect(find.text('No styles available'), findsOneWidget);
  });

  testWidgets('PropertyPanel allows creating new styles for elements without styles', (WidgetTester tester) async {
    // Element without matching style
    final noStyleElement = MockElement(
      id: 'no-style',
      name: 'No Style Element',
      tags: const ['NoMatchingTag'],
    );
    
    bool createStyleCalled = false;
    
    // Build the PropertyPanel
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyPanel(
            selectedElement: noStyleElement,
            styles: testStyles, // Only has style for 'TestTag'
            onElementPropertyChanged: (element, property, value) {
              if (property == 'style') {
                createStyleCalled = true;
              }
            },
          ),
        ),
      ),
    );

    // Tap on Styles tab
    await tester.tap(find.text('Styles'));
    await tester.pumpAndSettle();
    
    // Verify "No styles defined" message is shown
    expect(find.text('No styles defined for this element'), findsOneWidget);
    
    // Verify Create Style button is shown
    expect(find.text('Create Style'), findsOneWidget);
    
    // Tap Create Style button
    await tester.tap(find.text('Create Style'));
    await tester.pumpAndSettle();
    
    // Verify the callback was called
    expect(createStyleCalled, true);
  });
}