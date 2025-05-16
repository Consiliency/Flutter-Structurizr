# TableOfContents Widget

This document describes the implementation of the `TableOfContents` widget, which provides a navigable, collapsible hierarchy of documentation sections and architecture decision records.

## Overview

The `TableOfContents` widget is a key component of the documentation system in Flutter Structurizr. It provides:

1. A hierarchical display of documentation sections with parent-child relationships
2. Collapsible sections with expand/collapse controls
3. Visual hierarchy through indentation and styling
4. Support for both documentation sections and architecture decision records
5. Selection highlighting and callbacks for navigation
6. Dark mode support with appropriate theming

## Implementation

The `TableOfContents` is implemented as a `StatefulWidget` to maintain the expanded/collapsed state of each section:

```dart
class TableOfContents extends StatefulWidget {
  final List<DocumentationSection> sections;
  final List<Decision> decisions;
  final int currentSectionIndex;
  final int currentDecisionIndex;
  final bool viewingDecisions;
  final Function(int) onSectionSelected;
  final Function(int) onDecisionSelected;
  final VoidCallback onToggleView;
  final bool isDarkMode;

  // Constructor
  const TableOfContents({
    Key? key,
    required this.sections,
    required this.decisions,
    required this.currentSectionIndex,
    required this.currentDecisionIndex,
    required this.viewingDecisions,
    required this.onSectionSelected,
    required this.onDecisionSelected,
    required this.onToggleView,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<TableOfContents> createState() => _TableOfContentsState();
}
```

### Key Components

1. **State Management**:
   - The `_expandedSections` map tracks which sections are expanded
   - The `_toggleSection` method toggles the expanded state of a section
   - In `initState`, all root sections are initially expanded

2. **Section Hierarchy Detection**:
   - The `_computeSectionHierarchy` method analyzes section titles to detect parent-child relationships
   - It builds a map of parent indices to lists of child indices
   - This is used to render the hierarchical tree structure

3. **Rendering**:
   - The `_buildSectionsList` method creates the section list with proper hierarchy
   - The `_buildSectionWithChildren` method recursively builds each section with its children
   - The `_buildDecisionsList` method builds the list of architecture decisions

4. **Visual Hierarchy**:
   - Indentation is applied based on the depth level of each section
   - Expand/collapse indicators show the state of each parent section
   - Child sections are only rendered if their parent is expanded

## Usage

The `TableOfContents` widget can be used as follows:

```dart
TableOfContents(
  sections: documentationSections,
  decisions: decisions,
  currentSectionIndex: selectedSectionIndex,
  currentDecisionIndex: selectedDecisionIndex,
  viewingDecisions: isViewingDecisions,
  onSectionSelected: (index) {
    // Handle section selection
    setState(() {
      selectedSectionIndex = index;
      isViewingDecisions = false;
    });
  },
  onDecisionSelected: (index) {
    // Handle decision selection
    setState(() {
      selectedDecisionIndex = index;
      isViewingDecisions = true;
    });
  },
  onToggleView: () {
    // Toggle between documentation and decisions view
    setState(() {
      isViewingDecisions = !isViewingDecisions;
    });
  },
  isDarkMode: isDarkTheme,
)
```

## Parent-Child Relationship Detection

The widget detects parent-child relationships based on section title structure. For example:

- "1. Introduction" (parent)
  - "1.1. Getting Started" (child of Introduction)
  - "1.2. Installation" (child of Introduction)
- "2. Architecture" (parent)
  - "2.1. Components" (child of Architecture)

The algorithm looks at the section title format and builds a hierarchy based on numeric prefixes.

## Accessibility

The implementation includes accessibility features:

1. **Keyboard Navigation**:
   - Expand/collapse controls are focusable and operable via keyboard
   - Proper visual feedback is provided for focused controls

2. **Hierarchical Structure**:
   - Visual indentation clearly indicates parent-child relationships
   - Expand/collapse controls use standard iconography (arrow down/right)

3. **State Persistence**:
   - The widget maintains expanded/collapsed state when navigating through the documentation

## Testing

Comprehensive tests for the `TableOfContents` widget include:

1. **Rendering Tests**:
   - Verifying that all sections and decisions are rendered correctly
   - Testing the collapsible hierarchy functionality

2. **Interaction Tests**:
   - Verifying that selection callbacks are called correctly
   - Testing expand/collapse functionality

3. **Edge Case Tests**:
   - Handling empty sections or decisions lists
   - Dark mode theming support

## Future Improvements

Potential enhancements for the `TableOfContents` widget:

1. **Keyboard Shortcuts**:
   - Add keyboard shortcuts for fast navigation (e.g., J/K for next/previous)
   - Add shortcuts for expanding/collapsing all sections

2. **Search Integration**:
   - Highlight sections matching the current search query
   - Auto-expand sections containing search results

3. **Drag and Drop**:
   - Allow reordering sections via drag and drop
   - Support for custom ordering of sections

4. **State Persistence**:
   - Save expanded/collapsed state between sessions
   - Synchronize state with URL parameters for deep linking

5. **Enhanced Filtering**:
   - Add filtering options based on section content or tags
   - Support for hiding/showing specific sections or section types