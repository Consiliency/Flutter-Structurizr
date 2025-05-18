import 'package:flutter/material.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/markdown_renderer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Documentation Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const EnhancedMarkdownExample(),
    );
  }
}

class EnhancedMarkdownExample extends StatefulWidget {
  const EnhancedMarkdownExample({Key? key}) : super(key: key);

  @override
  State<EnhancedMarkdownExample> createState() =>
      _EnhancedMarkdownExampleState();
}

class _EnhancedMarkdownExampleState extends State<EnhancedMarkdownExample> {
  bool _isDarkMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    const markdownContent = '''
# Enhanced Markdown Features

This page demonstrates the enhanced Markdown features available in Flutter Structurizr.

## Task Lists

You can create interactive task lists:

- [ ] Incomplete task
- [x] Complete task
- [ ] Another task with a longer description that wraps to the next line
- [x] Task with **bold** and *italic* text

## Enhanced Images

Standard markdown images work, but we also support enhanced options:

\![Flutter Logo](https://storage.googleapis.com/cms-storage-bucket/c823e53b3a1a7b0d36a9.png?width=200&height=150&caption=Flutter%20Logo%20with%20caption)

With parameters:
- width: set image width
- height: set image height
- caption: add a caption beneath the image
- align: center (default), left, or right
- radius: set border radius in pixels

## Keyboard Shortcuts

Use <kbd>Ctrl</kbd> + <kbd>F</kbd> to search the documentation.

Navigation shortcuts:
- <kbd>↑</kbd> / <kbd>↓</kbd> - Navigate between sections
- <kbd>Alt</kbd> + <kbd>←</kbd> / <kbd>→</kbd> - Navigate history
- <kbd>Home</kbd> / <kbd>End</kbd> - Jump to first/last section

## Advanced Tables

| Feature | Description | Status |
|---------|-------------|--------|
| Task Lists | Create interactive checklists | ✅ |
| Enhanced Images | Configure images with parameters | ✅ |
| Keyboard Shortcuts | Display keyboard keys | ✅ |
| Advanced Tables | Better table styling with alternate rows | ✅ |
| Metadata | Document metadata support | ✅ |

## Metadata Support

You can add metadata to your documents using YAML frontmatter:

```yaml
---
title: Enhanced Markdown Demo
author: Flutter Structurizr Team
version: 1.0
date: 2023-06-15
tags: markdown, documentation, extensions
---
```

## Code Blocks with Syntax Highlighting

```dart
void main() {
  // TODO('Replace with logging: Hello, enhanced markdown!');
}

// Class example
class MyWidget extends StatelessWidget {
  final String title;

  const MyWidget({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}
```

## Embedding Diagrams

You can embed diagrams from your workspace:

\![System Context](embed:SystemContext?width=600&height=400)

Parameters:
- width: set diagram width
- height: set diagram height 
- showTitle: show/hide the diagram title (default: true)
''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Documentation'),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            tooltip: 'Toggle Dark Mode',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: MarkdownRenderer(
              content: markdownContent,
              isDarkMode: _isDarkMode,
              enableTaskLists: true,
              enableEnhancedImages: true,
              showMetadata: true,
            ),
          ),
        ),
      ),
    );
  }
}
