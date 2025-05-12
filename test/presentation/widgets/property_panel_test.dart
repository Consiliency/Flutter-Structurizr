import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart' as structurizr;
import 'package:flutter_structurizr/domain/model/person.dart';
import 'package:flutter_structurizr/domain/model/relationship.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/widgets/property_panel.dart';

void main() {
  group('PropertyPanel Widget Tests', () {
    testWidgets('PropertyPanel shows empty state when nothing is selected', (WidgetTester tester) async {
      // Build the widget with no selection
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropertyPanel(),
          ),
        ),
      );

      // Verify empty state message is shown
      expect(find.text('Select an element or relationship to edit its properties'), findsOneWidget);
      
      // Verify icon is shown
      expect(find.byIcon(Icons.touch_app), findsOneWidget);
    });
    
    testWidgets('PropertyPanel shows element properties', (WidgetTester tester) async {
      // Create test element
      final element = Person(
        id: 'person-1',
        name: 'Test Person',
        description: 'A test person',
        tags: ['User', 'External'],
        properties: {'email': 'test@example.com'},
      );
      
      // Build the widget with element selected
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyPanel(
              selectedElement: element,
            ),
          ),
        ),
      );

      // Verify tabs are shown
      expect(find.text('Properties'), findsOneWidget);
      expect(find.text('Styles'), findsOneWidget);
      expect(find.text('Tags'), findsOneWidget);
      
      // Verify basic element properties are shown
      expect(find.text('Element Type: Person'), findsOneWidget);
      expect(find.text('Basic Properties'), findsOneWidget);
      
      // Verify text fields contain correct values
      expect(find.widgetWithText(TextField, 'ID'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Description'), findsOneWidget);
      
      // Switch to Tags tab
      await tester.tap(find.text('Tags'));
      await tester.pumpAndSettle();
      
      // Verify tags are shown
      expect(find.text('Element Tags'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('External'), findsOneWidget);
    });
    
    testWidgets('PropertyPanel shows relationship properties', (WidgetTester tester) async {
      // Create test relationship
      final relationship = Relationship(
        id: 'relationship-1',
        sourceId: 'source-1',
        destinationId: 'destination-1',
        description: 'Test Relationship',
        technology: 'HTTP',
        tags: ['API'],
        properties: {'priority': 'high'},
      );
      
      // Build the widget with relationship selected
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyPanel(
              selectedRelationship: relationship,
            ),
          ),
        ),
      );

      // Verify tabs are shown
      expect(find.text('Properties'), findsOneWidget);
      expect(find.text('Styles'), findsOneWidget);
      expect(find.text('Tags'), findsOneWidget);
      
      // Verify basic relationship properties are shown
      expect(find.text('Relationship'), findsOneWidget);
      expect(find.text('Basic Properties'), findsOneWidget);
      
      // Verify text fields contain correct values
      expect(find.widgetWithText(TextField, 'ID'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Source'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Destination'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Description'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Technology'), findsOneWidget);
      
      // Switch to Tags tab
      await tester.tap(find.text('Tags'));
      await tester.pumpAndSettle();
      
      // Verify tags are shown
      expect(find.text('Relationship Tags'), findsOneWidget);
      expect(find.text('API'), findsOneWidget);
    });
    
    testWidgets('PropertyPanel allows editing element properties', (WidgetTester tester) async {
      // Track property changes
      String? changedProperty;
      dynamic changedValue;
      
      // Create test element
      final element = Person(
        id: 'person-1',
        name: 'Test Person',
        description: 'A test person',
      );
      
      // Build the widget with element selected and callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyPanel(
              selectedElement: element,
              onElementPropertyChanged: (element, property, value) {
                changedProperty = property;
                changedValue = value;
              },
            ),
          ),
        ),
      );

      // Find the name text field
      final nameField = find.widgetWithText(TextField, 'Name');
      expect(nameField, findsOneWidget);
      
      // Edit the name
      await tester.enterText(nameField, 'Updated Person');
      
      // Verify callback was called with correct values
      expect(changedProperty, equals('name'));
      expect(changedValue, equals('Updated Person'));
    });
    
    testWidgets('PropertyPanel allows adding and removing tags', (WidgetTester tester) async {
      // Track property changes
      String? changedProperty;
      dynamic changedValue;
      
      // Create test element
      final element = Person(
        id: 'person-1',
        name: 'Test Person',
        tags: ['User'],
      );
      
      // Build the widget with element selected and callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyPanel(
              selectedElement: element,
              onElementPropertyChanged: (element, property, value) {
                changedProperty = property;
                changedValue = value;
              },
            ),
          ),
        ),
      );

      // Navigate to Tags tab
      await tester.tap(find.text('Tags'));
      await tester.pumpAndSettle();
      
      // Verify initial tag is shown
      expect(find.text('User'), findsOneWidget);
      
      // Find the delete icon and tap it
      final deleteIcon = find.descendant(
        of: find.byType(Chip),
        matching: find.byIcon(Icons.close),
      );
      expect(deleteIcon, findsOneWidget);
      
      await tester.tap(deleteIcon);
      await tester.pump();
      
      // Verify callback was called with correct values
      expect(changedProperty, equals('tags'));
      expect(changedValue, isA<List<String>>());
      expect((changedValue as List<String>).isEmpty, isTrue);
    });
  });
}