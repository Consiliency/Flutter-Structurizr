import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';

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
          final groupNode = _parseGroup(tokens.sublist(i + 1));
          if (groupNode != null) {
            model.addGroup(groupNode);
            print('[DEBUG] Added group: \\${groupNode.name}');
          }
          i = _findBlockEnd(tokens, i + 2) + 1;
        } else if (token.value == 'enterprise' && i + 1 < tokens.length) {
          final enterpriseNode = _parseEnterprise(tokens.sublist(i + 1));
          if (enterpriseNode != null) {
            model.addEnterprise(enterpriseNode);
            print('[DEBUG] Added enterprise: \\${enterpriseNode.name}');
          }
          i = _findBlockEnd(tokens, i + 2) + 1;
        } else if (['person', 'softwareSystem', 'container', 'component'].contains(token.value)) {
          final elementNode = _parseNestedElement(tokens.sublist(i));
          if (elementNode != null) {
            model.addElement(elementNode);
            print('[DEBUG] Added element: \\${elementNode.name}');
          }
          if (i + 2 < tokens.length && tokens[i + 2].type == TokenType.leftBrace) {
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
            final relationshipNode = _parseImpliedRelationship(tokens.sublist(i));
            if (relationshipNode != null) {
              model.addImpliedRelationship(relationshipNode);
              print('[DEBUG] Added implied relationship: \\${relationshipNode.sourceId} -> \\${relationshipNode.destinationId}');
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
  GroupNode? _parseGroup(List<Token> tokens) {
    if (tokens.isEmpty || tokens[0].type != TokenType.string) {
      _errorReporter.error('Expected group name as string', tokens.isEmpty ? null : tokens[0].position);
      return null;
    }
    
    final name = tokens[0].value.replaceAll('"', '');
    
    // Check for opening brace
    if (tokens.length < 2 || tokens[1].type != TokenType.leftBrace) {
      _errorReporter.error('Expected { after group name', tokens.length < 2 ? null : tokens[1].position);
      return null;
    }
    
    // Create the group node
    final groupNode = GroupNode(name: name);
    
    // Find the end of the block
    if (tokens.length < 3) {
      _errorReporter.error('Unterminated group block', tokens.isEmpty ? null : tokens.last.position);
      return groupNode;
    }
    
    // Parse elements inside the group block
    // This is a simplified implementation
    // In a complete implementation, we would extract the block tokens and parse them
    
    return groupNode;
  }
  
  /// Parses an enterprise node from a list of tokens.
  ///
  /// An enterprise is defined as a name followed by a block containing elements:
  /// enterprise "MyCompany" { ... }
  EnterpriseNode? _parseEnterprise(List<Token> tokens) {
    if (tokens.isEmpty || tokens[0].type != TokenType.string) {
      _errorReporter.error('Expected enterprise name as string', tokens.isEmpty ? null : tokens[0].position);
      return null;
    }
    
    final name = tokens[0].value.replaceAll('"', '');
    
    // Check for opening brace
    if (tokens.length < 2 || tokens[1].type != TokenType.leftBrace) {
      _errorReporter.error('Expected { after enterprise name', tokens.length < 2 ? null : tokens[1].position);
      return null;
    }
    
    // Create the enterprise node
    final enterpriseNode = EnterpriseNode(name: name);
    
    // Find the end of the block
    if (tokens.length < 3) {
      _errorReporter.error('Unterminated enterprise block', tokens.isEmpty ? null : tokens.last.position);
      return enterpriseNode;
    }
    
    // Parse elements inside the enterprise block
    // This is a simplified implementation
    // In a complete implementation, we would extract the block tokens and parse them
    
    return enterpriseNode;
  }
  
  /// Parses a nested element (person, softwareSystem, container, component) from a list of tokens.
  ///
  /// Elements are defined with a type, name, description (optional), and technology (optional):
  /// person "User" "A user of the system"
  /// container "Web Application" "Frontend UI" "React"
  ElementNode? _parseNestedElement(List<Token> tokens) {
    if (tokens.isEmpty || tokens[0].type != TokenType.identifier) {
      _errorReporter.error('Expected element type', tokens.isEmpty ? null : tokens[0].position);
      return null;
    }
    
    final elementType = tokens[0].value;
    
    // Check for element name
    if (tokens.length < 2 || tokens[1].type != TokenType.string) {
      _errorReporter.error('Expected element name as string', tokens.length < 2 ? null : tokens[1].position);
      return null;
    }
    
    final name = tokens[1].value.replaceAll('"', '');
    
    // Extract description if present
    String? description;
    if (tokens.length > 2 && tokens[2].type == TokenType.string) {
      description = tokens[2].value.replaceAll('"', '');
    }
    
    // Extract technology if present
    String? technology;
    if (tokens.length > 3 && tokens[3].type == TokenType.string) {
      technology = tokens[3].value.replaceAll('"', '');
    }
    
    // Create the appropriate element node based on type
    ElementNode? elementNode;
    final id = name.replaceAll(' ', '');
    
    switch (elementType) {
      case 'person':
        elementNode = PersonNode(name: name, id: id);
        break;
      case 'softwareSystem':
        elementNode = SoftwareSystemNode(name: name, id: id);
        break;
      case 'container':
        elementNode = ContainerNode(name: name, id: id);
        break;
      case 'component':
        elementNode = ComponentNode(name: name, id: id);
        break;
      default:
        _errorReporter.error('Unknown element type: $elementType', tokens[0].position);
        return null;
    }
    
    // Set description if provided
    if (description != null) {
      elementNode.setProperty('description', description);
    }
    
    // Set technology if provided
    if (technology != null) {
      elementNode.setProperty('technology', technology);
    }
    
    return elementNode;
  }
  
  /// Parses an implied relationship from a list of tokens.
  ///
  /// Implied relationships are defined with a source, arrow, destination, and optional description:
  /// user -> system "Uses"
  RelationshipNode? _parseImpliedRelationship(List<Token> tokens) {
    if (tokens.length < 3 ||
        tokens[0].type != TokenType.identifier ||
        tokens[1].type != TokenType.arrow ||
        tokens[2].type != TokenType.identifier) {
      _errorReporter.error('Invalid relationship syntax', tokens.isEmpty ? null : tokens[0].position);
      return null;
    }
    
    final sourceId = tokens[0].value;
    final destinationId = tokens[2].value;
    
    // Extract description if present
    String description = 'uses'; // Default description
    if (tokens.length > 3 && tokens[3].type == TokenType.string) {
      description = tokens[3].value.replaceAll('"', '');
    }
    
    // Extract technology if present
    String? technology;
    if (tokens.length > 4 && tokens[4].type == TokenType.string) {
      technology = tokens[4].value.replaceAll('"', '');
    }
    
    // Create the relationship node
    final relationshipNode = RelationshipNode(
      sourceId: sourceId,
      destinationId: destinationId,
      description: description,
    );
    
    // Set technology if provided
    if (technology != null) {
      relationshipNode.setProperty('technology', technology);
    }
    
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
    _errorReporter.error('Unterminated block', tokens.isEmpty ? null : tokens.last.position);
    return tokens.length - 1;
  }
}