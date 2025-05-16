# Structurizr JSON Format Documentation

This document provides a comprehensive overview of the Structurizr JSON format, which is the underlying data storage format used by all Structurizr tooling. This information is essential for implementing a Dart port of Structurizr.

## 1. Overview and Key Concepts

Structurizr JSON is a schema-based format for describing software architecture models based on the C4 model. While the format exists as the persistence layer for Structurizr, it's important to note that it is **not designed to be authored manually**. The recommended approach is to use either:

1. The Structurizr DSL (Domain Specific Language)
2. One of the programming language APIs (Java, .NET, etc.)
3. A combination of both approaches

The JSON format serves as a complete representation of a Structurizr workspace, including:
- The architecture model (elements and relationships)
- Views of the model (various diagram types)
- Documentation
- Decision records
- Styling information
- Layout coordinates
- Configuration options

## 2. Core Structure

The root object in Structurizr JSON is a `Workspace`, which contains the following high-level components:

```json
{
  "id": 12345,
  "name": "Example Workspace",
  "description": "An example workspace",
  "version": "1.0",
  "model": {
    // Model elements and relationships
  },
  "views": {
    // Different views of the model
  },
  "documentation": {
    // Documentation sections
  },
  "configuration": {
    // Workspace configuration
  }
}
```

### 2.1 Model Section

The model contains the core architectural elements:

```json
"model": {
  "enterprise": {
    "name": "Example Enterprise"
  },
  "people": [
    // Person elements
  ],
  "softwareSystems": [
    // Software System elements with containers and components
  ],
  "deploymentNodes": [
    // Deployment environment definitions
  ]
}
```

### 2.2 Views Section

The views section defines different visualizations of the model:

```json
"views": {
  "systemLandscapeViews": [ /* ... */ ],
  "systemContextViews": [ /* ... */ ],
  "containerViews": [ /* ... */ ],
  "componentViews": [ /* ... */ ],
  "dynamicViews": [ /* ... */ ],
  "deploymentViews": [ /* ... */ ],
  "filteredViews": [ /* ... */ ],
  "styles": {
    "elements": [ /* ... */ ],
    "relationships": [ /* ... */ ]
  },
  "configuration": {
    // View-specific configuration
  }
}
```

## 3. Element Types and Hierarchies

### 3.1 Common Element Properties

All elements share a common set of properties:

```json
{
  "id": "unique-id",
  "name": "Element Name",
  "description": "Description of the element",
  "tags": "Tag1,Tag2",
  "relationships": [
    // Outgoing relationships from this element
  ],
  "properties": {
    // Custom properties as key-value pairs
  },
  "perspectives": [
    // Architectural perspectives (security, performance, etc.)
  ]
}
```

### 3.2 Element Hierarchy

The model follows a hierarchical structure:

1. **Person**: Represents users or roles
   ```json
   {
     "id": "1",
     "name": "User",
     "description": "A user of the system",
     "location": "External",
     // Common element properties
   }
   ```

2. **Software System**: Top-level system
   ```json
   {
     "id": "2",
     "name": "Banking System",
     "description": "Handles banking operations",
     "location": "Internal",
     "containers": [
       // Containers within this system
     ],
     // Common element properties
   }
   ```

3. **Container**: Applications, data stores, etc.
   ```json
   {
     "id": "3",
     "name": "Web Application",
     "description": "Provides UI for customers",
     "technology": "Java, Spring Boot",
     "components": [
       // Components within this container
     ],
     // Common element properties
   }
   ```

4. **Component**: Classes, modules, etc.
   ```json
   {
     "id": "4",
     "name": "AccountController",
     "description": "Handles account-related requests",
     "technology": "Java",
     // Common element properties
   }
   ```

5. **Deployment Node**: Infrastructure elements
   ```json
   {
     "id": "5",
     "name": "Amazon Web Services",
     "description": "AWS Cloud",
     "technology": "Amazon Web Services",
     "environment": "Live",
     "instances": 1,
     "children": [
       // Child deployment nodes
     ],
     "containerInstances": [
       // Container instances deployed on this node
     ],
     "infrastructureNodes": [
       // Infrastructure nodes within this node
     ],
     // Common element properties
   }
   ```

## 4. Relationships

Relationships connect elements in the model:

```json
{
  "id": "rel1",
  "sourceId": "1",
  "destinationId": "2",
  "description": "Uses",
  "technology": "HTTPS",
  "interactionStyle": "Synchronous",
  "tags": "Tag1,Tag2",
  "properties": {
    // Custom properties
  },
  "perspectives": [
    // Perspectives
  ]
}
```

Key aspects of relationships:
- Each relationship has a unique ID
- Source and destination elements are referenced by ID
- Relationships can have technology information
- Interaction style can be Synchronous or Asynchronous
- Custom properties and perspectives can be attached

## 5. Views

Views define different ways to visualize the architectural model:

### 5.1 View Types

1. **System Landscape View**: Enterprise-wide view
   ```json
   {
     "key": "SystemLandscape",
     "description": "The system landscape diagram",
     "title": "System Landscape",
     "elements": [
       // Element references with positions
     ],
     "relationships": [
       // Relationship references with routing information
     ],
     "animations": [
       // Animation step definitions
     ],
     "automaticLayout": {
       // Layout configuration if used
     }
   }
   ```

2. **System Context View**: Single system focus
3. **Container View**: Components of a system
4. **Component View**: Elements within a container
5. **Dynamic View**: Sequence of interactions
6. **Deployment View**: Infrastructure mapping
7. **Filtered View**: Subset based on tags

### 5.2 Element Positioning in Views

Elements in views include positioning information:

```json
{
  "id": "1",
  "x": 100,
  "y": 200,
  "width": 450,
  "height": 300
}
```

### 5.3 View-Specific Properties

Different view types have specific properties:
- System Context and Container views reference a software system ID
- Component views reference a container ID
- Dynamic views can have a scope and sequence information
- Deployment views reference an environment
- Filtered views reference a base view

## 6. Styling

Styling is defined in the views section:

```json
"styles": {
  "elements": [
    {
      "tag": "Person",
      "shape": "Person",
      "background": "#08427B",
      "color": "#ffffff",
      "fontSize": 22,
      "border": "Solid",
      "opacity": 100,
      "metadata": true,
      "icon": "data:image/png;base64,..."
    }
  ],
  "relationships": [
    {
      "tag": "Relationship",
      "thickness": 2,
      "color": "#707070",
      "style": "Solid",
      "routing": "Direct",
      "fontSize": 22,
      "width": 200,
      "position": 50,
      "opacity": 100
    }
  ]
}
```

### 6.1 Element Style Properties

- **shape**: Box, RoundedBox, Circle, Ellipse, Hexagon, Cylinder, Pipe, Person, Robot, Folder, WebBrowser, MobileDevicePortrait, MobileDeviceLandscape, Component
- **icon**: Data URI for an icon image
- **width/height**: Size in pixels
- **background**: Background color (hex)
- **color/colour**: Text color (hex)
- **stroke**: Border color (hex)
- **strokeWidth**: Border thickness (1-10px)
- **fontSize**: Text size in pixels
- **border**: Solid, Dashed, Dotted
- **opacity**: 0-100
- **metadata**: true/false to show metadata
- **description**: true/false to show description

### 6.2 Relationship Style Properties

- **thickness**: Line thickness in pixels
- **color/colour**: Line color (hex)
- **style**: Solid, Dashed, Dotted
- **routing**: Direct, Curved, Orthogonal
- **fontSize**: Text size in pixels
- **width**: Width of description
- **position**: Position of description (0-100%)
- **opacity**: 0-100

## 7. Documentation and Decisions

Documentation is structured as a collection of sections:

```json
"documentation": {
  "sections": [
    {
      "format": "Markdown",
      "content": "# Documentation\n\nThis is the documentation for the system.",
      "order": 1
    }
  ],
  "decisions": [
    {
      "id": "1",
      "date": "2021-07-20",
      "title": "Use Spring Boot",
      "status": "Accepted",
      "content": "# Decision\n\nWe will use Spring Boot.",
      "format": "Markdown"
    }
  ]
}
```

## 8. Configuration

The configuration section includes workspace-level settings:

```json
"configuration": {
  "users": [
    // User definitions for access control
  ],
  "properties": {
    // Custom workspace properties
  }
}
```

## 9. Validation Rules

Structurizr JSON must adhere to several validation rules:

1. Element and relationship IDs must be unique
2. View key and order properties must be unique across all views
3. Software and people names must be unique
4. Container names must be unique within the context of a software system
5. Component names must be unique within the context of a container
6. Deployment node names must be unique within their parent context
7. Infrastructure node names must be unique within their parent context
8. All relationships from a source element to a destination element must have a unique description

## 10. Implementation Recommendations for Dart

When implementing Structurizr in Dart, consider the following:

### 10.1 Class Structure

Create class hierarchies that mirror the JSON structure:

```dart
class Workspace {
  int? id;
  String name;
  String? description;
  String? version;
  Model model;
  ViewSet views;
  Documentation? documentation;
  WorkspaceConfiguration? configuration;
  
  // JSON serialization methods
}

class Model {
  Enterprise? enterprise;
  List<Person> people = [];
  List<SoftwareSystem> softwareSystems = [];
  List<DeploymentNode> deploymentNodes = [];
  
  // Methods for finding elements by ID, etc.
}

abstract class Element {
  String id;
  String name;
  String? description;
  List<String> tags = [];
  Map<String, String> properties = {};
  List<Relationship> relationships = [];
  Map<String, Perspective> perspectives = {};
  
  // Common element methods
}

// Specific element classes extending Element
class Person extends Element { ... }
class SoftwareSystem extends Element { ... }
class Container extends Element { ... }
// etc.
```

### 10.2 View Implementation

```dart
class ViewSet {
  List<SystemLandscapeView> systemLandscapeViews = [];
  List<SystemContextView> systemContextViews = [];
  List<ContainerView> containerViews = [];
  List<ComponentView> componentViews = [];
  List<DynamicView> dynamicViews = [];
  List<DeploymentView> deploymentViews = [];
  List<FilteredView> filteredViews = [];
  Styles styles;
  ViewConfiguration configuration;
  
  // Methods for finding views, etc.
}

abstract class View {
  String key;
  String? description;
  String? title;
  
  // Common view methods
}

// Specific view classes extending View
class SystemLandscapeView extends View { ... }
class SystemContextView extends View { ... }
// etc.
```

### 10.3 Serialization Strategies

1. Use packages like `json_serializable` to streamline JSON conversion
2. Implement custom `fromJson` and `toJson` methods for complex classes
3. Create factories for polymorphic element/view types:

```dart
class ElementFactory {
  static Element fromJson(Map<String, dynamic> json) {
    final type = _determineElementType(json);
    switch (type) {
      case ElementType.person:
        return Person.fromJson(json);
      case ElementType.softwareSystem:
        return SoftwareSystem.fromJson(json);
      // etc.
    }
  }
}
```

### 10.4 Validation Implementation

Implement validators for the model to ensure it adheres to the rules:

```dart
class WorkspaceValidator {
  List<ValidationError> validate(Workspace workspace) {
    final errors = <ValidationError>[];
    
    errors.addAll(_validateUniqueIds(workspace));
    errors.addAll(_validateUniqueNames(workspace));
    // etc.
    
    return errors;
  }
  
  List<ValidationError> _validateUniqueIds(Workspace workspace) {
    // Implementation
  }
  
  // Other validation methods
}
```

## 11. Resources and References

- [Structurizr JSON GitHub Repository](https://github.com/structurizr/json)
- [OpenAPI Specification](https://github.com/structurizr/json/blob/master/structurizr.yaml)
- [Structurizr Java Client](https://github.com/structurizr/java)
- [Structurizr DSL](https://docs.structurizr.com/dsl)

This document provides a comprehensive overview of the Structurizr JSON format that can serve as a guide for implementing a Dart version of Structurizr.