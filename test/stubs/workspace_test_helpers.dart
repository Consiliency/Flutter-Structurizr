import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'mock_documentation.dart';

/// A class containing helper methods for testing workspaces with documentation.
class WorkspaceTestHelpers {
  /// Creates a test workspace with documentation for widget testing.
  /// 
  /// This method creates a workspace with a mock documentation implementation
  /// that works around the freezed code generation issues.
  static Workspace createTestWorkspace({
    int id = 1,
    String name = 'Test Workspace',
    String? description,
    String? version,
    Model? model,
    Documentation? documentation,
    Views? views,
    Styles? styles,
  }) {
    final testModel = model ?? Model();
    final testViews = views ?? Views();
    final testStyles = styles ?? Styles();
    
    // If documentation is provided, convert it to MockDocumentation to avoid freezed issues
    Documentation? testDocumentation;
    if (documentation != null) {
      testDocumentation = MockDocumentation(
        sections: documentation.sections,
        decisions: documentation.decisions,
        images: documentation.images,
      );
    }
    
    return Workspace(
      id: id,
      name: name, 
      description: description,
      version: version,
      model: testModel,
      documentation: testDocumentation,
      views: testViews,
      styles: testStyles,
    );
  }
}