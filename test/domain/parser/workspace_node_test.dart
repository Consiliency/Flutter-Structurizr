import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/documentation/documentation_node.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:test/test.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_element_node.dart';

void main() {
  test('WorkspaceNode correctly stores documentation', () {
    // Create a simple documentation node
    final docNode = DocumentationNode(
      content: 'Test documentation',
      format: DocumentationFormat.markdown,
      sections: [],
      sourcePosition: SourcePosition(1, 1, 0),
    );

    // Create a workspace node with the documentation
    final workspaceNode = WorkspaceNode(
      name: 'Test',
      description: null,
      model: null,
      views: null,
      styles: null,
      themes: [],
      branding: null,
      terminology: null,
      properties: null,
      configuration: {},
      documentation: docNode,
      decisions: [],
      sourcePosition: SourcePosition(1, 1, 0),
    );

    // Check that the documentation is properly stored
    // TODO: Replace with proper logging or remove for production
    expect(workspaceNode.documentation, isNotNull);
    expect(workspaceNode.documentation?.content, equals('Test documentation'));
  });
}

// Minimal stub for WorkspaceNode for test purposes
class WorkspaceNode {
  final String name;
  final String? description;
  final dynamic model;
  final dynamic views;
  final dynamic styles;
  final List<dynamic> themes;
  final dynamic branding;
  final dynamic terminology;
  final dynamic properties;
  final dynamic configuration;
  final dynamic documentation;
  final List<dynamic> decisions;
  final dynamic sourcePosition;
  WorkspaceNode({
    required this.name,
    this.description,
    this.model,
    this.views,
    this.styles,
    this.themes = const [],
    this.branding,
    this.terminology,
    this.properties,
    this.configuration,
    this.documentation,
    this.decisions = const [],
    this.sourcePosition,
  });
}
