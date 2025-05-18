// Remove legacy AST imports and node type references

import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_node.dart'
    show ModelNode, GroupNode, EnterpriseNode;
import 'ast/nodes/person_node.dart' show PersonNode;
import 'ast/nodes/software_system_node.dart' show SoftwareSystemNode;
import 'ast/nodes/container_node.dart' show ContainerNode;
import 'ast/nodes/component_node.dart' show ComponentNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/relationship_node.dart'
    as rel_node;
import 'ast/nodes/group_node.dart';
import 'ast/nodes/enterprise_node.dart';
import 'ast/nodes/model_element_node.dart';

/// ModelParser is responsible for parsing model-related elements from a list of tokens.
/// This parser handles group blocks, enterprise blocks, nested elements, and implied relationships.
class ModelParser {
  final ErrorReporter _errorReporter;

  ModelParser(this._errorReporter);

  /// Parses a model node from a list of tokens.
  ///
  /// This method reads through the tokens to identify and parse model elements
  /// such as groups, enterprises, software systems, persons, containers,
  /// components, and implied relationships.
  ModelNode parse(List<Token> tokens) {
    final model = ModelNode();

    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];

      if (token.type == TokenType.identifier) {
        if (token.value == 'group' && i + 1 < tokens.length) {
          final groupNode = parseGroup(tokens.sublist(i + 1));
          if (groupNode != null) {
            model.addGroup(groupNode);
          }
          i = _findBlockEnd(tokens, i + 2) + 1;
        } else if (token.value == 'enterprise' && i + 1 < tokens.length) {
          final enterpriseNode = parseEnterprise(tokens.sublist(i + 1));
          if (enterpriseNode != null) {
            model.addEnterprise(enterpriseNode);
          }
          i = _findBlockEnd(tokens, i + 2) + 1;
        } else if (['person', 'softwareSystem', 'container', 'component']
            .contains(token.value)) {
          final elementNode = parseNestedElement(tokens.sublist(i));
          if (elementNode != null) {
            model.addElement(elementNode);
          }
          if (i + 2 < tokens.length &&
              tokens[i + 2].type == TokenType.leftBrace) {
            i = _findBlockEnd(tokens, i + 2) + 1;
          } else {
            i += 2;
            if (i < tokens.length && tokens[i].type == TokenType.string) {
              i++;
            }
            if (i < tokens.length && tokens[i].type == TokenType.string) {
              i++;
            }
          }
          if (i + 2 < tokens.length && tokens[i + 1].type == TokenType.arrow) {
            final relationshipNode =
                parseImpliedRelationship(tokens.sublist(i));
            if (relationshipNode != null) {
              model.addImpliedRelationship(relationshipNode);
            }
            i += 3;
            if (i < tokens.length && tokens[i].type == TokenType.string) {
              i++;
            }
            if (i < tokens.length && tokens[i].type == TokenType.string) {
              i++;
            }
            if (i < tokens.length && tokens[i].type == TokenType.leftBrace) {
              i = _findBlockEnd(tokens, i) + 1;
            }
          } else {
            i++;
          }
        }
      } else {
        i++;
      }
    }

    return model;
  }

  /// Parses a group node from a list of tokens.
  ///
  /// A group is defined as a name followed by a block containing elements:
  /// group "Internal" { ... }
  GroupNode? parseGroup(List<Token> tokens) {
    if (tokens.isEmpty || tokens[0].type != TokenType.string) {
      _errorReporter.error('Expected group name as string',
          tokens.isEmpty ? null : tokens[0].position);
      return null;
    }
    final name = (tokens[0].value as String).replaceAll('"', '');
    if (tokens.length < 2 || tokens[1].type != TokenType.leftBrace) {
      _errorReporter.error('Expected { after group name',
          tokens.length < 2 ? null : tokens[1].position);
      return null;
    }
    // Find the block tokens
    int blockStart = 2;
    int blockEnd = _findBlockEnd(tokens, blockStart);
    final groupNode = GroupNode(name: name);
    if (blockEnd > blockStart) {
      final blockTokens = tokens.sublist(blockStart, blockEnd);
      // Recursively parse children (groups, elements, etc.)
      int i = 0;
      while (i < blockTokens.length) {
        final t = blockTokens[i];
        if (t.type == TokenType.identifier && t.value == 'group') {
          final child = parseGroup(blockTokens.sublist(i + 1));
          if (child != null) groupNode.children.add(child);
          i = _findBlockEnd(blockTokens, i + 2) + 1;
        } else if (t.type == TokenType.identifier && t.value == 'enterprise') {
          final child = parseEnterprise(blockTokens.sublist(i + 1));
          if (child != null) groupNode.children.add(child);
          i = _findBlockEnd(blockTokens, i + 2) + 1;
        } else if (['person', 'softwareSystem', 'container', 'component']
            .contains(t.value)) {
          final element = parseNestedElement(blockTokens.sublist(i));
          if (element != null) groupNode.children.add(element);
          i += 2;
          if (i < blockTokens.length && blockTokens[i].type == TokenType.string) {
            i++;
          }
          if (i < blockTokens.length && blockTokens[i].type == TokenType.string) {
            i++;
          }
          if (i < blockTokens.length &&
              blockTokens[i].type == TokenType.leftBrace) {
            i = _findBlockEnd(blockTokens, i) + 1;
          }
        } else {
          i++;
        }
      }
    }
    return groupNode;
  }

  /// Parses an enterprise node from a list of tokens.
  ///
  /// An enterprise is defined as a name followed by a block containing elements:
  /// enterprise "MyCompany" { ... }
  EnterpriseNode? parseEnterprise(List<Token> tokens) {
    if (tokens.isEmpty || tokens[0].type != TokenType.string) {
      _errorReporter.error('Expected enterprise name as string',
          tokens.isEmpty ? null : tokens[0].position);
      return null;
    }
    final name = (tokens[0].value as String).replaceAll('"', '');
    if (tokens.length < 2 || tokens[1].type != TokenType.leftBrace) {
      _errorReporter.error('Expected { after enterprise name',
          tokens.length < 2 ? null : tokens[1].position);
      return null;
    }
    int blockStart = 2;
    int blockEnd = _findBlockEnd(tokens, blockStart);
    final enterpriseNode = EnterpriseNode(name: name);
    if (blockEnd > blockStart) {
      final blockTokens = tokens.sublist(blockStart, blockEnd);
      int i = 0;
      while (i < blockTokens.length) {
        final t = blockTokens[i];
        if (t.type == TokenType.identifier && t.value == 'group') {
          final child = parseGroup(blockTokens.sublist(i + 1));
          if (child != null) enterpriseNode.children.add(child);
          i = _findBlockEnd(blockTokens, i + 2) + 1;
        } else if (['person', 'softwareSystem', 'container', 'component']
            .contains(t.value)) {
          final element = parseNestedElement(blockTokens.sublist(i));
          if (element != null) enterpriseNode.children.add(element);
          i += 2;
          if (i < blockTokens.length && blockTokens[i].type == TokenType.string) {
            i++;
          }
          if (i < blockTokens.length && blockTokens[i].type == TokenType.string) {
            i++;
          }
          if (i < blockTokens.length &&
              blockTokens[i].type == TokenType.leftBrace) {
            i = _findBlockEnd(blockTokens, i) + 1;
          }
        } else {
          i++;
        }
      }
    }
    return enterpriseNode;
  }

  /// Parses a nested element (person, softwareSystem, container, component) from a list of tokens.
  ///
  /// Elements are defined with a type, name, description (optional), and technology (optional):
  /// person "User" "A user of the system"
  /// container "Web Application" "Frontend UI" "React"
  ModelElementNode? parseNestedElement(List<Token> tokens) {
    if (tokens.isEmpty || tokens[0].type != TokenType.identifier) {
      _errorReporter.error(
          'Expected element type', tokens.isEmpty ? null : tokens[0].position);
      return null;
    }
    final elementType = tokens[0].value;
    if (tokens.length < 2 || tokens[1].type != TokenType.string) {
      _errorReporter.error('Expected element name as string',
          tokens.length < 2 ? null : tokens[1].position);
      return null;
    }
    final name = (tokens[1].value as String).replaceAll('"', '');
    String? description;
    if (tokens.length > 2 && tokens[2].type == TokenType.string) {
      description = (tokens[2].value as String).replaceAll('"', '');
    }
    String? technology;
    if (tokens.length > 3 && tokens[3].type == TokenType.string) {
      technology = (tokens[3].value as String).replaceAll('"', '');
    }
    ModelElementNode? elementNode;
    final id = name.replaceAll(' ', '');
    if (elementType == 'person') {
      elementNode = PersonNode(name: name, id: id) as ModelElementNode;
    } else if (elementType == 'softwareSystem') {
      elementNode = SoftwareSystemNode(name: name, id: id) as ModelElementNode;
    } else if (elementType == 'container') {
      elementNode = ContainerNode(name: name, id: id) as ModelElementNode;
    } else if (elementType == 'component') {
      elementNode = ComponentNode(name: name, id: id) as ModelElementNode;
    } else {
      _errorReporter.error(
          'Unknown element type: $elementType', tokens[0].position);
      return null;
    }
    // If there is a block, recursively parse children (not implemented here, but can be added)
    return elementNode;
  }

  /// Parses an implied relationship from a list of tokens.
  ///
  /// Implied relationships are defined with a source, arrow, destination, and optional description:
  /// user -> system "Uses"
  rel_node.RelationshipNode? parseImpliedRelationship(List<Token> tokens) {
    if (tokens.length < 3 ||
        tokens[0].type != TokenType.identifier ||
        tokens[1].type != TokenType.arrow ||
        tokens[2].type != TokenType.identifier) {
      _errorReporter.error('Invalid relationship syntax',
          tokens.isEmpty ? null : tokens[0].position);
      return null;
    }
    final sourceId = tokens[0].value as String;
    final destinationId = tokens[2].value as String;
    String description = 'uses';
    if (tokens.length > 3 && tokens[3].type == TokenType.string) {
      description = (tokens[3].value as String).replaceAll('"', '');
    }
    String? technology;
    if (tokens.length > 4 && tokens[4].type == TokenType.string) {
      technology = (tokens[4].value as String).replaceAll('"', '');
    }
    final relationshipNode = rel_node.RelationshipNode(
      sourceId: sourceId,
      destinationId: destinationId,
      description: description,
    );
    // Technology can be set as a property if needed
    return relationshipNode;
  }

  /// Helper method to find the end of a block.
  ///
  /// Given a starting position (usually after a left brace),
  /// finds the matching right brace, handling nested blocks.
  int _findBlockEnd(List<Token> tokens, int start) {
    int depth = 0;

    for (int i = start; i < tokens.length; i++) {
      if (tokens[i].type == TokenType.leftBrace) {
        depth++;
      } else if (tokens[i].type == TokenType.rightBrace) {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }

    // If we're here, the block isn't properly terminated
    _errorReporter.error(
        'Unterminated block', tokens.isEmpty ? null : tokens.last.position);
    return tokens.length - 1;
  }
}
