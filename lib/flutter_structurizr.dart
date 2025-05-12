/// Flutter Structurizr
///
/// A Dart/Flutter implementation of the Structurizr architecture visualization tool.
/// Provides widgets and utilities for creating, viewing, and exporting C4 model diagrams.
library flutter_structurizr;

// Core domain models
export 'domain/model/workspace.dart';
export 'domain/model/element.dart';
export 'domain/view/view.dart';

// Widgets
export 'widgets.dart';

// Presentation components
export 'presentation/layout/layout_strategy.dart';

// Rendering utilities
export 'presentation/rendering/rendering.dart' hide DiagramPainter;

// Workspace management
export 'application/workspace/workspace_repository.dart';
export 'infrastructure/persistence/file_storage.dart';
export 'infrastructure/persistence/auto_save.dart';