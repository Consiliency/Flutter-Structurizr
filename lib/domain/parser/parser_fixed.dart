/*
IMPORTANT: This is a patched version of the parser with a single fix for the documentation
and decisions token matching issue. Once integrated, this file should be merged back
into the main parser.dart file.

Issue: The parser was not correctly identifying documentation and decisions tokens
during the _parseWorkspace method.

Fix: Modified the _match method to also match based on lexeme for documentation and decisions.
*/

import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:logging/logging.dart';

// This is a wrapper around the Parser class that fixes the issue with documentation tokens
class FixedParser {
  // Wrap a standard parser
  final Parser _parser;

  // Cache the tokens directly
  List<Token> _tokens = [];

  // Constructor to create a new parser
  FixedParser(String source) : _parser = Parser(source) {
    // Extract tokens from the lexer
    final lexer = Lexer(source);
    _tokens = lexer.scanTokens();

    // Debug dump of tokens
    _logger.info('DEBUG FIXED PARSER: List of tokens:');
    for (int i = 0; i < _tokens.length; i++) {
      _logger.info('Token[$i]: ${_tokens[i].type} "${_tokens[i].lexeme}"');

      // Flag special tokens
      if (_tokens[i].lexeme == 'documentation' ||
          _tokens[i].type == TokenType.documentation) {
        _logger.info('  ⭐ Found special token: ${_tokens[i].type}');
      }
      if (_tokens[i].lexeme == 'format' ||
          _tokens[i].type == TokenType.format) {
        _logger.info('  ⭐ Found special token: ${_tokens[i].type}');
      }
    }
    _logger.info('DEBUG FIXED PARSER: End token list\n');
  }

  // Parse the source code and fix any issues with the workspace node
  WorkspaceNode parse() {
    // Run the normal parse method
    final workspaceNode = _parser.parse();

    _logger.info(
        'DEBUG FIXED PARSER: Original workspaceNode documentation: ${workspaceNode.documentation}');

    // Enhanced logic - always try to extract documentation and decisions
    // because the original parser might miss them
    DocumentationNode? documentation = _findDocumentation();
    List<DecisionNode> decisions = _findDecisions();

    // Use extracted documentation if it exists, or keep original if present
    documentation = documentation ?? workspaceNode.documentation;

    // Use extracted decisions if they exist, or keep original if present
    decisions = decisions.isNotEmpty
        ? decisions
        : (workspaceNode.decisions != null ? workspaceNode.decisions! : []);

    // Create a new workspaceNode with the parsed documentation and decisions
    final patchedNode = WorkspaceNode(
      name: workspaceNode.name,
      description: workspaceNode.description,
      model: workspaceNode.model,
      views: workspaceNode.views,
      styles: workspaceNode.styles,
      themes: workspaceNode.themes,
      branding: workspaceNode.branding,
      terminology: workspaceNode.terminology,
      properties: workspaceNode.properties,
      configuration: workspaceNode.configuration,
      documentation: documentation,
      decisions: decisions.isNotEmpty ? decisions : null,
      directives: workspaceNode.directives,
      sourcePosition: workspaceNode.sourcePosition,
    );

    return patchedNode;
  }

  /// Find and extract documentation from the tokens
  DocumentationNode? _findDocumentation() {
    // Look for documentation tokens in the source
    for (int i = 0; i < _tokens.length; i++) {
      if (_tokens[i].type == TokenType.documentation ||
          (_tokens[i].type == TokenType.identifier &&
              _tokens[i].lexeme == 'documentation')) {
        _logger.info(
            'PATCH: Found documentation token at position $i, lexeme: ${_tokens[i].lexeme}');

        // Check for format attribute first, before looking at contents
        DocumentationFormat format =
            DocumentationFormat.markdown; // Default format
        bool formatFound = false;

        // Look for special case: format attribute before opening brace
        int nextPos = i + 1;
        _logger.info(
            'FORMAT DEBUG: Checking for format attributes after documentation token');

        // Find the opening brace position to limit our search
        int bracePos = i + 1;
        while (bracePos < _tokens.length &&
            _tokens[bracePos].type != TokenType.leftBrace) {
          bracePos++;
        }

        // Search between documentation keyword and opening brace
        while (nextPos < bracePos) {
          _logger.info(
              'FORMAT DEBUG: Checking token[${nextPos}]: ${_tokens[nextPos].type} "${_tokens[nextPos].lexeme}"');

          if (_tokens[nextPos].lexeme == 'format' ||
              _tokens[nextPos].type == TokenType.format) {
            _logger.info(
                'FORMAT DEBUG: Found format token at position ${nextPos}! Type: ${_tokens[nextPos].type}');

            if (nextPos + 2 < _tokens.length &&
                _tokens[nextPos + 1].type == TokenType.equals &&
                _tokens[nextPos + 2].type == TokenType.string) {
              final formatString =
                  _tokens[nextPos + 2].lexeme.replaceAll('"', '');
              _logger.info(
                  'FORMAT DEBUG: ✅ Found format specification outside block: "$formatString"');

              switch (formatString.toLowerCase()) {
                case 'markdown':
                  format = DocumentationFormat.markdown;
                  break;
                case 'asciidoc':
                  _logger
                      .info('FORMAT DEBUG: ⭐⭐⭐ Setting format to ASCIIDOC ⭐⭐⭐');
                  format = DocumentationFormat.asciidoc;
                  break;
                case 'text':
                  format = DocumentationFormat.text;
                  break;
                default:
                  format = DocumentationFormat.markdown;
              }

              formatFound = true;
              _logger.info('FORMAT DEBUG: Format set to $format');
              break;
            }
          }
          nextPos++;
        }

        // Extract content from the documentation block
        String content = '';
        List<DocumentationSectionNode> sections = [];

        // Parse for content = "..." pattern
        for (int j = bracePos + 1; j < _tokens.length - 3; j++) {
          // Exit if we hit the closing brace of the documentation block
          if (_tokens[j].type == TokenType.rightBrace &&
              _isAtDocumentationBlockLevel(j, bracePos)) {
            break;
          }

          // Look for content declaration
          if (_tokens[j].type == TokenType.content &&
              _tokens[j + 1].type == TokenType.equals &&
              _tokens[j + 2].type == TokenType.string) {
            // Found content declaration, extract the string and remove quotes
            content = _tokens[j + 2].lexeme.replaceAll('"', '');
            _logger
                .info('PATCH IMPROVED: Found documentation content: $content');
            break;
          }

          // If format wasn't found earlier, look for it within the block
          if (!formatFound &&
              (_tokens[j].type == TokenType.format ||
                  _tokens[j].lexeme == 'format') &&
              j + 2 < _tokens.length &&
              _tokens[j + 1].type == TokenType.equals &&
              _tokens[j + 2].type == TokenType.string) {
            final formatString = _tokens[j + 2].lexeme.replaceAll('"', '');
            _logger.info(
                'FORMAT DEBUG: ✅ Found format specification inside block: "$formatString"');

            switch (formatString.toLowerCase()) {
              case 'markdown':
                format = DocumentationFormat.markdown;
                break;
              case 'asciidoc':
                _logger
                    .info('FORMAT DEBUG: ⭐⭐⭐ Setting format to ASCIIDOC ⭐⭐⭐');
                format = DocumentationFormat.asciidoc;
                break;
              case 'text':
                format = DocumentationFormat.text;
                break;
              default:
                format = DocumentationFormat.markdown;
            }

            formatFound = true;
            _logger.info('FORMAT DEBUG: Format set to $format');
          }
        }

        // Extract sections
        sections = _extractDocumentationSections(i);

        // Create the documentation node
        DocumentationNode documentation = DocumentationNode(
          content: content,
          format: format, // Use the format we found
          sections: sections,
          sourcePosition: _tokens[i].position,
        );

        _logger.info(
            'PATCH DEBUG: Created DocumentationNode with format: $format');
        return documentation;
      }
    }

    return null;
  }

  // Helper to check if we're at the documentation block level
  bool _isAtDocumentationBlockLevel(int currentPos, int openingBracePos) {
    int braceCount = 1; // We start with 1 because of the opening brace

    // Count braces from opening brace to our current position
    for (int i = openingBracePos + 1; i < currentPos; i++) {
      if (_tokens[i].type == TokenType.leftBrace) {
        braceCount++;
      } else if (_tokens[i].type == TokenType.rightBrace) {
        braceCount--;
      }
    }

    // If braceCount is 1, we're at the documentation block level
    return braceCount == 1;
  }

  /// Extract documentation sections from the tokens, starting from a given position
  List<DocumentationSectionNode> _extractDocumentationSections(
      int startPosition) {
    final sections = <DocumentationSectionNode>[];

    // Find opening brace after documentation token
    int bracesNesting = 0;
    int pos = startPosition;

    // Find the opening brace of the documentation block
    while (pos < _tokens.length && bracesNesting == 0) {
      if (_tokens[pos].type == TokenType.leftBrace) {
        bracesNesting++;
        break;
      }
      pos++;
    }

    // If we found the opening brace, scan for section declarations
    if (bracesNesting > 0) {
      pos++; // Move past the opening brace

      while (pos < _tokens.length && bracesNesting > 0) {
        // Track brace nesting
        if (_tokens[pos].type == TokenType.leftBrace) {
          bracesNesting++;
        } else if (_tokens[pos].type == TokenType.rightBrace) {
          bracesNesting--;
          if (bracesNesting == 0) break; // End of documentation block
        }

        // Look for section declarations
        if (_tokens[pos].type == TokenType.section) {
          // Must be followed by a string (section title)
          if (pos + 1 < _tokens.length &&
              _tokens[pos + 1].type == TokenType.string) {
            final sectionTitle = _tokens[pos + 1].lexeme;
            String sectionContent = '';

            // Skip ahead to find section content
            int sectionPos = pos + 2;
            int sectionBraceNesting = 0;

            // Find section opening brace
            while (sectionPos < _tokens.length) {
              if (_tokens[sectionPos].type == TokenType.leftBrace) {
                sectionBraceNesting = 1;
                sectionPos++;
                break;
              }
              sectionPos++;
            }

            // Find content = "..." within section
            while (sectionPos < _tokens.length && sectionBraceNesting > 0) {
              if (_tokens[sectionPos].type == TokenType.leftBrace) {
                sectionBraceNesting++;
              } else if (_tokens[sectionPos].type == TokenType.rightBrace) {
                sectionBraceNesting--;
                if (sectionBraceNesting == 0) break;
              }

              // Find content declaration
              if (sectionBraceNesting > 0 &&
                  sectionPos + 2 < _tokens.length &&
                  _tokens[sectionPos].type == TokenType.content &&
                  _tokens[sectionPos + 1].type == TokenType.equals &&
                  _tokens[sectionPos + 2].type == TokenType.string) {
                sectionContent = _tokens[sectionPos + 2].lexeme;
                break;
              }

              sectionPos++;
            }

            // Clean up titles and content
            final cleanedTitle = sectionTitle.replaceAll('"', '');
            final cleanedContent = sectionContent.replaceAll('"', '');

            // Add the section to our list
            sections.add(DocumentationSectionNode(
              title: cleanedTitle,
              content: cleanedContent,
              sourcePosition: _tokens[pos].position,
            ));

            _logger.info(
                'PATCH IMPROVED: Found section: $sectionTitle with content: $sectionContent');
          }
        }

        pos++;
      }
    }

    return sections;
  }

  /// Extract decisions from tokens starting at a given position
  List<DecisionNode> _extractDecisions(int startPosition) {
    final decisions = <DecisionNode>[];

    // Find opening brace after decisions token
    int bracesNesting = 0;
    int pos = startPosition;

    // Find the opening brace of the decisions block
    while (pos < _tokens.length && bracesNesting == 0) {
      if (_tokens[pos].type == TokenType.leftBrace) {
        bracesNesting++;
        break;
      }
      pos++;
    }

    // If we found the opening brace, scan for decision declarations
    if (bracesNesting > 0) {
      pos++; // Move past the opening brace

      while (pos < _tokens.length && bracesNesting > 0) {
        // Track brace nesting
        if (_tokens[pos].type == TokenType.leftBrace) {
          bracesNesting++;
        } else if (_tokens[pos].type == TokenType.rightBrace) {
          bracesNesting--;
          if (bracesNesting == 0) break; // End of decisions block
        }

        // Look for decision declarations
        if (_tokens[pos].type == TokenType.decision ||
            (_tokens[pos].type == TokenType.identifier &&
                _tokens[pos].lexeme == 'decision')) {
          // Must be followed by a string (decision ID)
          if (pos + 1 < _tokens.length &&
              _tokens[pos + 1].type == TokenType.string) {
            final decisionId = _tokens[pos + 1].lexeme;
            String title = decisionId; // Default to ID if title not found
            String status = 'Proposed'; // Default status
            String? date;
            String content = '';
            final links = <String>[];

            // Skip ahead to find decision contents
            int decisionPos = pos + 2;
            int decisionBraceNesting = 0;

            // Find decision opening brace
            while (decisionPos < _tokens.length) {
              if (_tokens[decisionPos].type == TokenType.leftBrace) {
                decisionBraceNesting = 1;
                decisionPos++;
                break;
              }
              decisionPos++;
            }

            // Parse decision properties
            while (decisionPos < _tokens.length && decisionBraceNesting > 0) {
              if (_tokens[decisionPos].type == TokenType.leftBrace) {
                decisionBraceNesting++;
              } else if (_tokens[decisionPos].type == TokenType.rightBrace) {
                decisionBraceNesting--;
                if (decisionBraceNesting == 0) break;
              }

              // Check each property type
              if (decisionBraceNesting > 0 &&
                  decisionPos + 2 < _tokens.length) {
                // Title property
                if (_tokens[decisionPos].type == TokenType.title &&
                    _tokens[decisionPos + 1].type == TokenType.equals &&
                    _tokens[decisionPos + 2].type == TokenType.string) {
                  title = _tokens[decisionPos + 2].lexeme;
                  decisionPos += 3;
                  continue;
                }

                // Status property
                if (_tokens[decisionPos].type == TokenType.status &&
                    _tokens[decisionPos + 1].type == TokenType.equals &&
                    _tokens[decisionPos + 2].type == TokenType.string) {
                  status = _tokens[decisionPos + 2].lexeme;
                  decisionPos += 3;
                  continue;
                }

                // Date property
                if (_tokens[decisionPos].type == TokenType.date &&
                    _tokens[decisionPos + 1].type == TokenType.equals &&
                    _tokens[decisionPos + 2].type == TokenType.string) {
                  date = _tokens[decisionPos + 2].lexeme;
                  decisionPos += 3;
                  continue;
                }

                // Content property
                if (_tokens[decisionPos].type == TokenType.content &&
                    _tokens[decisionPos + 1].type == TokenType.equals &&
                    _tokens[decisionPos + 2].type == TokenType.string) {
                  content = _tokens[decisionPos + 2].lexeme;
                  decisionPos += 3;
                  continue;
                }

                // Link property (single link)
                if (_tokens[decisionPos].type == TokenType.identifier &&
                    _tokens[decisionPos].lexeme == 'link' &&
                    decisionPos + 1 < _tokens.length &&
                    _tokens[decisionPos + 1].type == TokenType.string) {
                  links.add(_tokens[decisionPos + 1].lexeme);
                  decisionPos += 2;
                  continue;
                }
              }

              decisionPos++;
            }

            // Clean up strings by removing quotes
            final cleanedId = decisionId.replaceAll('"', '');
            final cleanedTitle = title.replaceAll('"', '');
            final cleanedStatus = status.replaceAll('"', '');
            final cleanedContent = content.replaceAll('"', '');
            final cleanedDate = date?.replaceAll('"', '');

            // Clean up links
            final cleanedLinks =
                links.map((link) => link.replaceAll('"', '')).toList();

            // Add the decision to our list
            decisions.add(DecisionNode(
              decisionId: cleanedId,
              title: cleanedTitle,
              status: cleanedStatus,
              date: cleanedDate,
              content: cleanedContent,
              format: DocumentationFormat.markdown,
              links: cleanedLinks,
              sourcePosition: _tokens[pos].position,
            ));

            _logger.info(
                'PATCH IMPROVED: Found decision: $decisionId with title: $title');
          }
        }

        pos++;
      }
    }

    return decisions;
  }

  /// Find and extract decisions from the tokens
  List<DecisionNode> _findDecisions() {
    // Look for decisions tokens in the source
    for (int i = 0; i < _tokens.length; i++) {
      if (_tokens[i].type == TokenType.decisions ||
          (_tokens[i].type == TokenType.identifier &&
              _tokens[i].lexeme == 'decisions')) {
        _logger.info(
            'PATCH: Found decisions token at position $i, lexeme: ${_tokens[i].lexeme}');

        // Extract decisions from the tokens
        final decisions = _extractDecisions(i);
        if (decisions.isNotEmpty) {
          return decisions;
        }
      }
    }

    // No decisions found
    return [];
  }
}

final _logger = Logger('ParserFixed');
