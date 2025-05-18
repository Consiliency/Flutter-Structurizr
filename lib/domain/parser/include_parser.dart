import 'dart:collection';

import 'context_stack.dart';
import 'error_reporter.dart';
import 'file_loader.dart';
import 'lexer/lexer.dart';
import 'lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/include_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/source_position.dart';

/// Parser for include directives in the Structurizr DSL.
class IncludeParser {
  /// The file loader for resolving file paths (optional).
  final FileLoader? fileLoader;

  /// The error reporter for reporting parsing errors.
  final ErrorReporter errorReporter;

  /// Creates a new include parser.
  IncludeParser({
    this.fileLoader,
    required this.errorReporter,
  });

  /// Parses include directives from the given tokens.
  ///
  /// Returns a list of include nodes. This handles both file includes
  /// (`!include file.dsl`) and view includes (`include *`).
  ///
  /// The method also resolves file includes recursively and checks for circular
  /// references.
  List<IncludeNode> parse(List<Token> tokens) {
    final includeNodes = <IncludeNode>[];
    final contextStack = ContextStack();

    // Push a context for the include parsing
    contextStack.push(Context('include_parsing'));

    try {
      for (int i = 0; i < tokens.length; i++) {
        final token = tokens[i];

        // Parse file includes
        if (token.type == TokenType.bang &&
            i + 1 < tokens.length &&
            tokens[i + 1].lexeme.toLowerCase() == 'include') {
          i += 1; // Skip the 'include' token

          // Extract the file path tokens (can span multiple tokens)
          final pathTokens = <Token>[];
          i += 1; // Move to the first token of the path

          // Collect tokens until end of line or end of input
          while (i < tokens.length) {
            final pathToken = tokens[i];
            if (pathToken.line != token.line) {
              i--; // Step back so the outer loop can process this token
              break;
            }
            pathTokens.add(pathToken);
            i++;
          }

          final includeNode = _parseFileInclude(pathTokens);
          includeNodes.add(includeNode);
        }

        // Parse view includes
        else if (token.type == TokenType.include && i + 1 < tokens.length) {
          // Extract the element pattern tokens
          final patternTokens = <Token>[];
          i += 1; // Move to the first token of the pattern

          // Collect tokens until end of line or end of input
          while (i < tokens.length) {
            final patternToken = tokens[i];
            if (patternToken.line != token.line ||
                patternToken.type == TokenType.leftBrace ||
                patternToken.type == TokenType.rightBrace) {
              i--; // Step back so the outer loop can process this token
              break;
            }
            patternTokens.add(patternToken);
            i++;
          }

          final includeNode = _parseViewInclude(patternTokens);
          includeNodes.add(includeNode);
        }
      }

      // Resolve recursive includes and check for circular references
      _resolveRecursive(includeNodes);
      _resolveCircular(includeNodes);

      return includeNodes;
    } catch (e) {
      errorReporter.reportStandardError(
        'Error parsing includes: $e',
        tokens.isNotEmpty ? tokens.first.position.offset : 0,
      );
      return includeNodes;
    } finally {
      // Pop the include parsing context
      contextStack.pop();
    }
  }

  /// Parses a file include directive.
  ///
  /// Returns an include node with type set to 'file'.
  IncludeNode _parseFileInclude(List<Token> tokens) {
    if (tokens.isEmpty) {
      errorReporter.reportStandardError(
        'Expected file path after !include directive',
        0,
      );
      return IncludeNode(
        path: '',
        isFileInclude: true,
        expression: '',
        sourcePosition: null,
      );
    }

    // Extract the file path from the tokens
    var stringBuilder = StringBuffer();
    SourcePosition? position;

    for (final token in tokens) {
      if (position == null) {
        position = token.position;
      }

      // If it's a string token, add the string value without quotes
      if (token.type == TokenType.string && token.value is String) {
        stringBuilder.write(token.value);
      } else {
        stringBuilder.write(token.lexeme);
      }
    }

    final filePath = stringBuilder.toString().trim();

    final includeNode = IncludeNode(
      path: filePath,
      isFileInclude: true,
      expression: filePath,
      sourcePosition: position,
    );

    return includeNode;
  }

  /// Parses a view include directive.
  ///
  /// Returns an include node with type set to 'view'.
  IncludeNode _parseViewInclude(List<Token> tokens) {
    if (tokens.isEmpty) {
      errorReporter.reportStandardError(
        'Expected element pattern after include directive',
        0,
      );
      return IncludeNode(
        path: '',
        isFileInclude: false,
        expression: '',
        sourcePosition: null,
      );
    }

    // Extract the element pattern from the tokens
    String pattern = '';
    SourcePosition? position;

    final firstToken = tokens.first;
    position = firstToken.position;

    if (firstToken.type == TokenType.star) {
      pattern = '*';
    } else if (firstToken.type == TokenType.string &&
        firstToken.value is String) {
      pattern = firstToken.value as String;
    } else {
      pattern = firstToken.lexeme;
    }

    final String patternStr = pattern.toString();
    final includeNode = IncludeNode(
      path: patternStr,
      isFileInclude: false,
      expression: patternStr,
      sourcePosition: position,
    );

    return includeNode;
  }

  /// Resolves file includes recursively.
  ///
  /// This method expands all file includes by loading the referenced files
  /// and parsing them for further includes.
  void _resolveRecursive(List<IncludeNode> includeNodes) {
    if (fileLoader == null) {
      return;
    }

    final processed = Set<String>();
    final pending = Queue<IncludeNode>.from(
        includeNodes.where((node) => node.isFileInclude));

    while (pending.isNotEmpty) {
      final includeNode = pending.removeFirst();
      final filePath = includeNode.expression;

      if (processed.contains(filePath)) {
        continue;
      }

      processed.add(filePath);

      // Load the file content
      final content = fileLoader!.loadFile(filePath);
      if (content == null) {
        errorReporter.reportStandardError(
          'Failed to load included file: $filePath',
          includeNode.sourcePosition?.offset ?? 0,
        );
        continue;
      }

      // Parse the file for further includes
      final lexer = Lexer(content);
      final tokens = lexer.scanTokens();
      final nestedIncludes = parse(tokens);

      // Add file includes to the pending queue for processing
      for (final nestedInclude in nestedIncludes) {
        if (nestedInclude.isFileInclude &&
            !processed.contains(nestedInclude.expression)) {
          pending.add(nestedInclude);
        }
      }

      // Add all nested includes to the result
      includeNodes.addAll(nestedIncludes.where((node) => !includeNodes.any(
          (existing) =>
              existing.expression == node.expression &&
              existing.type == node.type)));
    }
  }

  /// Detects circular references in file includes.
  ///
  /// This method checks for cycles in the include graph and reports errors
  /// if any circular references are detected.
  void _resolveCircular(List<IncludeNode> includeNodes) {
    if (fileLoader == null) {
      return;
    }

    // Build a directed graph of file includes
    final graph = <String, Set<String>>{};

    // Initialize graph nodes
    for (final node in includeNodes) {
      if (node.isFileInclude) {
        graph.putIfAbsent(node.expression, () => {});
      }
    }

    // Build edges based on include relationships
    for (final path in graph.keys) {
      final content = fileLoader!.loadFile(path);
      if (content == null) {
        continue;
      }

      final lexer = Lexer(content);
      final tokens = lexer.scanTokens();

      for (int i = 0; i < tokens.length - 1; i++) {
        if (tokens[i].type == TokenType.bang &&
            tokens[i + 1].lexeme.toLowerCase() == 'include' &&
            i + 2 < tokens.length) {
          // Extract the included file path
          String includedPath = '';
          final pathToken = tokens[i + 2];

          if (pathToken.type == TokenType.string && pathToken.value is String) {
            includedPath = pathToken.value as String;
          } else {
            includedPath = pathToken.lexeme;
          }

          // Add edge from current file to included file
          if (graph.containsKey(includedPath)) {
            graph[path]!.add(includedPath);
          }
        }
      }
    }

    // Detect cycles using DFS
    final visited = <String>{};
    final recursionStack = <String>{};

    void dfs(String node, List<String> stack) {
      if (recursionStack.contains(node)) {
        // Cycle detected
        final cycle = stack.sublist(stack.indexOf(node)) + [node];
        errorReporter.reportStandardError(
          'Circular include detected: ${cycle.join(' -> ')}',
          includeNodes
                  .firstWhere((n) => n.expression == node)
                  .sourcePosition
                  ?.offset ??
              0,
        );
        return;
      }

      if (visited.contains(node)) {
        return;
      }

      visited.add(node);
      recursionStack.add(node);
      stack.add(node);

      for (final neighbor in graph[node] ?? {}) {
        dfs(neighbor as String, stack);
      }

      recursionStack.remove(node);
      stack.removeLast();
    }

    // Run DFS from each unvisited node
    for (final node in graph.keys) {
      if (!visited.contains(node)) {
        dfs(node, []);
      }
    }
  }
}
