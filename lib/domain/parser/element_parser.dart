import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/context_stack.dart';
import 'package:flutter_structurizr/domain/parser/model_parser.dart';
import 'package:flutter_structurizr/domain/parser/relationship_parser.dart';

/// Parser for elements in the Structurizr DSL.
/// 
/// This class is responsible for parsing Person and SoftwareSystem elements,
/// including their identifiers and parent-child relationships.
class ElementParser {
  /// Error reporter for handling parsing errors
  final ErrorReporter errorReporter;
  
  /// The context stack for tracking parsing context
  final ContextStack contextStack;
  
  /// The model parser for parsing nested elements
  final ModelParser? modelParser;
  
  /// The relationship parser for parsing relationships
  final RelationshipParser? relationshipParser;

  /// Creates a new ElementParser with the given error reporter.
  ElementParser(this.errorReporter, {
    ContextStack? contextStack,
    this.modelParser,
    this.relationshipParser,
  }) : this.contextStack = contextStack ?? ContextStack();

  /// Parses a Person element from the given tokens.
  /// 
  /// Example DSL:
  /// ```
  /// person "User" "A standard user" "external,user"
  /// ```
  /// 
  /// Or with a block:
  /// ```
  /// person "Admin" {
  ///   description = "System administrator"
  ///   tags = "internal,admin"
  /// }
  /// ```
  PersonNode parsePerson(List<Token> tokens) {
    if (tokens.isEmpty) {
      handleError("No tokens provided for person element", null);
      return PersonNode(id: "error", name: "Error");
    }
    
    // Push person context onto the stack
    contextStack.push(Context('person'));
    
    try {
      // Ensure first token is 'person'
      if (tokens[0].type != TokenType.person && tokens[0].lexeme != 'person') {
        handleError("Expected 'person' keyword at start of person element", tokens[0].position);
      }
      
      // Parse name (required)
      if (tokens.length < 2 || tokens[1].type != TokenType.string) {
        handleError("Expected person name as string", tokens.length < 2 ? null : tokens[1].position);
        contextStack.pop();
        return PersonNode(id: "error", name: "Error");
      }
      
      // Extract the name
      final name = tokens[1].value as String? ?? tokens[1].lexeme.replaceAll('"', '');
      
      // Create person node with name and generated ID
      final id = name.replaceAll(' ', '');
      final personNode = PersonNode(id: id, name: name);
      
      // Set identifier
      personNode.setIdentifier(id);
      
      // Parse description if present
      if (tokens.length > 2 && tokens[2].type == TokenType.string) {
        final description = tokens[2].value as String? ?? tokens[2].lexeme.replaceAll('"', '');
        personNode.setProperty('description', description);
      }
      
      // Parse tags if present
      if (tokens.length > 3 && tokens[3].type == TokenType.string) {
        final tags = tokens[3].value as String? ?? tokens[3].lexeme.replaceAll('"', '');
        personNode.setProperty('tags', tags);
      }
      
      // Check for and parse block content
      int blockStart = -1;
      for (int i = 1; i < tokens.length; i++) {
        if (tokens[i].type == TokenType.leftBrace) {
          blockStart = i;
          break;
        }
      }
      
      if (blockStart != -1) {
        // Find matching closing brace
        int blockEnd = blockStart + 1;
        int braceCount = 1;
        
        while (blockEnd < tokens.length && braceCount > 0) {
          if (tokens[blockEnd].type == TokenType.leftBrace) {
            braceCount++;
          } else if (tokens[blockEnd].type == TokenType.rightBrace) {
            braceCount--;
          }
          
          if (braceCount > 0) {
            blockEnd++;
          }
        }
        
        if (braceCount != 0) {
          handleError("Unmatched brace in person block", tokens[blockStart].position);
        } else {
          // Parse the block contents
          _parseParentChild(tokens.sublist(blockStart + 1, blockEnd));
        }
      }
      
      // Pop context from stack
      contextStack.pop();
      return personNode;
    } catch (e) {
      handleError("Error parsing person element: $e", tokens.isNotEmpty ? tokens[0].position : null);
      // Make sure to pop the context even in case of error
      if (contextStack.isNotEmpty() && contextStack.current().name == 'person') {
        contextStack.pop();
      }
      return PersonNode(id: "error", name: "Error");
    }
  }

  /// Parses a SoftwareSystem element from the given tokens.
  /// 
  /// Example DSL:
  /// ```
  /// softwareSystem "Payment System" "Handles payments" "external,payment"
  /// ```
  /// 
  /// Or with a block:
  /// ```
  /// softwareSystem "E-Commerce System" {
  ///   description = "Handles all e-commerce functionality"
  ///   container "Web Application" "Provides the web interface" "React"
  /// }
  /// ```
  SoftwareSystemNode parseSoftwareSystem(List<Token> tokens) {
    if (tokens.isEmpty) {
      handleError("No tokens provided for software system element", null);
      return SoftwareSystemNode(id: "error", name: "Error");
    }
    
    // Push software system context onto the stack
    contextStack.push(Context('softwareSystem'));
    
    try {
      // Ensure first token is 'softwareSystem'
      if (tokens[0].type != TokenType.softwareSystem && tokens[0].lexeme != 'softwareSystem') {
        handleError("Expected 'softwareSystem' keyword at start of software system element", tokens[0].position);
      }
      
      // Parse name (required)
      if (tokens.length < 2 || tokens[1].type != TokenType.string) {
        handleError("Expected software system name as string", tokens.length < 2 ? null : tokens[1].position);
        contextStack.pop();
        return SoftwareSystemNode(id: "error", name: "Error");
      }
      
      // Extract the name
      final name = tokens[1].value as String? ?? tokens[1].lexeme.replaceAll('"', '');
      
      // Create software system node with name and generated ID
      final id = name.replaceAll(' ', '');
      final softwareSystemNode = SoftwareSystemNode(id: id, name: name);
      
      // Set identifier
      softwareSystemNode.setIdentifier(id);
      
      // Parse description if present
      if (tokens.length > 2 && tokens[2].type == TokenType.string) {
        final description = tokens[2].value as String? ?? tokens[2].lexeme.replaceAll('"', '');
        softwareSystemNode.setProperty('description', description);
      }
      
      // Parse tags if present
      if (tokens.length > 3 && tokens[3].type == TokenType.string) {
        final tags = tokens[3].value as String? ?? tokens[3].lexeme.replaceAll('"', '');
        softwareSystemNode.setProperty('tags', tags);
      }
      
      // Check for and parse block content
      int blockStart = -1;
      for (int i = 1; i < tokens.length; i++) {
        if (tokens[i].type == TokenType.leftBrace) {
          blockStart = i;
          break;
        }
      }
      
      if (blockStart != -1) {
        // Find matching closing brace
        int blockEnd = blockStart + 1;
        int braceCount = 1;
        
        while (blockEnd < tokens.length && braceCount > 0) {
          if (tokens[blockEnd].type == TokenType.leftBrace) {
            braceCount++;
          } else if (tokens[blockEnd].type == TokenType.rightBrace) {
            braceCount--;
          }
          
          if (braceCount > 0) {
            blockEnd++;
          }
        }
        
        if (braceCount != 0) {
          handleError("Unmatched brace in software system block", tokens[blockStart].position);
        } else {
          // Parse the block contents
          _parseParentChild(tokens.sublist(blockStart + 1, blockEnd));
        }
      }
      
      // Pop context from stack
      contextStack.pop();
      return softwareSystemNode;
    } catch (e) {
      handleError("Error parsing software system element: $e", tokens.isNotEmpty ? tokens[0].position : null);
      // Make sure to pop the context even in case of error
      if (contextStack.isNotEmpty() && contextStack.current().name == 'softwareSystem') {
        contextStack.pop();
      }
      return SoftwareSystemNode(id: "error", name: "Error");
    }
  }

  /// Private method for parsing identifiers.
  /// 
  /// This method extracts the identifier (name) from a token, which can be
  /// either a string token or an identifier token.
  String _parseIdentifier(List<Token> tokens) {
    if (tokens.isEmpty) {
      handleError("Expected identifier but found no tokens", null);
      return "error";
    }
    
    final token = tokens[0];
    
    if (token.type == TokenType.identifier) {
      return token.lexeme;
    } else if (token.type == TokenType.string) {
      return token.value as String? ?? token.lexeme.replaceAll('"', '');
    } else {
      handleError("Expected identifier or string, found ${token.type}", token.position);
      return "error";
    }
  }

  /// Private method for parsing parent-child relationships.
  /// 
  /// This method handles the contents inside braces, which can include:
  /// - Properties (description, tags, etc.)
  /// - Child elements (containers, components, etc.)
  /// - Relationships
  void _parseParentChild(List<Token> tokens) {
    if (tokens.isEmpty) {
      handleError("No tokens provided for parent-child block", null);
      return;
    }
    
    try {
      int i = 0;
      while (i < tokens.length) {
        // Skip any whitespace or unexpected tokens
        if (tokens[i].type == TokenType.identifier || 
            tokens[i].type == TokenType.container || 
            tokens[i].type == TokenType.component) {
          
          // Check for property assignments
          if (i + 2 < tokens.length && tokens[i+1].type == TokenType.equals) {
            final propertyName = tokens[i].lexeme;
            final propertyValue = tokens[i+2].value as String? ?? 
                                  tokens[i+2].lexeme.replaceAll('"', '');
            
            // Set property on current element
            final currentContext = contextStack.current();
            if (currentContext.data.containsKey('currentElement')) {
              final element = currentContext.data['currentElement'] as ElementNode;
              element.setProperty(propertyName, propertyValue);
            } else {
              handleError("No current element to set property on", tokens[i].position);
            }
            
            i += 3; // Skip property name, equals, and value
          }
          // Check for nested element or relationship
          else if (tokens[i].type == TokenType.container || 
                  tokens[i].type == TokenType.component ||
                  tokens[i].lexeme == 'container' || 
                  tokens[i].lexeme == 'component') {
            
            // Delegate to model parser for nested element if available
            if (modelParser != null) {
              final nestedElement = modelParser!._parseNestedElement(tokens.sublist(i));
              
              // Add the child element to the parent
              final currentContext = contextStack.current();
              if (currentContext.data.containsKey('currentElement')) {
                final parentElement = currentContext.data['currentElement'] as ElementNode;
                if (nestedElement != null) {
                  parentElement.addChild(nestedElement);
                }
              }
              
              // Skip the parsed tokens
              // Find how many tokens to skip
              int toSkip = 2; // At minimum, skip the element type and name
              if (i + toSkip < tokens.length && tokens[i + toSkip].type == TokenType.string) {
                toSkip++; // Skip description
              }
              if (i + toSkip < tokens.length && tokens[i + toSkip].type == TokenType.string) {
                toSkip++; // Skip technology/tags
              }
              if (i + toSkip < tokens.length && tokens[i + toSkip].type == TokenType.leftBrace) {
                // Skip block
                int j = i + toSkip + 1;
                int braceCount = 1;
                while (j < tokens.length && braceCount > 0) {
                  if (tokens[j].type == TokenType.leftBrace) braceCount++;
                  if (tokens[j].type == TokenType.rightBrace) braceCount--;
                  j++;
                }
                toSkip = j - i;
              }
              i += toSkip;
            } else {
              // No model parser, just skip
              handleError("Model parser not available for nested element", tokens[i].position);
              i++;
            }
          }
          // Check for relationship
          else if (i + 2 < tokens.length && tokens[i+1].type == TokenType.arrow) {
            // Delegate to relationship parser
            if (relationshipParser != null) {
              final relationship = relationshipParser!.parse(tokens.sublist(i));
              
              // Add the relationship to the current element
              final currentContext = contextStack.current();
              if (currentContext.data.containsKey('currentElement')) {
                final element = currentContext.data['currentElement'] as ElementNode;
                if (relationship != null) {
                  // Handle relationship
                  // This would add the relationship to the element, but the exact method
                  // depends on the implementation of the ElementNode class
                }
              }
              
              // Skip the parsed tokens
              int toSkip = 3; // At minimum, skip source, arrow, and target
              if (i + toSkip < tokens.length && tokens[i + toSkip].type == TokenType.string) {
                toSkip++; // Skip description
              }
              if (i + toSkip < tokens.length && tokens[i + toSkip].type == TokenType.string) {
                toSkip++; // Skip technology
              }
              if (i + toSkip < tokens.length && tokens[i + toSkip].type == TokenType.leftBrace) {
                // Skip block
                int j = i + toSkip + 1;
                int braceCount = 1;
                while (j < tokens.length && braceCount > 0) {
                  if (tokens[j].type == TokenType.leftBrace) braceCount++;
                  if (tokens[j].type == TokenType.rightBrace) braceCount--;
                  j++;
                }
                toSkip = j - i;
              }
              i += toSkip;
            } else {
              // No relationship parser, just skip
              handleError("Relationship parser not available", tokens[i].position);
              i += 3; // Skip source, arrow, target at minimum
            }
          }
          else {
            i++; // Skip unknown identifier
          }
        } else {
          i++; // Skip other token types
        }
      }
    } catch (e) {
      handleError("Error parsing parent-child block: $e", tokens.isNotEmpty ? tokens[0].position : null);
    }
  }

  /// Helper method to handle errors consistently
  void handleError(String message, SourcePosition? position) {
    if (position != null) {
      errorReporter.reportStandardError(message, position.offset);
    } else {
      errorReporter.reportStandardError(message, 0);
    }
    
    // Throw exception with the error message
    throw ParseError(message, position);
  }
}

/// Exception thrown when a parsing error occurs
class ParseError implements Exception {
  final String message;
  final SourcePosition? position;
  
  ParseError(this.message, this.position);
  
  @override
  String toString() => 'ParseError: $message${position != null ? ' at $position' : ''}';
}