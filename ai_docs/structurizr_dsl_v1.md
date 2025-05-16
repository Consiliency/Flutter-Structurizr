# Structurizr DSL Documentation Summary

This document summarizes the Structurizr Domain Specific Language (DSL), which provides a text-based way to define software architecture models based on the C4 model.

## 1. Core Concepts

Structurizr DSL is a model-based approach to defining software architecture diagrams that:

1. Enables the generation of multiple diagrams from a single source file
2. Runs on the JVM, allowing Java/Groovy/Kotlin/JRuby code execution during model generation
3. Supports pluggable rendering formats (Structurizr UI, PlantUML, Mermaid, etc.)

Key differences from other "diagrams as code" formats:

| Feature | Structurizr DSL | PlantUML/Mermaid/Graphviz |
|---------|----------------|-------------------------|
| Multiple diagrams from single file | Yes | No |
| Execute JVM code | Yes | No |
| Multiple rendering tools | Yes | No |

## 2. Basic Language Structure

The DSL follows a nested block structure with the following hierarchy:

```
workspace "Name" "Description" {
    model {
        // Elements and relationships defined here
    }
    
    views {
        // Diagram definitions
    }
}
```

### 2.1 Model Elements

The model defines the architectural elements and their relationships:

- **person**: End users of the system
- **softwareSystem**: Top-level software systems
- **container**: Applications, services, databases, etc. within a software system
- **component**: Implementation units within a container
- **deploymentEnvironment**: Deployment environments (dev, test, prod)
- **deploymentNode**: Physical/virtual infrastructure where containers run
- **infrastructureNode**: Network infrastructure components
- **containerInstance**: Deployed instances of containers
- **softwareSystemInstance**: Deployed instances of software systems
- **element**: Custom elements outside the C4 model

Example:
```
model {
    user = person "User" "A user of the system"
    
    softwareSystem = softwareSystem "Banking System" {
        webapp = container "Web Application" "Provides banking functionality" "Java, Spring Boot"
        database = container "Database" "Stores user data" "PostgreSQL" {
            tags "Database"
        }
    }
    
    user -> webapp "Uses"
    webapp -> database "Reads from and writes to"
}
```

### 2.2 Relationships

Relationships are defined using the `->` operator:

```
// Explicit from source to destination
source -> destination "Description" "Technology" {
    tags "Tag1", "Tag2"
}

// Within the context of an element
element {
    -> destination "Description"  // Implicit source from current context
}
```

## 3. View Types

Structurizr supports multiple view types based on the C4 model:

1. **systemLandscape**: High-level overview showing multiple systems
   ```
   systemLandscape "key" "description" {
       include *
       autoLayout
   }
   ```

2. **systemContext**: Focus on a single system and its interactions
   ```
   systemContext softwareSystem "key" "description" {
       include *
       autoLayout
   }
   ```

3. **container**: Shows containers within a software system
   ```
   container softwareSystem "key" "description" {
       include *
       autoLayout
   }
   ```

4. **component**: Shows components within a container
   ```
   component container "key" "description" {
       include *
       autoLayout
   }
   ```

5. **dynamic**: Shows runtime interactions between elements
   ```
   dynamic softwareSystem "key" "description" {
       user -> webapp "Logs in"
       webapp -> database "Retrieves user details"
   }
   ```

6. **deployment**: Shows deployment of containers to infrastructure
   ```
   deployment softwareSystem "Production" "key" "description" {
       include *
       autoLayout
   }
   ```

7. **filtered**: Shows a filtered version of another view
   ```
   filtered baseViewKey include "Tag1,Tag2" "key" "description"
   ```

8. **custom**: Custom diagrams with custom elements
   ```
   custom "key" "title" "description" {
       include *
       autoLayout
   }
   ```

9. **image**: Includes external images (PlantUML, Mermaid, etc.)
   ```
   image * "key" {
       plantuml "file.puml"
   }
   ```

## 4. Including and Excluding Elements

Views can include or exclude elements using direct references or expressions:

```
// Include specific elements
include element1 element2

// Include elements by expression
include "element.tag==Database"

// Include elements with relationships
include "->webapp->"  // Elements connected to webapp

// Exclude elements
exclude element3
```

## 5. Styling

### 5.1 Element Styles

Elements can be styled using tags:

```
styles {
    element "Person" {
        shape Person
        background #08427B
        color #ffffff
    }
    
    element "Database" {
        shape Cylinder
        background #1168BD
    }
}
```

Available element properties:
- `shape`: Box, RoundedBox, Circle, Ellipse, Hexagon, Person, Cylinder, etc.
- `icon`: URL or data URI for icons
- `width`, `height`: Size in pixels
- `background`: Background color
- `color`/`colour`: Text color
- `stroke`: Border color
- `strokeWidth`: Border thickness (1-10px)
- `border`: solid, dashed, dotted
- `opacity`: 0-100
- `fontSize`: Text size in pixels
- `metadata`: true/false to show metadata
- `description`: true/false to show description

### 5.2 Relationship Styles

Relationships can be styled:

```
styles {
    relationship "Relationship" {
        thickness 2
        color #707070
        style dashed
        routing Orthogonal
    }
}
```

Available relationship properties:
- `thickness`: Line thickness in pixels
- `color`/`colour`: Line color
- `style`: solid, dashed, dotted
- `routing`: Direct, Curved, Orthogonal
- `fontSize`: Text size
- `width`: Width of description
- `position`: Text position (0-100%)
- `opacity`: 0-100

## 6. Advanced Features

### 6.1 Implied Relationships

Structurizr automatically infers relationships between parent elements when child elements have relationships:

```
// This relationship
user -> webApplication "Uses"

// Implies this relationship if webApplication is a container of softwareSystem
user -> softwareSystem "Uses"
```

This feature can be configured with:
```
!impliedRelationships <true|false>
```

### 6.2 Groups

Elements can be grouped:

```
group "Group Name" {
    element1 = person "Person 1"
    element2 = person "Person 2"
}
```

or on a component:

```
component "Component Name" {
    group "Group Name"
}
```

### 6.3 Tags

Tags allow styling and filtering:

```
element {
    tags "Tag1", "Tag2"
}

// Or
tags "Tag1", "Tag2"
```

### 6.4 Properties and Perspectives

Custom metadata can be added:

```
// Properties
properties {
    "Property1" "Value1"
    "Property2" "Value2"
}

// Perspectives
perspectives {
    "Security" "Description" "High"
    "Performance" "Description" "Medium"
}
```

### 6.5 Animation

Views can define animation steps:

```
animation {
    user
    user softwareSystem
    user softwareSystem database
}
```

### 6.6 Themes

Styling can be defined via themes:

```
theme default
// or
themes url1 url2 file
```

### 6.7 Branding

Workspace branding can be customized:

```
branding {
    logo "logo.png"
    font "Open Sans" "https://fonts.googleapis.com/css?family=Open+Sans"
}
```

### 6.8 Terminology

C4 terminology can be customized:

```
terminology {
    person "Actor"
    softwareSystem "System"
    container "Module"
    component "Service"
}
```

## 7. Tooling Support

### 7.1 Authoring Tools

| Tool | Summary | Recommended |
|------|---------|------------|
| Structurizr Lite | Free local server for viewing/editing workspaces | Yes |
| Structurizr CLI | Command-line utility for pushing/pulling workspaces | Yes |
| Browser-based editor | Basic online editor (limited features) | No |

### 7.2 Feature Comparison

| Feature | Structurizr Lite | Structurizr CLI | Browser Editor |
|---------|-----------------|----------------|---------------|
| Local files with source control | Yes | Yes | No |
| Documentation | Yes | Yes | No |
| Architecture Decision Records | Yes | Yes | No |
| Image views | Yes | Yes | Limited |
| DSL includes | Yes | Yes | Limited |
| Plugins | Yes | Yes | No |
| Scripts | Yes | Yes | No |
| Export formats | No | Yes | Limited |

## 8. Implementation Examples

### 8.1 Basic System Context Example

```
workspace {
    model {
        user = person "User"
        softwareSystem = softwareSystem "Software System"
        
        user -> softwareSystem "Uses"
    }
    
    views {
        systemContext softwareSystem "SystemContext" {
            include *
            autoLayout
        }
        
        styles {
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
        }
    }
}
```

### 8.2 Container View Example

```
workspace {
    model {
        user = person "User"
        softwareSystem = softwareSystem "Software System" {
            webapp = container "Web Application" "Provides functionality" "Java, Spring"
            database = container "Database" "Stores data" "PostgreSQL" {
                tags "Database"
            }
        }
        
        user -> webapp "Uses"
        webapp -> database "Reads from and writes to"
    }
    
    views {
        container softwareSystem "Containers" {
            include *
            autoLayout
        }
        
        styles {
            element "Database" {
                shape Cylinder
            }
        }
    }
}
```

### 8.3 Dynamic View Example

```
workspace {
    model {
        user = person "User"
        system = softwareSystem "System" {
            webapp = container "Web App"
            api = container "API"
            db = container "Database" {
                tags "Database"
            }
        }
    }
    
    views {
        dynamic system "Login" "User login sequence" {
            user -> webapp "Enters credentials"
            webapp -> api "Validates credentials"
            api -> db "Queries user"
            db -> api "Returns user data"
            api -> webapp "Authentication result"
            webapp -> user "Shows dashboard"
        }
        
        styles {
            element "Database" {
                shape Cylinder
            }
        }
    }
}
```

## 9. Integration Points

The Structurizr DSL can be extended via:

1. **!include**: Include DSL fragments from other files
   ```
   !include "path/to/fragment.dsl"
   ```

2. **!docs**: Attach documentation to elements
   ```
   !docs "path/to/docs"
   ```

3. **!adrs**: Attach Architecture Decision Records
   ```
   !adrs "path/to/adrs"
   ```

4. **!script**: Execute scripts in Groovy, Kotlin, Ruby, or JavaScript
   ```
   !script groovy {
       // Groovy code to generate model elements
   }
   ```

5. **!plugin**: Execute Java plugins
   ```
   !plugin com.example.MyPlugin
   ```

6. **extends**: Extend another workspace
   ```
   workspace extends "base.dsl" {
       // Add more elements
   }
   ```

## 10. Best Practices

1. Use hierarchical identifiers for clarity with `!identifiers hierarchical`
2. Leverage implied relationships to reduce model definition redundancy
3. Use explicit view keys for stable manual layouts
4. Group related elements with the `group` keyword
5. Apply consistent styling via themes
6. Store DSL files in source control
7. Use Structurizr Lite/CLI rather than browser-based editor
8. Break large models into modules using `!include`

This summary provides an overview of the Structurizr DSL capabilities with practical examples for implementing a Dart/Flutter version of the Structurizr architecture visualization tool.