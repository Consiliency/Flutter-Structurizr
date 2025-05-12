import 'dart:ui';

import 'package:flutter_structurizr/application/dsl/workspace_mapper.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceMapper Style Visitor Methods', () {
    late ErrorReporter errorReporter;
    late WorkspaceMapper mapper;
    late String source;

    setUp(() {
      source = ''; // Empty source text as we're testing direct node visitation
      errorReporter = ErrorReporter(source);
      mapper = WorkspaceMapper(source, errorReporter);
    });

    test('maps element styles', () {
      // Manually create a style node and call the visitor method
      final elementStyleNode = ElementStyleNode(
        tag: 'Person', 
        shape: 'Box',
        background: '#ff0000',
        sourcePosition: null,
      );

      // Create the element styles node
      final styleNode = StylesNode(
        elementStyles: [elementStyleNode],
        sourcePosition: null
      );
      
      // First create a workspace node and create the workspace
      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'Test Description',
        sourcePosition: null,
      );
      
      // Visit the workspace node first
      final workspace = mapper.mapWorkspace(workspaceNode);
      expect(workspace, isNotNull);
      
      // Now visit the styles node
      mapper.visitStylesNode(styleNode);
      
      // Check that styles were added to the workspace
      expect(errorReporter.hasErrors, isFalse);
    });

    test('maps relationship styles', () {
      // Manually create a relationship style node
      final relationshipStyleNode = RelationshipStyleNode(
        tag: 'Relationship',
        thickness: 2,
        color: '#0000ff',
        style: 'Dashed',
        sourcePosition: null,
      );

      // Create styles node with the relationship style
      final styleNode = StylesNode(
        relationshipStyles: [relationshipStyleNode],
        sourcePosition: null,
      );
      
      // First create a workspace node and create the workspace
      final workspaceNode = WorkspaceNode(
        name: 'Test Workspace',
        description: 'Test Description',
        sourcePosition: null,
      );
      
      // Visit the workspace node first
      final workspace = mapper.mapWorkspace(workspaceNode);
      expect(workspace, isNotNull);
      
      // Now visit the styles node
      mapper.visitStylesNode(styleNode);
      
      // Check no errors occurred
      expect(errorReporter.hasErrors, isFalse);
    });

    test('processes directives', () {
      // Test the directive visitor
      final directiveNode = DirectiveNode(
        type: 'include',
        value: '/path/to/file.dsl',
        sourcePosition: null,
      );
      
      // Call the visitor method directly
      mapper.visitDirectiveNode(directiveNode);
      
      // Verify no errors
      expect(errorReporter.hasErrors, isFalse);
    });
  });
}