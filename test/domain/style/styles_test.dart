import 'package:flutter/material.dart' hide Border;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';

void main() {
  group('Styles', () {
    test('creates styles with default values', () {
      const styles = Styles();
      
      expect(styles.elements, isEmpty);
      expect(styles.relationships, isEmpty);
      expect(styles.themes, isEmpty);
    });
    
    test('creates styles with all properties', () {
      final elementStyle = ElementStyle(
        tag: 'Person',
        shape: Shape.person,
        background: Colors.blue,
      );
      
      final relationshipStyle = RelationshipStyle(
        tag: 'Relationship',
        thickness: 2,
        color: Colors.black,
      );
      
      final styles = Styles(
        elements: [elementStyle],
        relationships: [relationshipStyle],
        themes: ['default'],
      );
      
      expect(styles.elements, hasLength(1));
      expect(styles.elements[0], equals(elementStyle));
      expect(styles.relationships, hasLength(1));
      expect(styles.relationships[0], equals(relationshipStyle));
      expect(styles.themes, hasLength(1));
      expect(styles.themes[0], equals('default'));
    });
    
    test('gets element style by tag', () {
      final personStyle = ElementStyle(
        tag: 'Person',
        shape: Shape.person,
        background: Colors.blue,
      );
      
      final systemStyle = ElementStyle(
        tag: 'SoftwareSystem',
        shape: Shape.box,
        background: Colors.green,
      );
      
      final styles = Styles(
        elements: [personStyle, systemStyle],
      );
      
      final style = styles.getElementStyle(['Person']);
      
      expect(style.shape, equals(Shape.person));
      expect(style.background, equals(Colors.blue));
    });
    
    test('merges element styles by tag priority', () {
      final baseStyle = ElementStyle(
        tag: 'Element',
        background: Colors.grey,
        color: Colors.black,
      );
      
      final specificStyle = ElementStyle(
        tag: 'Person',
        shape: Shape.person,
        background: Colors.blue,
      );
      
      final styles = Styles(
        elements: [baseStyle, specificStyle],
      );
      
      final style = styles.getElementStyle(['Element', 'Person']);
      
      // Person style should override the background
      expect(style.shape, equals(Shape.person));
      expect(style.background, equals(Colors.blue));
      // But keep the color from the base style
      expect(style.color, equals(Colors.black));
    });
    
    test('gets relationship style by tag', () {
      final defaultStyle = RelationshipStyle(
        tag: 'Relationship',
        thickness: 2,
        color: Colors.black,
      );
      
      final asyncStyle = RelationshipStyle(
        tag: 'Asynchronous',
        style: LineStyle.dashed,
        color: Colors.blue,
      );
      
      final styles = Styles(
        relationships: [defaultStyle, asyncStyle],
      );
      
      final style = styles.getRelationshipStyle(['Asynchronous']);
      
      expect(style.style, equals(LineStyle.dashed));
      expect(style.color, equals(Colors.blue));
    });
    
    test('adds element style', () {
      const styles = Styles();
      
      final elementStyle = ElementStyle(
        tag: 'Person',
        shape: Shape.person,
        background: Colors.blue,
      );
      
      final updatedStyles = styles.addElementStyle(elementStyle);
      
      expect(updatedStyles.elements, hasLength(1));
      expect(updatedStyles.elements[0], equals(elementStyle));
    });
    
    test('adds relationship style', () {
      const styles = Styles();
      
      final relationshipStyle = RelationshipStyle(
        tag: 'Relationship',
        thickness: 2,
        color: Colors.black,
      );
      
      final updatedStyles = styles.addRelationshipStyle(relationshipStyle);
      
      expect(updatedStyles.relationships, hasLength(1));
      expect(updatedStyles.relationships[0], equals(relationshipStyle));
    });
    
    test('adds theme', () {
      const styles = Styles();
      
      final updatedStyles = styles.addTheme('default');
      
      expect(updatedStyles.themes, hasLength(1));
      expect(updatedStyles.themes[0], equals('default'));
    });
  });
  
  group('ElementStyle', () {
    test('creates element style with default values', () {
      const style = ElementStyle();
      
      expect(style.tag, isNull);
      expect(style.shape, equals(Shape.box));
      expect(style.icon, isNull);
      expect(style.width, isNull);
      expect(style.height, isNull);
      expect(style.background, isNull);
      expect(style.color, isNull);
      expect(style.stroke, isNull);
      expect(style.strokeWidth, isNull);
      expect(style.border, equals(Border.solid));
      expect(style.opacity, equals(100));
      expect(style.fontSize, isNull);
      expect(style.metadata, isNull);
      expect(style.description, isNull);
    });
    
    test('creates element style with all properties', () {
      final style = ElementStyle(
        tag: 'Person',
        shape: Shape.person,
        icon: 'icon.png',
        width: 120,
        height: 100,
        background: Colors.blue,
        color: Colors.white,
        stroke: Colors.black,
        strokeWidth: 2,
        border: Border.dashed,
        opacity: 80,
        fontSize: 16,
        metadata: true,
        description: true,
      );
      
      expect(style.tag, equals('Person'));
      expect(style.shape, equals(Shape.person));
      expect(style.icon, equals('icon.png'));
      expect(style.width, equals(120));
      expect(style.height, equals(100));
      expect(style.background, equals(Colors.blue));
      expect(style.color, equals(Colors.white));
      expect(style.stroke, equals(Colors.black));
      expect(style.strokeWidth, equals(2));
      expect(style.border, equals(Border.dashed));
      expect(style.opacity, equals(80));
      expect(style.fontSize, equals(16));
      expect(style.metadata, isTrue);
      expect(style.description, isTrue);
    });
    
    test('merges styles', () {
      final baseStyle = ElementStyle(
        tag: 'Base',
        shape: Shape.box,
        background: Colors.grey,
        color: Colors.black,
        fontSize: 16,
      );
      
      final overrideStyle = ElementStyle(
        tag: 'Override',
        background: Colors.blue,
        strokeWidth: 2,
        opacity: 80,
      );
      
      final mergedStyle = baseStyle.merge(overrideStyle);
      
      // Properties from override style
      expect(mergedStyle.tag, equals('Override'));
      expect(mergedStyle.background, equals(Colors.blue));
      expect(mergedStyle.strokeWidth, equals(2));
      expect(mergedStyle.opacity, equals(80));
      
      // Properties from base style
      expect(mergedStyle.shape, equals(Shape.box));
      expect(mergedStyle.color, equals(Colors.black));
      expect(mergedStyle.fontSize, equals(16));
    });
  });
  
  group('RelationshipStyle', () {
    test('creates relationship style with default values', () {
      const style = RelationshipStyle();
      
      expect(style.tag, isNull);
      expect(style.thickness, equals(1));
      expect(style.color, isNull);
      expect(style.style, equals(LineStyle.solid));
      expect(style.routing, equals(Routing.direct));
      expect(style.fontSize, isNull);
      expect(style.width, isNull);
      expect(style.position, equals(50));
      expect(style.opacity, equals(100));
    });
    
    test('creates relationship style with all properties', () {
      final style = RelationshipStyle(
        tag: 'Relationship',
        thickness: 2,
        color: Colors.black,
        style: LineStyle.dashed,
        routing: Routing.curved,
        fontSize: 16,
        width: 200,
        position: 40,
        opacity: 80,
      );
      
      expect(style.tag, equals('Relationship'));
      expect(style.thickness, equals(2));
      expect(style.color, equals(Colors.black));
      expect(style.style, equals(LineStyle.dashed));
      expect(style.routing, equals(Routing.curved));
      expect(style.fontSize, equals(16));
      expect(style.width, equals(200));
      expect(style.position, equals(40));
      expect(style.opacity, equals(80));
    });
    
    test('merges styles', () {
      final baseStyle = RelationshipStyle(
        tag: 'Base',
        thickness: 1,
        color: Colors.grey,
        fontSize: 16,
      );
      
      final overrideStyle = RelationshipStyle(
        tag: 'Override',
        thickness: 2,
        style: LineStyle.dashed,
        routing: Routing.curved,
      );
      
      final mergedStyle = baseStyle.merge(overrideStyle);
      
      // Properties from override style
      expect(mergedStyle.tag, equals('Override'));
      expect(mergedStyle.thickness, equals(2));
      expect(mergedStyle.style, equals(LineStyle.dashed));
      expect(mergedStyle.routing, equals(Routing.curved));
      
      // Properties from base style
      expect(mergedStyle.color, equals(Colors.grey));
      expect(mergedStyle.fontSize, equals(16));
    });
  });
}