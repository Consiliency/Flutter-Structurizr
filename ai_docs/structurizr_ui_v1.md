# Structurizr UI Documentation Summary

This document summarizes the key features and functionality of the Structurizr browser-based UI (diagram/documentation/ADR renderer), which is shared across Structurizr cloud service, on-premises installation, and Lite.

## 1. Core Components

### 1.1 Diagrams
Structurizr offers multiple diagram types based on the C4 model approach:

- **System Landscape View**: High-level overview of systems and people
- **System Context View**: Focus on a single system and its interactions
- **Container View**: Zooms into a system to show containers (applications, data stores, etc.)
- **Component View**: Shows components inside a container
- **Code View**: Fine-grained view of code (classes, etc.)
- **Dynamic View**: Shows interactions between elements
- **Deployment View**: Shows deployment of containers to infrastructure
- **Filtered View**: Custom views with filtering
- **Custom View**: Custom element diagrams

### 1.2 Documentation
Structurizr supports lightweight supplementary technical documentation using Markdown or AsciiDoc files:

- Rendered with markdown-it or asciidoctor.js
- Can embed diagrams from the workspace
- Supports headings, section numbers, diagrams, and images
- Can be exported

### 1.3 Decisions
Architecture Decision Records (ADRs) capture the decisions that led to the solution:

- Each ADR has an ID, title, date, and status
- Content is written in Markdown or AsciiDoc
- Navigation through ADRs via left/right keys or quick navigation dialog
- Decision explorer with force-directed graph showing connections between decisions
- Customizable status labels with color support

## 2. Diagram Notation

### 2.1 Elements and Relationships
Structurizr uses a simple notation of boxes and unidirectional arrows:

- **Elements**: Person, Software System, Container, Component, Deployment Node, Infrastructure Node
- **Relationships**: Unidirectional arrows between elements
- **Tags**: Used to apply styles to elements and relationships
- **Boundaries and Groups**: Used to group elements on diagrams

### 2.2 Customization Options

#### Elements
- Shape (Box, RoundedBox, Circle, Ellipse, Hexagon, Person, etc.)
- Size (width and height in pixels)
- Colors (background, stroke, text)
- Borders (solid, dashed, dotted)
- Opacity
- Metadata/description visibility
- Icons (PNG, JPG, SVG via URL or base64)

#### Relationships
- Line thickness
- Color
- Style (solid, dashed, dotted)
- Routing (direct, curved, orthogonal)
- Font size
- Width and position of description
- Opacity

## 3. UI Features

### 3.1 Diagram Controls
- Automatic and manual layout options
- Zoom and pan navigation
- Diagram editor for adjusting positions
- Themes for consistent styling
- Branding customization
- Diagram sorting options
- Keyboard shortcuts
- Perspectives for filtering views
- Health check indicators
- Animation for dynamic diagrams
- Presentation mode
- PNG/SVG export

### 3.2 Other Features
- **Quick Navigation**: Easily jump between views
- **Dark Mode**: UI theme toggle
- **Scripting**: Extend the UI with custom JavaScript
- **Properties**: Customize UI behavior via properties
- **Explorations**: Interactive exploration of architecture

## 4. Customization Properties

Structurizr UI can be customized using properties like:

| Property | Purpose |
|----------|---------|
| structurizr.locale | Customizes date format rendering |
| structurizr.timezone | Sets timezone for displaying dates |
| structurizr.sort | Specifies diagram sorting (key, type, created) |
| structurizr.tooltips | Enables/disables diagram tooltips |
| structurizr.title | Includes/excludes diagram title |
| structurizr.description | Includes/excludes diagram description |
| structurizr.metadata | Includes/excludes diagram metadata |
| structurizr.groups | Includes/excludes groups |
| structurizr.softwareSystemBoundaries | Includes/excludes software system boundaries |

## 5. Implementation Notes

- Uses a simple visual language (boxes and arrows)
- Supports C4 model terminology by default but can be customized
- Icons must be served over HTTPS and may require CORS configuration
- Style cascade based on tag order
- The diagram key automatically shows all styles in use

This summary is based on the official Structurizr UI documentation at https://docs.structurizr.com/ui.