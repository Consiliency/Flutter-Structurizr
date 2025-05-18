import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';

/// A mixin that provides extensions to create workspaces with mock documentation
/// without triggering the issues with the workspace.freezed.dart code.
///
/// This is a workaround to allow tests to run correctly while the Documentation
/// class transition from freezed to regular Dart classes is in progress.
mixin WorkspaceDocumentationMixin {
  /// Creates a test workspace with the given documentation.
  static Workspace createWorkspaceWithDocumentation({
    int id = 1,
    String name = 'Test Workspace',
    Documentation? documentation,
  }) {
    // Use empty documentation if not provided
    final doc = documentation ?? const Documentation();

    // Directly construct a Workspace with the documentation
    // This works in tests without going through copyWith functions
    // that would trigger issues with the workspace.freezed.dart code
    final workspace = Workspace(
      id: id,
      name: name,
      model: const Model(),
      documentation: doc,
    );

    return workspace;
  }
}

/// Extension to provide convenience methods for creating test workspaces
extension WorkspaceExtension on Workspace {
  /// Returns a new workspace with the given documentation
  Workspace withDocumentation(Documentation documentation) {
    // Create a new workspace with the given documentation
    return Workspace(
      id: this.id,
      name: this.name,
      description: this.description,
      version: this.version,
      model: this.model,
      documentation: documentation,
      views: this.views,
      styles: this.styles,
      branding: this.branding,
      configuration: this.configuration,
    );
  }

  /// Returns a new workspace with the given model
  Workspace withModel(Model model) {
    // Create a new workspace with the given model
    return Workspace(
      id: this.id,
      name: this.name,
      description: this.description,
      version: this.version,
      model: model,
      documentation: this.documentation,
      views: this.views,
      styles: this.styles,
      branding: this.branding,
      configuration: this.configuration,
    );
  }
}
