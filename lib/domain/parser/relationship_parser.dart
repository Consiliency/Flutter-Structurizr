import 'ast/nodes/model_element_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/source_position.dart';
import 'error_reporter.dart';
import 'lexer/token.dart';
import 'context_stack.dart';
import 'element_parser.dart';

/// Parser for relationship elements in the Structurizr DSL.
///
/// This class handles parsing various types of relationships:
/// - Explicit relationships using arrow syntax: source -> destination "Description" "Technology"
/// - Implicit relationships using keywords: source uses destination "Description" "Technology"
/// - Group relationships: group elements with shared relationships
/// - Nested relationships: relationships defined within element hierarchies
class RelationshipParser {
  /// The error reporter for collecting parse errors.
  final ErrorReporter errorReporter;

  /// The context stack for tracking parsing context
  final ContextStack contextStack;

  /// Reference to the ElementParser for parsing identifiers
  final ElementParser? elementParser;

  /// Creates a new relationship parser with the specified error reporter.
  RelationshipParser({
    required this.errorReporter,
    ContextStack? contextStack,
    this.elementParser,
  }) : this.contextStack = contextStack ?? ContextStack();

  /// Parses relationships from a token list.
  ///
  /// This method analyzes the token list and delegates to the appropriate parsing
  /// method based on the relationship type detected.
  ///
  /// Returns a list of relationship nodes parsed from the tokens.
  List<RelationshipNode> parse(List<Token> tokens) {
    if (tokens.isEmpty) return [];

    // Push relationship context onto the stack
    contextStack.push(Context('relationship'));

    var relationships = <RelationshipNode>[];

    try {
      // Determine the type of relationship and parse accordingly
      if (_isExplicitRelationship(tokens)) {
        final relationship = _parseExplicit(tokens);
        if (relationship != null) {
          relationships.add(relationship);
        }
      } else if (_isImplicitRelationship(tokens)) {
        final relationship = _parseImplicit(tokens);
        if (relationship != null) {
          relationships.add(relationship);
        }
      } else if (_isGroupRelationship(tokens)) {
        _parseGroup(tokens);
        // Group processing would add relationships in a real implementation
      } else if (_isNestedRelationship(tokens)) {
        _parseNested(tokens);
        // Nested processing would add relationships in a real implementation
      } else {
        handleError('Unknown relationship type',
            tokens.isNotEmpty ? tokens[0].position : null);
      }
    } catch (e) {
      handleError('Error parsing relationship: $e',
          tokens.isNotEmpty ? tokens[0].position : null);
    } finally {
      // Make sure to pop context even in case of error
      if (contextStack.isNotEmpty() &&
          contextStack.current().name == 'relationship') {
        contextStack.pop();
      }
    }

    return relationships;
  }

  /// Checks if the token list represents an explicit relationship (using arrow syntax).
  bool _isExplicitRelationship(List<Token> tokens) {
    if (tokens.isEmpty) return false;
    return tokens.any((t) => t.lexeme == '->');
  }

  /// Checks if the token list represents an implicit relationship (using keywords like 'uses').
  bool _isImplicitRelationship(List<Token> tokens) {
    if (tokens.isEmpty) return false;

    // Common relationship verbs in Structurizr DSL
    const relationshipVerbs = [
      'uses',
      'delivers',
      'influences',
      'syncs',
      'reads',
      'writes'
    ];

    for (int i = 1; i < tokens.length - 1; i++) {
      if (relationshipVerbs.contains(tokens[i].lexeme.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  /// Checks if the token list represents a group relationship.
  bool _isGroupRelationship(List<Token> tokens) {
    if (tokens.isEmpty) return false;

    // Check for a group keyword at the start
    return tokens.first.lexeme == 'group';
  }

  /// Checks if the token list represents a nested relationship within an element.
  bool _isNestedRelationship(List<Token> tokens) {
    if (tokens.isEmpty) return false;

    // Element types that can contain nested relationships
    const containerElements = [
      'softwareSystem',
      'container',
      'component',
      'deploymentEnvironment',
      'deploymentNode',
      'infrastructureNode'
    ];

    // Check if the first token is an element that can contain nested elements
    return containerElements.contains(tokens.first.lexeme);
  }

  /// Parses an explicit relationship defined with arrow syntax.
  ///
  /// Example: user -> system "Uses" "HTTP"
  RelationshipNode? _parseExplicit(List<Token> tokens) {
    if (tokens.isEmpty) return null;

    // Push explicit relationship context
    contextStack.push(Context('explicitRelationship'));

    try {
      // Find the arrow token
      int arrowIndex = -1;
      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i].lexeme == '->') {
          arrowIndex = i;
          break;
        }
      }

      if (arrowIndex == -1 ||
          arrowIndex == 0 ||
          arrowIndex >= tokens.length - 1) {
        handleError(
            'Invalid relationship syntax: arrow (->) not found or at invalid position',
            tokens.first.position);
        return null;
      }

      // Extract source and destination using ElementParser if available
      String sourceId;
      String destinationId;

      if (elementParser != null) {
        // Use ElementParser.parseIdentifier to get source and destination
        sourceId =
            elementParser!.parseIdentifier(tokens.sublist(0, arrowIndex));
        final destStartIdx = arrowIndex + 1;

        // Find where destination ends (before any string literals)
        int destEndIdx = tokens.length;
        for (int i = destStartIdx; i < tokens.length; i++) {
          if (tokens[i].type == TokenType.string) {
            destEndIdx = i;
            break;
          }
        }

        destinationId = elementParser!
            .parseIdentifier(tokens.sublist(destStartIdx, destEndIdx));
      } else {
        // Fallback if ElementParser is not available
        sourceId =
            tokens.sublist(0, arrowIndex).map((t) => t.lexeme).join(' ').trim();

        // Process destination and find where string literals start
        int destEndIdx = tokens.length;
        for (int i = arrowIndex + 1; i < tokens.length; i++) {
          if (tokens[i].type == TokenType.string) {
            destEndIdx = i;
            break;
          }
        }

        destinationId = tokens
            .sublist(arrowIndex + 1, destEndIdx)
            .map((t) => t.lexeme)
            .join(' ')
            .trim();
      }

      // Find the first string literal if any (for description)
      int descriptionIndex = -1;
      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i].type == TokenType.string) {
          descriptionIndex = i;
          break;
        }
      }

      String? description;
      String? technology;

      if (descriptionIndex != -1) {
        // Extract description
        description = tokens[descriptionIndex]
            .lexeme
            .replaceAll('"', ''); // Remove quotes

        // Check if there's a technology string
        if (descriptionIndex + 1 < tokens.length &&
            tokens[descriptionIndex + 1].type == TokenType.string) {
          technology = tokens[descriptionIndex + 1]
              .lexeme
              .replaceAll('"', ''); // Remove quotes
        }
      }

      // Create the relationship node
      final relationshipNode = RelationshipNode(
        sourceId: sourceId,
        destinationId: destinationId,
        description: description ?? '',
        technology: technology,
        sourcePosition: tokens.first.position,
      );

      // Pop the context
      contextStack.pop();
      return relationshipNode;
    } catch (e) {
      handleError(
          'Error parsing explicit relationship: $e', tokens.first.position);

      // Make sure to pop context even in case of error
      if (contextStack.isNotEmpty() &&
          contextStack.current().name == 'explicitRelationship') {
        contextStack.pop();
      }
      return null;
    }
  }

  /// Parses an implicit relationship defined with keywords.
  ///
  /// Example: user uses system "For authentication" "HTTPS"
  RelationshipNode? _parseImplicit(List<Token> tokens) {
    if (tokens.isEmpty) return null;

    // Push implicit relationship context
    contextStack.push(Context('implicitRelationship'));

    try {
      // Common relationship verbs in Structurizr DSL
      const relationshipVerbs = [
        'uses',
        'delivers',
        'influences',
        'syncs',
        'reads',
        'writes'
      ];

      // Find the relationship verb
      int verbIndex = -1;
      for (int i = 1; i < tokens.length - 1; i++) {
        if (relationshipVerbs.contains(tokens[i].lexeme.toLowerCase())) {
          verbIndex = i;
          break;
        }
      }

      if (verbIndex == -1 || verbIndex == 0 || verbIndex >= tokens.length - 1) {
        handleError(
            'Invalid implicit relationship syntax: relationship verb not found or at invalid position',
            tokens.first.position);
        return null;
      }

      // Extract source and destination using ElementParser if available
      String sourceId;
      String destinationId;

      if (elementParser != null) {
        // Use ElementParser.parseIdentifier to get source and destination
        sourceId = elementParser!.parseIdentifier(tokens.sublist(0, verbIndex));

        final destStartIdx = verbIndex + 1;

        // Find where destination ends (before any string literals)
        int destEndIdx = tokens.length;
        for (int i = destStartIdx; i < tokens.length; i++) {
          if (tokens[i].type == TokenType.string) {
            destEndIdx = i;
            break;
          }
        }

        destinationId = elementParser!
            .parseIdentifier(tokens.sublist(destStartIdx, destEndIdx));
      } else {
        // Fallback if ElementParser is not available
        sourceId =
            tokens.sublist(0, verbIndex).map((t) => t.lexeme).join(' ').trim();

        // Process destination and find where string literals start
        final destStartIdx = verbIndex + 1;
        int destEndIdx = tokens.length;
        for (int i = destStartIdx; i < tokens.length; i++) {
          if (tokens[i].type == TokenType.string) {
            destEndIdx = i;
            break;
          }
        }

        destinationId = tokens
            .sublist(destStartIdx, destEndIdx)
            .map((t) => t.lexeme)
            .join(' ')
            .trim();
      }

      // Find the first string literal if any (for description)
      int descriptionIndex = -1;
      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i].type == TokenType.string) {
          descriptionIndex = i;
          break;
        }
      }

      String? description;
      String? technology;

      if (descriptionIndex != -1) {
        // Extract description
        description = tokens[descriptionIndex]
            .lexeme
            .replaceAll('"', ''); // Remove quotes

        // Check if there's a technology string
        if (descriptionIndex + 1 < tokens.length &&
            tokens[descriptionIndex + 1].type == TokenType.string) {
          technology = tokens[descriptionIndex + 1]
              .lexeme
              .replaceAll('"', ''); // Remove quotes
        }
      }

      // The description is derived from the verb by default if not explicitly provided
      description ??= tokens[verbIndex].lexeme.capitalize();

      // Create the relationship node
      final relationshipNode = RelationshipNode(
        sourceId: sourceId,
        destinationId: destinationId,
        description: description ?? '',
        technology: technology,
        sourcePosition: tokens.first.position,
      );

      // Pop the context
      contextStack.pop();
      return relationshipNode;
    } catch (e) {
      handleError(
          'Error parsing implicit relationship: $e', tokens.first.position);

      // Make sure to pop context even in case of error
      if (contextStack.isNotEmpty() &&
          contextStack.current().name == 'implicitRelationship') {
        contextStack.pop();
      }
      return null;
    }
  }

  /// Parses relationships within a group.
  ///
  /// Example:
  /// group "External Users" {
  ///   user -> system "Uses"
  /// }
  void _parseGroup(List<Token> tokens) {
    if (tokens.isEmpty || tokens.first.lexeme != 'group') {
      handleError('Invalid group relationship syntax: missing group keyword',
          tokens.first.position);
      return;
    }

    // Push group context onto the stack
    contextStack.push(Context('group'));

    try {
      // Find the opening brace
      int openBraceIndex = -1;
      for (int i = 1; i < tokens.length; i++) {
        if (tokens[i].lexeme == '{') {
          openBraceIndex = i;
          break;
        }
      }

      if (openBraceIndex == -1) {
        handleError('Invalid group relationship syntax: missing opening brace',
            tokens.first.position);
        return;
      }

      // Find the matching closing brace
      int closeBraceIndex = -1;
      int braceCount = 1;
      for (int i = openBraceIndex + 1; i < tokens.length; i++) {
        if (tokens[i].lexeme == '{') {
          braceCount++;
        } else if (tokens[i].lexeme == '}') {
          braceCount--;
          if (braceCount == 0) {
            closeBraceIndex = i;
            break;
          }
        }
      }

      if (closeBraceIndex == -1) {
        handleError('Invalid group relationship syntax: missing closing brace',
            tokens.first.position);
        return;
      }

      // Extract the group content tokens
      final contentTokens = tokens.sublist(openBraceIndex + 1, closeBraceIndex);

      // Recursively parse the content for relationships
      if (contentTokens.isNotEmpty) {
        parse(contentTokens);
      }
    } catch (e) {
      handleError(
          'Error parsing group relationship: $e', tokens.first.position);
    } finally {
      // Make sure to pop context even in case of error
      if (contextStack.isNotEmpty() && contextStack.current().name == 'group') {
        contextStack.pop();
      }
    }
  }

  /// Parses relationships nested within an element.
  ///
  /// Example:
  /// softwareSystem "System" {
  ///   container "Web App" {
  ///     -> database "Reads from"
  ///   }
  /// }
  void _parseNested(List<Token> tokens) {
    if (tokens.isEmpty) {
      handleError('Invalid nested relationship syntax: empty token list',
          const SourcePosition(0, 0, 0));
      return;
    }

    // Push nested element context onto the stack
    contextStack.push(Context('nestedElement'));

    try {
      // Find the opening brace
      int openBraceIndex = -1;
      for (int i = 1; i < tokens.length; i++) {
        if (tokens[i].lexeme == '{') {
          openBraceIndex = i;
          break;
        }
      }

      if (openBraceIndex == -1) {
        handleError('Invalid nested relationship syntax: missing opening brace',
            tokens.first.position);
        return;
      }

      // Find the matching closing brace
      int closeBraceIndex = -1;
      int braceCount = 1;
      for (int i = openBraceIndex + 1; i < tokens.length; i++) {
        if (tokens[i].lexeme == '{') {
          braceCount++;
        } else if (tokens[i].lexeme == '}') {
          braceCount--;
          if (braceCount == 0) {
            closeBraceIndex = i;
            break;
          }
        }
      }

      if (closeBraceIndex == -1) {
        handleError('Invalid nested relationship syntax: missing closing brace',
            tokens.first.position);
        return;
      }

      // Extract the element name or identifier
      final elementIdentifier = tokens
          .sublist(0, openBraceIndex)
          .map((t) => t.lexeme)
          .join(' ')
          .trim();

      // Add element identifier to context for reference
      contextStack.current().data['currentElement'] = elementIdentifier;

      // Extract the content tokens
      final contentTokens = tokens.sublist(openBraceIndex + 1, closeBraceIndex);

      // Recursively parse the content for relationships
      if (contentTokens.isNotEmpty) {
        parse(contentTokens);
      }
    } catch (e) {
      handleError(
          'Error parsing nested relationship: $e', tokens.first.position);
    } finally {
      // Make sure to pop context even in case of error
      if (contextStack.isNotEmpty() &&
          contextStack.current().name == 'nestedElement') {
        contextStack.pop();
      }
    }
  }

  /// Helper method to handle errors consistently
  void handleError(String message, SourcePosition? position) {
    if (position != null) {
      errorReporter.reportStandardError(message, position.offset);
    } else {
      errorReporter.reportStandardError(message, 0);
    }
  }
}

// Helper extension methods
extension StringHelpers on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

// Extension methods for setting source and destination on relationship nodes
extension RelationshipNodeExtensions on RelationshipNode {
  /// Creates a copy of this relationship node with a new source ID.
  RelationshipNode setSource(String newSourceId) {
    return RelationshipNode(
      sourceId: newSourceId,
      destinationId: destinationId,
      description: description,
      technology: technology,
      tags: tags,
      properties: properties,
      sourcePosition: sourcePosition,
    );
  }

  /// Creates a copy of this relationship node with a new destination ID.
  RelationshipNode setDestination(String newDestinationId) {
    return RelationshipNode(
      sourceId: sourceId,
      destinationId: newDestinationId,
      description: description,
      technology: technology,
      tags: tags,
      properties: properties,
      sourcePosition: sourcePosition,
    );
  }
}
