# Phase 1 Implementation Plan: Core Model

**Status: 100% Complete**

## Overview

The core model implementation is the foundation of the Flutter Structurizr application. This phase focuses on creating the domain models that represent the Structurizr concepts such as workspaces, models, elements, relationships, views, and styles.

## Components

### 1. Workspace Model ✅

The primary container for all architecture models and views.

- **Files:**
  - `/lib/domain/model/workspace.dart` ✅
  - `/test/domain/model/workspace_test.dart` ✅

### 2. Model and Elements ✅

The building blocks of architecture diagrams including software systems, containers, components, and people.

- **Files:**
  - `/lib/domain/model/model.dart` ✅
  - `/lib/domain/model/element.dart` ✅
  - `/lib/domain/model/person.dart` ✅
  - `/lib/domain/model/container.dart` ✅
  - `/lib/domain/model/component.dart` ✅
  - `/lib/domain/model/software_system.dart` ✅
  - `/lib/domain/model/enterprise.dart` ✅
  - `/lib/domain/model/infrastructure_node.dart` ✅
  - `/lib/domain/model/model_item.dart` ✅
  - `/lib/domain/model/deployment_environment.dart` ✅
  - `/lib/domain/model/deployment_node.dart` ✅
  - `/lib/domain/model/group.dart` ✅
  - `/lib/domain/model/location.dart` ✅
  - `/test/domain/model/model_test.dart` ✅
  - `/test/domain/model/element_test.dart` ✅
  - `/test/domain/model/component_test.dart` ✅
  - `/test/domain/model/container_test.dart` ✅
  - `/test/domain/model/deployment_test.dart` ✅

### 3. Relationships ✅

The connections between elements in the architecture model.

- **Files:**
  - `/lib/domain/model/relationship.dart` ✅
  - `/test/domain/model/relationship_test.dart` ✅

### 4. Views ✅

Different perspectives on the architecture model for visualization.

- **Files:**
  - `/lib/domain/view/view.dart` ✅
  - `/lib/domain/view/views.dart` ✅
  - `/lib/domain/view/model_view.dart` ✅
  - `/lib/domain/view/view_alias.dart` ✅
  - `/test/domain/view/view_test.dart` ✅
  - `/test/domain/view/views_test.dart` ✅
  - `/test/domain/view/animation_test.dart` ✅

### 5. Styles ✅

Visual styling for elements and relationships in views.

- **Files:**
  - `/lib/domain/style/styles.dart` ✅
  - `/lib/domain/style/themes.dart` ✅
  - `/lib/domain/style/boundary_style.dart` ✅
  - `/lib/domain/style/branding.dart` ✅
  - `/test/domain/style/styles_test.dart` ✅
  - `/test/domain/style/themes_test.dart` ✅
  - `/test/domain/style/branding_test.dart` ✅

### 6. Type Aliases ✅

Helper files to manage naming conflicts between Flutter and Structurizr models.

- **Files:**
  - `/lib/domain/model/container_alias.dart` ✅
  - `/lib/domain/model/element_alias.dart` ✅
  - `/lib/util/import_helper.dart` ✅

### 7. Documentation ✅

API documentation for core model classes.

- **Files:**
  - `/lib/domain/documentation/documentation.dart` ✅
  - `/test/domain/documentation/documentation_test.dart` ✅

## Implementation Approach

1. ✅ Start with implementing the base ModelItem class
2. ✅ Create the Element base class
3. ✅ Implement specific element types (Person, SoftwareSystem, Container, Component)
4. ✅ Implement the Model class that manages collections of elements
5. ✅ Implement Relationship and relationship management
6. ✅ Develop the Workspace container
7. ✅ Implement Views (SystemContext, Container, Component, Deployment)
8. ✅ Create the styling system
9. ✅ Implement serialization for all model components
10. ✅ Create comprehensive tests for all components

## Technical Considerations

- ✅ All domain models should be immutable
- ✅ Use extension methods for modifications to maintain immutability
- ✅ Implement proper validation for all model components
- ✅ Use UUIDs for all model elements
- ✅ Ensure proper serialization/deserialization
- ✅ Manage naming conflicts with Flutter built-ins (Container, Element, etc.)

## Dependencies

- package:uuid for generating unique identifiers
- package:meta for annotations
- package:equatable for value equality
- package:json_annotation for serialization
- package:collection for enhanced collections

## Test Plan

- ✅ Unit tests for all model classes
- ✅ Serialization/deserialization tests
- ✅ Integration tests with sample architecture models
- ✅ Specific tests for edge cases and validation

### Comprehensive Testing Guide for Phase 1

#### Setup for Domain Model Testing

1. **Required Dependencies**:
   ```yaml
   dev_dependencies:
     flutter_test:
       sdk: flutter
     build_runner: ^2.4.0
     json_serializable: ^6.7.0
     test: ^1.24.0
   ```

2. **Installation**:
   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

#### Running Domain Model Tests

1. **Run All Model Tests**:
   ```bash
   flutter test test/domain/model/
   ```

2. **Run Specific Model Component Tests**:
   ```bash
   # Workspace tests
   flutter test test/domain/model/workspace_test.dart
   
   # Relationship tests
   flutter test test/domain/model/relationship_test.dart
   
   # Element tests (Person, Container, etc.)
   flutter test test/domain/model/element_test.dart
   flutter test test/domain/model/component_test.dart
   flutter test test/domain/model/container_test.dart
   ```

3. **Run View Tests**:
   ```bash
   flutter test test/domain/view/
   ```

4. **Run Style Tests**:
   ```bash
   flutter test test/domain/style/
   ```

5. **Run All Phase 1 Tests**:
   ```bash
   flutter test test/domain/
   ```

#### Test Implementation Guidelines

1. **Model Tests Structure**:
   ```dart
   void main() {
     group('Workspace', () {
       test('creation with required fields', () {
         // Test code
       });
       
       test('JSON serialization', () {
         // Test serialization
       });
       
       test('validation', () {
         // Test validation logic
       });
     });
   }
   ```

2. **Mocking Dependencies**:
   ```dart
   // Example of mocking model elements for testing
   final mockModel = Model();
   final mockPerson = Person(id: 'person1', name: 'User');
   mockModel.addPerson(mockPerson);
   ```

3. **Testing Immutability**:
   ```dart
   test('immutability', () {
     final workspace = Workspace(name: 'Test');
     final updatedWorkspace = workspace.addPerson(Person(id: 'person1', name: 'User'));
     
     // Original should be unchanged
     expect(workspace != updatedWorkspace, true);
     expect(workspace.model.people.isEmpty, true);
   });
   ```

#### Troubleshooting Common Issues

1. **Json Serialization Errors**:
   - Check that all serializable classes have proper annotations
   - Regenerate code with `flutter pub run build_runner build --delete-conflicting-outputs`
   - Ensure all required fields are marked as required in the model

2. **Naming Conflicts**:
   - Use proper import hiding for Flutter conflicts: `import 'package:flutter/material.dart' hide Container, Element;`
   - Use type aliases defined in `container_alias.dart` and `element_alias.dart`

3. **Test Data Generation**:
   - Use helper functions in tests to create consistent test data
   - Create factory methods for common test configurations

## Completion Criteria

- ✅ All files implemented
- ✅ All tests passing
- ✅ Serialization working correctly
- ✅ Immutability and extension methods functioning as expected
- ✅ Type aliases correctly handling naming conflicts