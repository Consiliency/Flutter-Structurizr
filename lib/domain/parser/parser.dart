import 'dart:io';
import 'package:path/path.dart' as path;
import 'error_reporter.dart';
import 'file_loader.dart';
import 'lexer/lexer.dart';
import 'lexer/token.dart';
import 'context_stack.dart';
import 'model_parser.dart';
import 'views_parser.dart';
import 'relationship_parser.dart';
import 'include_parser.dart';
import 'package:logging/logging.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/model_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/views_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/styles_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/theme_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/branding_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/terminology_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/properties_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/documentation/documentation_node.dart'
    as doc_nodes;
import 'package:flutter_structurizr/domain/parser/ast/nodes/person_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/software_system_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/relationship_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/deployment_environment_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/deployment_node_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/infrastructure_node_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/container_instance_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/nodes/directive_node.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_node.dart'
    show WorkspaceNode, TagsNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/container_node.dart'
    show ContainerNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/component_node.dart'
    show ComponentNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/tags_node.dart'
    show TagsNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/system_landscape_view_node.dart'
    show SystemLandscapeViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/system_context_view_node.dart'
    show SystemContextViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/container_view_node.dart'
    show ContainerViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/component_view_node.dart'
    show ComponentViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/dynamic_view_node.dart'
    show DynamicViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/deployment_view_node.dart'
    show DeploymentViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/filtered_view_node.dart'
    show FilteredViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/custom_view_node.dart'
    show CustomViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/image_view_node.dart'
    show ImageViewNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/include_node.dart'
    show IncludeNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/exclude_node.dart'
    show ExcludeNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/auto_layout_node.dart'
    show AutoLayoutNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/animation_node.dart'
    show AnimationNode;
import 'package:flutter_structurizr/domain/parser/ast/nodes/source_position.dart'
    show SourcePosition;

final logger = Logger('Parser');

/// Parser for the Structurizr DSL.
///
/// This recursive descent parser implements context-sensitive error recovery
/// and meaningful diagnostic messages to help users debug their DSL syntax.
class Parser {
  /// The lexer that provides tokens.
  final Lexer _lexer;

  /// The error reporter for reporting parsing errors.
  final ErrorReporter _errorReporter;

  /// The current token.
  Token _current;

  /// The previous token.
  Token? _previous;

  /// The tokens from the lexer.
  final List<Token> _tokens;

  /// The current position in the token list.
  int _position = 0;

  /// Variables defined in the DSL.
  final Map<String, Object> _variables = {};

  /// Stack of parsing contexts.
  final ContextStack _contextStack = ContextStack();

  /// Flag indicating whether the parser is in panic mode (error recovery).
  bool _panicMode = false;

  /// Count of errors encountered during parsing.
  int _errorCount = 0;

  /// Maximum number of errors to report before stopping.
  static const int _maxErrorCount = 25;

  /// The file loader for resolving include directives.
  FileLoader? _fileLoader;

  /// The list of directives encountered during parsing.
  final List<DirectiveNode> _directives = [];
  
  /// Hook functions for testing
  Function? _modelParserHook;
  Function? _viewsParserHook;
  Function? _relationshipParserHook;
  Function? _includeParserHook;
  
  /// Sets a hook function to be called when the model parser is used.
  void setModelParserHook(Function hook) {
    _modelParserHook = hook;
  }
  
  /// Sets a hook function to be called when the views parser is used.
  void setViewsParserHook(Function hook) {
    _viewsParserHook = hook;
  }
  
  /// Sets a hook function to be called when the relationship parser is used.
  void setRelationshipParserHook(Function hook) {
    _relationshipParserHook = hook;
  }
  
  /// Sets a hook function to be called when the include parser is used.
  void setIncludeParserHook(Function hook) {
    _includeParserHook = hook;
  }

  /// Creates a new parser for the given source code.
  Parser(String source, {String? filePath})
      : _lexer = Lexer(source),
        _errorReporter = ErrorReporter(source),
        _tokens = [],
        _current = Token(
          type: TokenType.error,
          lexeme: '',
          position: const SourcePosition(0, 0, 0),
        ) {
    // Initialize file loader if a file path is provided
    if (filePath != null) {
      final baseDir = path.dirname(filePath);
      _fileLoader = FileLoader(
        baseDirectory: baseDir,
        errorReporter: _errorReporter,
      );
    }

    _tokens.addAll(_lexer.scanTokens());
    if (_tokens.isNotEmpty) {
      _advance();
    }
  }

  /// Creates a new parser for a file at the given path.
  /// This factory handles loading the file and setting up the parser.
  static Parser fromFile(String filePath) {
    // Load the file content
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File not found: $filePath');
    }

    final source = file.readAsStringSync();
    return Parser(source, filePath: filePath);
  }

  /// Returns the error reporter for this parser.
  ErrorReporter get errorReporter => _errorReporter;

  /// Integrates content from included files and modules.
  ///
  /// This method processes any included files and builds or updates the
  /// model and views based on their content. It ensures that related elements
  /// from different files are properly connected.
  void integrateSubmodules() {
    // Skip if there are no directives
    if (_directives.isEmpty) {
      return;
    }
    
    // Call hook functions if they exist (for testing)
    if (_includeParserHook != null) {
      _includeParserHook!();
    }
    
    if (_modelParserHook != null) {
      _modelParserHook!();
    }
    
    if (_viewsParserHook != null) {
      _viewsParserHook!();
    }
    
    if (_relationshipParserHook != null) {
      _relationshipParserHook!();
    }

    // Create parsers for various parts of the model
    final modelParser = ModelParser(_errorReporter);
    final viewsParser = ViewsParser(_errorReporter);
    final relationshipParser =
        RelationshipParser(errorReporter: _errorReporter);
    final includeParser =
        IncludeParser(fileLoader: _fileLoader, errorReporter: _errorReporter);

    // Process each directive
    for (final directive in _directives) {
      // Only process include directives
      if (directive.type.toLowerCase() != 'include') {
        continue;
      }

      final includeValue = directive.value;

      // Try to load the included file
      if (_fileLoader == null) {
        _errorReporter.reportWarning(
          'Cannot process include directive: No file loader available',
          directive.sourcePosition?.offset ?? 0,
        );
        continue;
      }

      final content = _fileLoader!.loadFile(includeValue);
      if (content == null) {
        _errorReporter.reportStandardError(
          'Failed to load included file: $includeValue',
          directive.sourcePosition?.offset ?? 0,
        );
        continue;
      }

      // Create a lexer for the included content
      final includedLexer = Lexer(content);
      final tokens = includedLexer.scanTokens();

      try {
        // Process includes with the include parser
        final includes = includeParser.parse(tokens);

        // Process model elements with the model parser
        final modelNodes = modelParser.parse(tokens);

        // Process views with the views parser
        final viewNodes = viewsParser.parse(tokens);

        // Process relationships with the relationship parser
        final relationships = relationshipParser.parse(tokens);

        // TODO: Merge the results into the main workspace
        _errorReporter.reportInfo(
          'Included content from $includeValue: ' +
              '${modelNodes.people.length} people, ' +
              '${modelNodes.softwareSystems.length} software systems, ' +
              '${relationships.length} relationships',
          directive.sourcePosition?.offset ?? 0,
        );
      } catch (e) {
        _errorReporter.reportStandardError(
          'Error processing included file $includeValue: $e',
          directive.sourcePosition?.offset ?? 0,
        );
      }
    }
  }

  /// Reports a parser error but continues parsing in panic mode.
  void _error(String message) {
    if (_panicMode) return; // Avoid cascading errors

    _panicMode = true;
    _errorCount++;

    _errorReporter.reportStandardError(
      message,
      _current.position.offset,
    );

    if (_errorCount >= _maxErrorCount) {
      _errorReporter.reportFatalError(
        'Too many errors encountered (${_errorCount}). Stopping parse.',
        _current.position.offset,
      );
      throw Exception('Parse aborted due to excessive errors');
    }
    // Always try to recover after an error
    _synchronize();
    _panicMode = false;
  }

  /// Handles a parse error with context information.
  ///
  /// This method uses the current context stack to provide more detailed
  /// error reporting and recovery.
  void handleError(ParseError err) {
    // Get current context to provide more specific error information
    if (!_contextStack.isEmpty()) {
      final context = _contextStack.current();
      final contextName = context.name;

      // Add context information to the error message
      final contextualMessage = 'In ${contextName} context: ${err.message}';

      _errorReporter.reportStandardError(
        contextualMessage,
        err.position?.offset ?? _current.position.offset,
      );
    } else {
      // No context available, report the error directly
      _errorReporter.reportStandardError(
        err.message,
        err.position?.offset ?? _current.position.offset,
      );
    }

    _errorCount++;

    // Check for too many errors
    if (_errorCount >= _maxErrorCount) {
      _errorReporter.reportFatalError(
        'Too many errors encountered (${_errorCount}). Stopping parse.',
        _current.position.offset,
      );
      throw Exception('Parse aborted due to excessive errors');
    }

    // Try to recover from the error by synchronizing to a safe point
    _synchronize();
  }

  /// Parses the DSL and returns the resulting workspace AST node.
  ///
  /// This method attempts to parse the entire DSL source and build a workspace AST.
  /// If errors are encountered, it will attempt to recover and continue parsing
  /// to provide the most complete AST possible along with detailed error diagnostics.
  WorkspaceNode parse() {
    try {
      // Check if there were any lexical errors before we even start parsing
      if (_lexer.errorReporter.hasErrors) {
        _errorReporter.reportInfo(
          'Parsing will continue despite lexical errors',
          0,
        );
      }

      // Process any top-level directives (like !include) before parsing the workspace
      _processDirectives();

      // Fix token types for 'documentation' and 'decisions'
      // This ensures any identifiers with these lexemes are properly recognized
      for (int i = 0; i < _tokens.length; i++) {
        if (_tokens[i].type == TokenType.identifier) {
          if (_tokens[i].lexeme == 'documentation') {
            _tokens[i] = _tokens[i].copyWith(type: TokenType.documentation);
            logger.fine(
                'DEBUG: Fixed token type for documentation at position $i');
          } else if (_tokens[i].lexeme == 'decisions') {
            _tokens[i] = _tokens[i].copyWith(type: TokenType.decisions);
            logger.fine('DEBUG: Fixed token type for decisions at position $i');
          }
        }
      }

      // Check all the tokens to verify we have documentation and decisions
      logger.info('DEBUG: List of tokens from lexer:');
      for (int i = 0; i < _tokens.length && i < 100; i++) {
        logger.info('Token[$i]: ${_tokens[i].type} "${_tokens[i].lexeme}"');
        if (_tokens[i].type == TokenType.documentation ||
            _tokens[i].type == TokenType.decisions) {
          logger.info('  ⭐ Found special token: ${_tokens[i].type}');
        }
      }

      // Add another loop looking specifically for documentation and decisions
      bool hasDocToken = false;
      bool hasDecToken = false;
      for (final token in _tokens) {
        if (token.type == TokenType.documentation) hasDocToken = true;
        if (token.type == TokenType.decisions) hasDecToken = true;
      }
      logger.fine('DEBUG: Documentation token found: $hasDocToken');
      logger.fine('DEBUG: Decisions token found: $hasDecToken');
      logger.fine('DEBUG: End token list\n');

      // Parse the workspace
      final workspace = _parseWorkspace();

      // Store the directives in the workspace for use by downstream processing
      final workspaceWithDirectives = WorkspaceNode(
        name: workspace.name,
        description: workspace.description,
        model: workspace.model,
        views: workspace.views,
        styles: workspace.styles,
        themes: workspace.themes,
        branding: workspace.branding,
        terminology: workspace.terminology,
        properties: workspace.properties,
        configuration: workspace.configuration,
        sourcePosition: workspace.sourcePosition,
        directives: null,
      );

      // Integrate any included content from other files
      integrateSubmodules();

      // Report parse statistics
      if (_errorCount > 0) {
        _errorReporter.reportInfo(
          'Parsing completed with $_errorCount errors.\n' +
              'The resulting model may be incomplete or contain placeholders for erroneous content.',
          0,
        );
      }

      return workspaceWithDirectives;
    } catch (e) {
      // Only catch unexpected exceptions, not our controlled error handling
      _errorReporter.reportFatalError(
        'Fatal parsing error: $e',
        _current.position.offset,
      );

      // Return a minimal valid workspace that won't cause downstream errors
      return WorkspaceNode(
        name: 'Error',
        description:
            'Parsing failed with errors - this is a placeholder workspace',
        model: ModelNode(
          people: [],
          softwareSystems: [],
          relationships: [],
          sourcePosition: _current.position,
        ),
        sourcePosition: _current.position,
      );
    }
  }

  /// Processes directives at the beginning of the file before parsing the workspace.
  /// This includes handling !include directives to include additional files.
  void _processDirectives() {
    while (_check(TokenType.bang) && !_isAtEnd()) {
      final directiveToken = _current;
      _advance(); // Consume the bang (!)

      if (_check(TokenType.identifier)) {
        final directiveType = _current.lexeme;
        _advance(); // Consume the directive name

        if (directiveType.toLowerCase() == 'include') {
          _processIncludeDirective(directiveToken);
        } else {
          // Unknown directive type, just record it
          final directive = DirectiveNode(
            type: directiveType,
            value: _current.lexeme,
            sourcePosition: directiveToken.position,
          );
          _directives.add(directive);
          _advance(); // Skip the directive value
        }
      } else {
        _error('Expected directive name after !');
        _advance(); // Skip the token to recover
      }
    }
  }

  /// Processes an !include directive to include an external file.
  void _processIncludeDirective(Token directiveToken) {
    // If file loader is not available, just record the directive but don't process it
    if (_fileLoader == null) {
      _errorReporter.reportWarning(
        'File loader not available, !include directive ignored',
        directiveToken.position.offset,
      );

      // Skip to the next line
      while (!_check(TokenType.eof) &&
          _current.position.line == directiveToken.position.line) {
        _advance();
      }

      return;
    }

    // Parse the file path
    String filePath;
    if (_check(TokenType.string)) {
      filePath = _parseStringLiteral('Expected file path as string');
    } else {
      // Try to read the rest of the line as the file path
      final sb = StringBuffer();
      while (!_check(TokenType.eof) &&
          _current.position.line == directiveToken.position.line) {
        sb.write(_current.lexeme);
        _advance();
      }
      filePath = sb.toString().trim();

      if (filePath.isEmpty) {
        _errorReporter.reportStandardError(
          'Expected file path after !include directive',
          directiveToken.position.offset,
        );
        return;
      }
    }

    // Add the directive to the list of directives
    final directive = DirectiveNode(
      type: 'include',
      value: filePath,
      sourcePosition: directiveToken.position,
    );
    _directives.add(directive);

    // Try to load and parse the included file
    final includedContent = _fileLoader!.loadFile(filePath);
    if (includedContent != null) {
      // Create a new parser for the included content
      final includedPath = _fileLoader!.resolveFilePath(filePath);
      final includedParser = Parser(includedContent, filePath: includedPath);

      // Parse the included file and merge its directives with ours
      final includedWorkspace = includedParser.parse();
      if (includedWorkspace.directives != null) {
        // No merging of directives needed since types do not match
        _errorReporter.reportInfo(
          'Included content from $filePath: ' +
              '${includedWorkspace.model?.people.length} people, ' +
              '${includedWorkspace.model?.softwareSystems.length} software systems, ' +
              '${includedWorkspace.views?.systemLandscapeViews.length} system landscape views, ' +
              '${includedWorkspace.views?.systemContextViews.length} system context views, ' +
              '${includedWorkspace.views?.containerViews.length} container views, ' +
              '${includedWorkspace.views?.componentViews.length} component views, ' +
              '${includedWorkspace.views?.dynamicViews.length} dynamic views, ' +
              '${includedWorkspace.views?.deploymentViews.length} deployment views, ' +
              '${includedWorkspace.views?.filteredViews.length} filtered views, ' +
              '${includedWorkspace.views?.customViews.length} custom views, ' +
              '${includedWorkspace.views?.imageViews.length} image views',
          directiveToken.position.offset,
        );
      }

      // Report how many elements were included from the file
      final elementCount = _countElementsInWorkspace(includedWorkspace);
      _errorReporter.reportInfo(
        'Included $elementCount elements from file: $filePath',
        directiveToken.position.offset,
      );
    }
  }

  /// Counts the number of elements in a workspace for reporting purposes.
  int _countElementsInWorkspace(WorkspaceNode workspace) {
    int count = 0;

    // Count model elements
    if (workspace.model != null) {
      count += workspace.model!.people.length;

      for (final system in workspace.model!.softwareSystems) {
        count += 1; // Count the system itself
        count += system.containers.length;

        // Count all components in all containers
        for (final container in system.containers) {
          count += container.components.length;
        }
      }

      count += workspace.model!.deploymentEnvironments.length;

      // Count deployment nodes and their contents
      for (final env in workspace.model!.deploymentEnvironments) {
        count += _countDeploymentNodes(
            env.children.whereType<DeploymentNodeNode>().toList());
      }
    }

    return count;
  }

  /// Counts the number of deployment nodes recursively.
  int _countDeploymentNodes(List<DeploymentNodeNode> nodes) {
    int count = 0;

    for (final node in nodes) {
      count += 1; // Count the node itself
      // If node has children, count them recursively
      count += _countDeploymentNodes(
          node.children.whereType<DeploymentNodeNode>().toList());
        }

    return count;
  }

  /// Parses a workspace.
  WorkspaceNode _parseWorkspace() {
    logger.fine('DEBUG: Starting _parseWorkspace parsing');
    _pushContext(_ParsingContext.workspace);

    _consume(TokenType.workspace, "Expect 'workspace' keyword");

    // Handle optional extends directive
    String? extendsPath;
    if (_check(TokenType.extends_)) {
      _advance(); // consume 'extends'
      // The extends path can be either a string literal or an identifier-like path
      if (_check(TokenType.string)) {
        extendsPath = _parseStringLiteral('Expect extends path as string');
      } else if (_check(TokenType.identifier)) {
        extendsPath = _current.lexeme;
        _advance();
        // Handle paths with dots and slashes (like ../model.dsl)
        while (_check(TokenType.dot) || _check(TokenType.slash) || _check(TokenType.identifier)) {
          extendsPath = (extendsPath ?? '') + _current.lexeme;
          _advance();
        }
      } else {
        _errorReporter.reportStandardError(
          'Expected extends path after extends keyword',
          _current.position.offset,
        );
        print('ERROR: Expected extends path after extends keyword');
      }
      logger.fine('DEBUG: Parsed extends path: $extendsPath');
      print('DEBUG: Parsed extends path: $extendsPath');
    }

    // --- FIXED LOGIC: Only parse name/description if next token(s) are string ---
    String name = 'Workspace';
    String? description;
    if (_check(TokenType.string)) {
      name = _parseStringLiteral('Expect workspace name as string');
      if (_check(TokenType.string)) {
        description =
            _parseStringLiteral('Expect workspace description as string');
      }
    }
    logger.fine('DEBUG: Parsed workspace name: $name');
    if (description != null) {
      logger.fine('DEBUG: Parsed workspace description: $description');
    }

    _consume(TokenType.leftBrace, "Expect '{' after workspace declaration");

    ModelNode? model;
    ViewsNode? views;
    StylesNode? styles;
    final themes = <ThemeNode>[];
    BrandingNode? branding;
    TerminologyNode? terminology;
    PropertiesNode? properties;
    final configuration = <String, String>{};
    doc_nodes.DocumentationNode? documentation;
    List<doc_nodes.DecisionNode> decisions = [];

    // CRITICAL FIX: Scan ahead to find documentation and decisions tokens
    // This is a temporary fix to handle token matching issues
    for (int i = _position; i < _tokens.length; i++) {
      if (_tokens[i].type == TokenType.documentation) {
        logger.fine(
            'DEBUG: Found documentation token at position $i, lexeme: \\${_tokens[i].lexeme}');
        int savedPosition = _position;
        _position = i;
        _current = _tokens[_position];
        _advance(); // Consume the documentation token
        documentation = _parseDocumentation();
        logger.fine(
            'DEBUG: Parsed documentation content: \\${documentation.content}');
      } else if (_tokens[i].type == TokenType.decisions) {
        logger.fine(
            'DEBUG: Found decisions token at position $i, lexeme: \\${_tokens[i].lexeme}');
        int savedPosition = _position;
        _position = i;
        _current = _tokens[_position];
        _advance(); // Consume the decisions token
        decisions = _parseDecisions();
        logger.fine('DEBUG: Parsed decisions count: \\${decisions.length}');
      }
    }

    // Reset position for normal parsing
    // Find the position after workspace declaration and leftBrace
    int afterBrace = 0;
    for (int i = 0, found = 0; i < _tokens.length; i++) {
      if (_tokens[i].type == TokenType.leftBrace) {
        found++;
        if (found == 1) {
          // The first leftBrace after workspace
          afterBrace = i + 1;
          break;
        }
      }
    }
    _position = afterBrace;
    _current = _tokens[_position];

    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      logger.fine(
          'DEBUG: Current token before matching: \\${_current.type}, lexeme: \\${_current.lexeme}');
      if (_match(TokenType.model)) {
        model = _parseModel();
      } else if (_match(TokenType.views)) {
        print('DEBUG: Found views token, parsing views section');
        views = _parseViews();
      } else if (_match(TokenType.styles)) {
        styles = _parseStyles();
      } else if (_match(TokenType.themes)) {
        themes.addAll(_parseThemes());
      } else if (_match(TokenType.branding)) {
        branding = _parseBranding();
      } else if (_match(TokenType.documentation)) {
        logger.fine(
            'DEBUG: Found documentation token! Parsing documentation block...');
        documentation = _parseDocumentation();
        logger.fine(
            'DEBUG: Finished parsing documentation block: \\${documentation != null}');
      } else if (_current.type == TokenType.documentation) {
        logger.fine(
            'DEBUG: Direct match for documentation token! Parsing documentation block...');
        _advance();
        documentation = _parseDocumentation();
        logger.fine(
            'DEBUG: Finished parsing documentation block: \\${documentation != null}');
      } else if (_match(TokenType.decisions)) {
        logger.fine('DEBUG: Found decisions token! Parsing decisions block...');
        decisions.addAll(_parseDecisions());
        logger.fine(
            'DEBUG: Finished parsing decisions block, count: \\${decisions.length}');
      } else if (_current.type == TokenType.decisions) {
        logger.fine(
            'DEBUG: Direct match for decisions token! Parsing decisions block...');
        _advance();
        decisions.addAll(_parseDecisions());
        logger.fine(
            'DEBUG: Finished parsing decisions block, count: \\${decisions.length}');
      } else if (_match(TokenType.identifier) &&
          _current.lexeme == 'terminology') {
        terminology = _parseTerminology();
      } else if (_match(TokenType.identifier) &&
          _current.lexeme == 'properties') {
        properties = _parseProperties();
      } else if (_match(TokenType.identifier) &&
          _current.lexeme == 'configuration') {
        configuration.addAll(_parseConfiguration());
      } else {
        _errorReporter.reportStandardError(
          'Unexpected token in workspace: \\${_current.lexeme}',
          _current.position.offset,
        );
        _advance();
      }
    }

    _consume(TokenType.rightBrace, "Expect '}' after workspace definition");

    _popContext();

    logger.fine(
        'DEBUG: Creating WorkspaceNode with documentation: \\${documentation != null}');
    logger.fine(
        'DEBUG: Creating WorkspaceNode with decisions count: \\${decisions.length}');
    if (documentation != null) {
      logger.fine(
          'DEBUG: Documentation content is: "\\${documentation.content}"');
    }
    if (documentation == null) {
      logger.warning('ALERT: No documentation node found during parsing!');
      for (int i = 0; i < _tokens.length; i++) {
        if (_tokens[i].type == TokenType.documentation) {
          logger.info(
              'DEBUG: Found documentation token at position $i but it wasn\'t parsed correctly!');
        }
      }
    }
    final workspaceNode = WorkspaceNode(
      name: name,
      description: description,
      model: model,
      views: views,
      styles: styles,
      themes: themes,
      branding: branding,
      terminology: terminology,
      properties: properties?.properties,
      configuration: configuration,
      documentation: documentation,
      decisions: decisions,
      sourcePosition: _current.position,
    );
    logger.fine(
        'DEBUG: FINAL CHECK - WorkspaceNode has documentation: \\${workspaceNode.documentation != null}');
    if (workspaceNode.documentation != null) {
      logger.fine(
          'DEBUG: FINAL CHECK - Documentation content: "\\${workspaceNode.documentation!.content}"');
    }
    if (model != null) {
      logger.fine('DEBUG: [Parser] ModelNode relationships (model-level):');
      for (final rel in model.relationships) {
        logger.fine(
            '  - source: \\${rel.sourceId}, dest: \\${rel.destinationId}, desc: \\${rel.description}');
      }
      logger.fine('DEBUG: [Parser] ModelNode relationships (element-level):');
      for (final person in model.people) {
        for (final rel in person.relationships) {
          logger.fine(
              '  - source: \\${rel.sourceId}, dest: \\${rel.destinationId}, desc: \\${rel.description}');
        }
      }
      for (final system in model.softwareSystems) {
        for (final rel in system.relationships) {
          logger.fine(
              '  - source: \\${rel.sourceId}, dest: \\${rel.destinationId}, desc: \\${rel.description}');
        }
      }
    }
    return workspaceNode;
  }

  /// Parses a documentation section.
  doc_nodes.DocumentationNode _parseDocumentation() {
    logger.fine('DEBUG: **** ENTERED _parseDocumentation method ****');
    _pushContext(_ParsingContext.documentation);
    final sourcePosition = _current.position;

    // Parse optional format
    doc_nodes.DocumentationFormat format =
        doc_nodes.DocumentationFormat.markdown;
    try {
      if (_match(TokenType.format)) {
        _consume(TokenType.equals, "Expect '=' after format keyword");
        final formatString =
            _parseStringLiteral('Expect format as string literal');
        switch (formatString.toLowerCase()) {
          case 'markdown':
            format = doc_nodes.DocumentationFormat.markdown;
            break;
          case 'asciidoc':
            format = doc_nodes.DocumentationFormat.asciidoc;
            break;
          case 'text':
            format = doc_nodes.DocumentationFormat.text;
            break;
          default:
            _errorReporter.reportWarning(
              'Unknown documentation format: $formatString. Using markdown as default.',
              _current.position.offset,
            );
            format = doc_nodes.DocumentationFormat.markdown;
        }
      }
    } catch (e) {
      _errorReporter.reportStandardError(
        'Error parsing documentation format: $e. Defaulting to markdown.',
        _current.position.offset,
      );
      // Synchronize to recover
      _synchronize();
    }

    // Parse the opening brace with enhanced error recovery
    try {
      _consume(
          TokenType.leftBrace, "Expect '{' after documentation declaration");
    } catch (e) {
      _errorReporter.reportStandardError(
        'Error parsing documentation block: $e. Attempting to recover.',
        _current.position.offset,
      );

      // If we can't find a left brace, look ahead for content or section
      // which would indicate we're in a documentation block
      int lookAhead = 0;
      while (_position + lookAhead < _tokens.length && lookAhead < 5) {
        final token = _tokens[_position + lookAhead];
        if (token.type == TokenType.content ||
            token.type == TokenType.section) {
          _errorReporter.reportInfo(
            'Found documentation content without opening brace, continuing parsing',
            token.position.offset,
          );
          // Skip to that token
          while (_position < _tokens.length &&
              _current.type != TokenType.content &&
              _current.type != TokenType.section) {
            _advance();
          }
          break;
        }
        lookAhead++;
      }

      // If we couldn't recover with look-ahead, use synchronize
      if (lookAhead >= 5 || _position + lookAhead >= _tokens.length) {
        _synchronize();
      }
    }

    String? content;
    final sections = <doc_nodes.DocumentationSectionNode>[];

    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      try {
        if (_match(TokenType.content)) {
          try {
            _consume(TokenType.equals, "Expect '=' after content keyword");
            content = _parseStringLiteral('Expect content as string literal');
          } catch (e) {
            _errorReporter.reportStandardError(
              'Error parsing documentation content: $e',
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_match(TokenType.section)) {
          try {
            sections.add(_parseDocumentationSection());
          } catch (e) {
            _errorReporter.reportStandardError(
              'Error parsing documentation section: $e',
              _current.position.offset,
            );
            _synchronize();
          }
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in documentation: ${_current.lexeme}',
            _current.position.offset,
          );
          _synchronize(); // Use synchronize instead of just advance
        }
      } catch (e) {
        _errorReporter.reportStandardError(
          'Error in documentation block: $e, attempting to recover',
          _current.position.offset,
        );
        _synchronize();
      }
    }

    if (content == null && sections.isEmpty) {
      _errorReporter.reportWarning(
        'Documentation has no content or sections',
        sourcePosition.offset,
      );
      content = ''; // Default to empty content
    }

    try {
      _consume(
          TokenType.rightBrace, "Expect '}' after documentation definition");
    } catch (e) {
      _errorReporter.reportStandardError(
        'Missing closing brace for documentation block, attempting to recover',
        _current.position.offset,
      );
      // Try to recover by synchronizing
      _synchronize();
    }

    _popContext();

    final docNode = doc_nodes.DocumentationNode(
      content: content ?? '',
      format: format,
      sections: sections,
      sourcePosition: sourcePosition,
    );

    logger.fine(
        'DEBUG: Created DocumentationNode with content: "${docNode.content}"');
    logger.fine(
        'DEBUG: Created DocumentationNode with ${docNode.sections.length} sections');

    return docNode;
  }

  /// Parses a documentation section.
  doc_nodes.DocumentationSectionNode _parseDocumentationSection() {
    final sourcePosition = _current.position;

    // Parse section title
    final title = _parseStringLiteral('Expect section title as string');

    // Parse optional format (defaults to parent documentation format)
    doc_nodes.DocumentationFormat format =
        doc_nodes.DocumentationFormat.markdown;
    if (_match(TokenType.format)) {
      _consume(TokenType.equals, "Expect '=' after format keyword");
      final formatString =
          _parseStringLiteral('Expect format as string literal');
      switch (formatString.toLowerCase()) {
        case 'markdown':
          format = doc_nodes.DocumentationFormat.markdown;
          break;
        case 'asciidoc':
          format = doc_nodes.DocumentationFormat.asciidoc;
          break;
        case 'text':
          format = doc_nodes.DocumentationFormat.text;
          break;
        default:
          _errorReporter.reportWarning(
            'Unknown section format: $formatString. Using markdown as default.',
            _current.position.offset,
          );
      }
    }

    _consume(TokenType.leftBrace, "Expect '{' after section declaration");

    String content = '';

    if (_match(TokenType.content)) {
      _consume(TokenType.equals, "Expect '=' after content keyword");
      content = _parseStringLiteral('Expect content as string literal');
    } else {
      _errorReporter.reportWarning(
        'Section has no content',
        sourcePosition.offset,
      );
    }

    _consume(TokenType.rightBrace, "Expect '}' after section definition");

    return doc_nodes.DocumentationSectionNode(
      title: title,
      content: content,
      format: format,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses architecture decisions.
  List<doc_nodes.DecisionNode> _parseDecisions() {
    logger.fine('DEBUG: **** ENTERED _parseDecisions method ****');
    _pushContext(_ParsingContext.decisions);
    final decisions = <doc_nodes.DecisionNode>[];

    try {
      _consume(TokenType.leftBrace, "Expect '{' after decisions declaration");
    } catch (e) {
      _errorReporter.reportStandardError(
        'Error parsing decisions block: $e. Attempting to recover.',
        _current.position.offset,
      );

      // If we can't find a left brace, look ahead for decision token
      // which would indicate we're in a decisions block
      int lookAhead = 0;
      while (_position + lookAhead < _tokens.length && lookAhead < 5) {
        final token = _tokens[_position + lookAhead];
        if (token.type == TokenType.decision ||
            (token.type == TokenType.identifier &&
                token.lexeme == 'decision')) {
          _errorReporter.reportInfo(
            'Found decision token without opening brace, continuing parsing',
            token.position.offset,
          );
          // Skip to that token
          while (_position < _tokens.length &&
              _current.type != TokenType.decision &&
              !(_current.type == TokenType.identifier &&
                  _current.lexeme == 'decision')) {
            _advance();
          }
          break;
        }
        lookAhead++;
      }

      // If we couldn't recover with look-ahead, use synchronize
      if (lookAhead >= 5 || _position + lookAhead >= _tokens.length) {
        _synchronize();
      }
    }

    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      try {
        if (_match(TokenType.decision)) {
          decisions.add(_parseDecision());
        } else if (_current.type == TokenType.identifier &&
            _current.lexeme == 'decision') {
          // Handle case where "decision" is parsed as an identifier
          _errorReporter.reportInfo(
            "Found 'decision' as identifier instead of keyword, treating as decision token",
            _current.position.offset,
          );
          _advance(); // Consume the identifier
          decisions.add(_parseDecision());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in decisions block: ${_current.lexeme}',
            _current.position.offset,
          );
          _synchronize(); // Use _synchronize for recovery
        }
      } catch (e) {
        _errorReporter.reportStandardError(
          'Exception in decisions block: $e',
          _current.position.offset,
        );
        _synchronize();
      }
    }

    try {
      _consume(TokenType.rightBrace, "Expect '}' after decisions definition");
    } catch (e) {
      _errorReporter.reportStandardError(
        'Missing closing brace for decisions block, attempting to recover',
        _current.position.offset,
      );
      // Try to recover by synchronizing
      _synchronize();
    }

    _popContext();

    logger.fine('DEBUG: Successfully parsed ${decisions.length} decisions');

    return decisions;
  }

  /// Parses an architecture decision record with enhanced error recovery.
  doc_nodes.DecisionNode _parseDecision() {
    _pushContext(_ParsingContext.decision);
    final sourcePosition = _current.position;

    // Parse decision ID
    final decisionId = _parseStringLiteral('Expect decision ID as string');

    try {
      _consume(TokenType.leftBrace, "Expect '{' after decision declaration");
    } catch (e) {
      _errorReporter.reportStandardError(
        'Error parsing decision record: $e. Attempting to recover.',
        _current.position.offset,
      );

      // Look ahead for common decision properties
      int lookAhead = 0;
      while (_position + lookAhead < _tokens.length && lookAhead < 5) {
        final token = _tokens[_position + lookAhead];
        if (token.type == TokenType.title ||
            token.type == TokenType.status ||
            token.type == TokenType.date ||
            token.type == TokenType.content) {
          _errorReporter.reportInfo(
            'Found decision property without opening brace, continuing parsing',
            token.position.offset,
          );
          // Skip to that token
          while (_position < _tokens.length &&
              _current.type != TokenType.title &&
              _current.type != TokenType.status &&
              _current.type != TokenType.date &&
              _current.type != TokenType.content) {
            _advance();
          }
          break;
        }
        lookAhead++;
      }

      // If we couldn't recover with look-ahead, use synchronize
      if (lookAhead >= 5 || _position + lookAhead >= _tokens.length) {
        _synchronize();
      }
    }

    String? title;
    String? date;
    String status = 'Proposed'; // Default status
    String content = '';
    doc_nodes.DocumentationFormat format =
        doc_nodes.DocumentationFormat.markdown;
    final links = <String>[];

    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      try {
        if (_match(TokenType.title)) {
          try {
            _consume(TokenType.equals, "Expect '=' after title keyword");
            title = _parseStringLiteral('Expect title as string literal');
          } catch (e) {
            _errorReporter.reportStandardError(
              'Error parsing decision title: $e',
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_match(TokenType.date)) {
          try {
            _consume(TokenType.equals, "Expect '=' after date keyword");
            date = _parseStringLiteral('Expect date as string literal');
          } catch (e) {
            _errorReporter.reportStandardError(
              'Error parsing decision date: $e',
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_match(TokenType.status)) {
          try {
            _consume(TokenType.equals, "Expect '=' after status keyword");
            status = _parseStringLiteral('Expect status as string literal');
          } catch (e) {
            _errorReporter.reportStandardError(
              'Error parsing decision status: $e',
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_match(TokenType.format)) {
          try {
            _consume(TokenType.equals, "Expect '=' after format keyword");
            final formatString =
                _parseStringLiteral('Expect format as string literal');
            switch (formatString.toLowerCase()) {
              case 'markdown':
                format = doc_nodes.DocumentationFormat.markdown;
                break;
              case 'asciidoc':
                format = doc_nodes.DocumentationFormat.asciidoc;
                break;
              case 'text':
                format = doc_nodes.DocumentationFormat.text;
                break;
              default:
                _errorReporter.reportWarning(
                  'Unknown decision format: $formatString. Using markdown as default.',
                  _current.position.offset,
                );
            }
          } catch (e) {
            _errorReporter.reportStandardError(
              'Error parsing decision format: $e',
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_match(TokenType.content)) {
          try {
            _consume(TokenType.equals, "Expect '=' after content keyword");
            content = _parseStringLiteral('Expect content as string literal');
          } catch (e) {
            _errorReporter.reportStandardError(
              'Error parsing decision content: $e',
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_match(TokenType.identifier) && _current.lexeme == 'links') {
          try {
            links.addAll(_parseLinks());
          } catch (e) {
            _errorReporter.reportStandardError(
              'Error parsing decision links: $e',
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_match(TokenType.identifier) && _current.lexeme == 'link') {
          // Handle single link
          try {
            links.add(_parseStringLiteral('Expect link target as string'));
          } catch (e) {
            _errorReporter.reportStandardError(
              'Error parsing decision link: $e',
              _current.position.offset,
            );
            _synchronize();
          }
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in decision: ${_current.lexeme}',
            _current.position.offset,
          );
          _synchronize(); // Use synchronize instead of just advance
        }
      } catch (e) {
        _errorReporter.reportStandardError(
          'Error in decision block: $e, attempting to recover',
          _current.position.offset,
        );
        _synchronize();
      }
    }

    if (title == null) {
      _errorReporter.reportWarning(
        'Decision has no title, using ID as title',
        sourcePosition.offset,
      );
      title = decisionId;
    }

    try {
      _consume(TokenType.rightBrace, "Expect '}' after decision definition");
    } catch (e) {
      _errorReporter.reportStandardError(
        'Missing closing brace for decision, attempting to recover',
        _current.position.offset,
      );
      _synchronize();
    }

    _popContext(); // Pop decision context

    return doc_nodes.DecisionNode(
      decisionId: decisionId,
      title: title,
      date: date,
      status: status,
      content: content,
      format: format,
      links: links,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a list of links to other decisions.
  List<String> _parseLinks() {
    final links = <String>[];

    _consume(TokenType.leftBrace, "Expect '{' after links declaration");

    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      links.add(_parseStringLiteral('Expect link as string'));
    }

    _consume(TokenType.rightBrace, "Expect '}' after links definition");

    return links;
  }

  /// Parses a model section.
  ModelNode _parseModel() {
    _pushContext(_ParsingContext.model);
    _consume(TokenType.leftBrace, "Expect '{' after model declaration");
    final people = <PersonNode>[];
    final softwareSystems = <SoftwareSystemNode>[];
    final relationships = <RelationshipNode>[];
    final deploymentEnvironments = <DeploymentEnvironmentNode>[];
    String? enterpriseName;
    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      try {
        print('DEBUG: [Parser] Parsing model token: ${_current.type} "${_current.lexeme}"');
        if (_check(TokenType.identifier) ||
            _check(TokenType.string) ||
            _isKeyword(_current.type)) {
          // Variable definition or element declaration
          final startToken = _current;
          if (_peekNext().type == TokenType.equals) {
            // Variable definition
            final varName = _parseVariableName('Expect variable name');
            _consume(TokenType.equals, "Expect '=' after variable name");
            if (_match(TokenType.person)) {
              final person = _parsePerson(varName);
              people.add(person);
              _variables[varName] = person;
            } else if (_match(TokenType.softwareSystem)) {
              final system = _parseSoftwareSystem(varName);
              softwareSystems.add(system);
              _variables[varName] = system;
            } else {
              _errorReporter.reportStandardError(
                'Unsupported variable assignment in model: \\${_current.lexeme}',
                _current.position.offset,
              );
              _synchronize();
            }
          } else if (_check(TokenType.identifier) &&
              _peekNext().type == TokenType.arrow) {
            // Implicit relationship at model level
            relationships.add(_parseImplicitRelationship());
          } else if (_match(TokenType.arrow)) {
            // Implicit relationship (should not reach here, handled above)
            _errorReporter.reportStandardError(
              'Unexpected arrow token in model block',
              startToken.position.offset,
            );
            _synchronize();
          } else {
            _errorReporter.reportStandardError(
              'Unexpected token in model: \\${_current.lexeme}',
              _current.position.offset,
            );
            _advance();
          }
        } else if (_match(TokenType.person)) {
          people.add(_parsePerson(null));
        } else if (_match(TokenType.softwareSystem)) {
          softwareSystems.add(_parseSoftwareSystem(null));
        } else if (_match(TokenType.relationship)) {
          relationships.add(_parseRelationship());
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'enterprise') {
          // Parse enterprise name
          enterpriseName =
              _parseStringLiteral('Expect enterprise name as string');
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in model: \\${_current.lexeme}',
            _current.position.offset,
          );
          _synchronize();
        }
      } catch (e) {
        _errorReporter.reportStandardError(
          'Exception in model block: $e',
          _current.position.offset,
        );
        _synchronize();
      }
    }
    _consume(TokenType.rightBrace, "Expect '}' after model definition");
    _popContext();
    return ModelNode(
      people: people,
      softwareSystems: softwareSystems,
      deploymentEnvironments: deploymentEnvironments,
      relationships: relationships,
      sourcePosition: _current.position,
    );
  }

  /// Parses a person element.
  PersonNode _parsePerson(String? id) {
    final sourcePosition = _current.position;

    String name = _parseStringLiteral('Expect person name as string');
    String? description;
    String? location;

    if (_check(TokenType.string)) {
      description = _parseStringLiteral('Expect person description as string');
    }

    TagsNode? tags;
    PropertiesNode? properties;
    final relationships = <RelationshipNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'location') {
          location = _parseStringLiteral('Expect location as string');
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in person: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after person definition");
      _popContext();
    }

    final personId = id ?? name.replaceAll(' ', '');

    return PersonNode(
      id: personId,
      name: name,
      description: description,
      location: location,
      tags: tags?.tags ?? [],
      properties: properties?.properties ?? {},
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a software system element.
  SoftwareSystemNode _parseSoftwareSystem(String? id) {
    final sourcePosition = _current.position;
    // Debug print for ID assignment
    logger.fine('DEBUG: [_parseSoftwareSystem] incoming id: '
        '\u001b[36m$id\u001b[0m');
    String name = _parseStringLiteral('Expect software system name as string');
    String? description;
    String? location;

    if (_check(TokenType.string)) {
      description =
          _parseStringLiteral('Expect software system description as string');
    }

    TagsNode? tags;
    PropertiesNode? properties;
    final relationships = <RelationshipNode>[];
    final containers = <ContainerNode>[];
    final deploymentEnvironments = <DeploymentEnvironmentNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'location') {
          location = _parseStringLiteral('Expect location as string');
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.equals) {
          // Variable definition
          final varName = _parseIdentifierOrString('Expect variable name');
          _consume(TokenType.equals, "Expect '=' after variable name");

          if (_match(TokenType.container)) {
            final container =
                _parseContainer(varName, id ?? name.replaceAll(' ', ''));
            containers.add(container);
            _variables[varName] = container;
          } else {
            _errorReporter.reportStandardError(
              'Unsupported variable assignment in software system: ${_current.lexeme}',
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else if (_match(TokenType.container)) {
          containers.add(_parseContainer(null, id ?? name.replaceAll(' ', '')));
        } else if (_match(TokenType.deploymentEnvironment)) {
          deploymentEnvironments.add(_parseDeploymentEnvironment(
              null, id ?? name.replaceAll(' ', '')));
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in software system: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(
          TokenType.rightBrace, "Expect '}' after software system definition");
      _popContext();
    }

    final systemId = id ?? name.replaceAll(' ', '');
    logger.fine('DEBUG: [_parseSoftwareSystem] assigned systemId: '
        '\u001b[33m$systemId\u001b[0m');
    return SoftwareSystemNode(
      id: systemId,
      name: name,
      description: description,
      location: location,
      tags: tags?.tags ?? [],
      properties: properties?.properties ?? {},
      containers: containers,
      deploymentEnvironments: deploymentEnvironments,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a container element.
  ContainerNode _parseContainer(String? id, String parentId) {
    final sourcePosition = _current.position;

    String name = _parseStringLiteral('Expect container name as string');
    String? description;
    String? technology;

    if (_check(TokenType.string)) {
      description =
          _parseStringLiteral('Expect container description as string');

      if (_check(TokenType.string)) {
        technology =
            _parseStringLiteral('Expect container technology as string');
      }
    }

    TagsNode? tags;
    PropertiesNode? properties;
    final relationships = <RelationshipNode>[];
    final components = <ComponentNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.equals) {
          // Variable definition
          final varName = _parseIdentifierOrString('Expect variable name');
          _consume(TokenType.equals, "Expect '=' after variable name");

          if (_match(TokenType.component)) {
            final component =
                _parseComponent(varName, id ?? name.replaceAll(' ', ''));
            components.add(component);
            _variables[varName] = component;
          } else {
            _errorReporter.reportStandardError(
              'Unsupported variable assignment in container: ${_current.lexeme}',
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else if (_match(TokenType.component)) {
          components.add(_parseComponent(null, id ?? name.replaceAll(' ', '')));
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in container: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after container definition");
      _popContext();
    }

    final containerId = id ?? name.replaceAll(' ', '');

    return ContainerNode(
      id: containerId,
      name: name,
      description: description,
      technology: technology,
      tags: tags?.tags ?? [],
      properties: properties?.properties ?? {},
      components: components,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a component element.
  ComponentNode _parseComponent(String? id, String parentId) {
    final sourcePosition = _current.position;

    String name = _parseStringLiteral('Expect component name as string');
    String? description;
    String? technology;

    if (_check(TokenType.string)) {
      description =
          _parseStringLiteral('Expect component description as string');

      if (_check(TokenType.string)) {
        technology =
            _parseStringLiteral('Expect component technology as string');
      }
    }

    TagsNode? tags;
    PropertiesNode? properties;
    final relationships = <RelationshipNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in component: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after component definition");
      _popContext();
    }

    final componentId = id ?? name.replaceAll(' ', '');

    return ComponentNode(
      id: componentId,
      name: name,
      description: description,
      technology: technology,
      tags: tags?.tags ?? [],
      properties: properties?.properties ?? {},
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a deployment environment.
  DeploymentEnvironmentNode _parseDeploymentEnvironment(
      String? id, String parentId) {
    final sourcePosition = _current.position;

    String name =
        _parseStringLiteral('Expect deployment environment name as string');
    String? description;

    if (_check(TokenType.string)) {
      description = _parseStringLiteral(
          'Expect deployment environment description as string');
    }

    TagsNode? tags;
    PropertiesNode? properties;
    final relationships = <RelationshipNode>[];
    final deploymentNodes = <DeploymentNodeNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.equals) {
          // Variable definition
          final varName = _parseIdentifierOrString('Expect variable name');
          _consume(TokenType.equals, "Expect '=' after variable name");

          if (_match(TokenType.deploymentNode)) {
            final node =
                _parseDeploymentNode(varName, id ?? name.replaceAll(' ', ''));
            deploymentNodes.add(node);
            _variables[varName] = node;
          } else {
            _errorReporter.reportStandardError(
              'Unsupported variable assignment in deployment environment: ${_current.lexeme}',
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else if (_match(TokenType.deploymentNode)) {
          deploymentNodes
              .add(_parseDeploymentNode(null, id ?? name.replaceAll(' ', '')));
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in deployment environment: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace,
          "Expect '}' after deployment environment definition");
      _popContext();
    }

    final envId = id ?? name.replaceAll(' ', '');

    return DeploymentEnvironmentNode(
      id: envId,
      name: name,
      group: null, // or actual group if parsed
      children: deploymentNodes,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a deployment node.
  DeploymentNodeNode _parseDeploymentNode(String? id, String parentId) {
    final sourcePosition = _current.position;

    String name = _parseStringLiteral('Expect deployment node name as string');
    String? description;
    String? technology;

    if (_check(TokenType.string)) {
      description =
          _parseStringLiteral('Expect deployment node description as string');

      if (_check(TokenType.string)) {
        technology =
            _parseStringLiteral('Expect deployment node technology as string');
      }
    }

    TagsNode? tags;
    PropertiesNode? properties;
    final relationships = <RelationshipNode>[];
    final children = <DeploymentNodeNode>[];
    final infrastructureNodes = <InfrastructureNodeNode>[];
    final containerInstances = <ContainerInstanceNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.equals) {
          // Variable definition
          final varName = _parseIdentifierOrString('Expect variable name');
          _consume(TokenType.equals, "Expect '=' after variable name");

          if (_match(TokenType.deploymentNode)) {
            final node =
                _parseDeploymentNode(varName, id ?? name.replaceAll(' ', ''));
            children.add(node);
            _variables[varName] = node;
          } else if (_match(TokenType.infrastructureNode)) {
            final node = _parseInfrastructureNode(
                varName, id ?? name.replaceAll(' ', ''));
            infrastructureNodes.add(node);
            _variables[varName] = node;
          } else if (_match(TokenType.identifier) &&
              _current.lexeme == 'containerInstance') {
            final instance = _parseContainerInstance(
                varName, id ?? name.replaceAll(' ', ''));
            containerInstances.add(instance);
            _variables[varName] = instance;
          } else {
            _errorReporter.reportStandardError(
              'Unsupported variable assignment in deployment node: ${_current.lexeme}',
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else if (_match(TokenType.deploymentNode)) {
          children
              .add(_parseDeploymentNode(null, id ?? name.replaceAll(' ', '')));
        } else if (_match(TokenType.infrastructureNode)) {
          infrastructureNodes.add(
              _parseInfrastructureNode(null, id ?? name.replaceAll(' ', '')));
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'containerInstance') {
          containerInstances.add(
              _parseContainerInstance(null, id ?? name.replaceAll(' ', '')));
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in deployment node: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(
          TokenType.rightBrace, "Expect '}' after deployment node definition");
      _popContext();
    }

    final nodeId = id ?? name.replaceAll(' ', '');

    return DeploymentNodeNode(
      id: nodeId,
      name: name,
      description: description,
      technology: technology,
      tags: tags?.tags ?? [],
      properties: properties?.properties ?? {},
      children: children,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses an infrastructure node.
  InfrastructureNodeNode _parseInfrastructureNode(String? id, String parentId) {
    final sourcePosition = _current.position;

    String name =
        _parseStringLiteral('Expect infrastructure node name as string');
    String? description;
    String? technology;

    if (_check(TokenType.string)) {
      description = _parseStringLiteral(
          'Expect infrastructure node description as string');

      if (_check(TokenType.string)) {
        technology = _parseStringLiteral(
            'Expect infrastructure node technology as string');
      }
    }

    TagsNode? tags;
    PropertiesNode? properties;
    final relationships = <RelationshipNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in infrastructure node: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace,
          "Expect '}' after infrastructure node definition");
      _popContext();
    }

    final nodeId = id ?? name.replaceAll(' ', '');

    return InfrastructureNodeNode(
      id: nodeId,
      name: name,
      description: description,
      technology: technology,
      tags: tags?.tags ?? [],
      properties: properties?.properties ?? {},
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a container instance.
  ContainerInstanceNode _parseContainerInstance(String? id, String parentId) {
    final sourcePosition = _current.position;

    String containerId = _parseIdentifierOrString(
        'Expect container reference as string or identifier');
    int instanceCount = 1;

    if (_check(TokenType.integer)) {
      instanceCount = int.parse(_current.lexeme);
      _advance();
    }

    TagsNode? tags;
    PropertiesNode? properties;
    final relationships = <RelationshipNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in container instance: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace,
          "Expect '}' after container instance definition");
      _popContext();
    }

    final instanceId = id ?? '${containerId}Instance';

    return ContainerInstanceNode(
      id: instanceId,
      identifier: containerId,
      tags: tags?.tags ?? [],
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a tags declaration.
  TagsNode _parseTags() {
    final sourcePosition = _current.position;
    final tagsList = <String>[];

    if (_check(TokenType.string)) {
      tagsList.add(_parseStringLiteral('Expect tag as string'));

      while (_match(TokenType.comma)) {
        tagsList.add(_parseStringLiteral('Expect tag as string'));
      }
    }

    // Join tags with commas
    final tags = tagsList.join(', ');

    return TagsNode(
      tags: tagsList,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a properties declaration.
  PropertiesNode _parseProperties() {
    final sourcePosition = _current.position;
    final properties = <String, String>{};

    if (_match(TokenType.leftBrace)) {
      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        final propName = _parseIdentifierOrString('Expect property name');
        String propValue = '';
        if (_match(TokenType.equals)) {
          propValue = _parseStringLiteral('Expect property value as string');
        }
        properties[propName] = propValue;
      }
      _consume(TokenType.rightBrace, "Expect '}' after properties definition");
    }
    return PropertiesNode(
      properties: properties,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a relationship declaration.
  RelationshipNode _parseRelationship() {
    final sourcePosition = _current.position;

    _advance(); // Consume 'relationship' keyword

    final sourceId =
        _parseIdentifierOrString('Expect source element identifier');
    _consume(TokenType.arrow, "Expect '->' between source and destination");
    final destinationId =
        _parseIdentifierOrString('Expect destination element identifier');

    String? description;
    String? technology;

    if (_check(TokenType.string)) {
      description =
          _parseStringLiteral('Expect relationship description as string');

      if (_check(TokenType.string)) {
        technology =
            _parseStringLiteral('Expect relationship technology as string');
      }
    }

    TagsNode? tags;
    PropertiesNode? properties;

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in relationship: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(
          TokenType.rightBrace, "Expect '}' after relationship definition");
      _popContext();
    }

    return RelationshipNode(
      sourceId: sourceId,
      destinationId: destinationId,
      description: description,
      technology: technology,
      tags: tags?.tags ?? [],
      properties: properties?.properties ?? {},
      sourcePosition: sourcePosition,
    );
  }

  /// Parses an implicit relationship (source -> destination).
  RelationshipNode _parseImplicitRelationship() {
    final sourcePosition = _current.position;
    print('DEBUG: [Parser] Parsing implicit relationship');

    final sourceId =
        _parseIdentifierOrString('Expect source element identifier');
    print('DEBUG: [Parser] Relationship source: $sourceId');
    _consume(TokenType.arrow, "Expect '->' between source and destination");
    final destinationId =
        _parseIdentifierOrString('Expect destination element identifier');
    print('DEBUG: [Parser] Relationship destination: $destinationId');

    String? description;
    String? technology;

    if (_check(TokenType.string)) {
      description =
          _parseStringLiteral('Expect relationship description as string');

      if (_check(TokenType.string)) {
        technology =
            _parseStringLiteral('Expect relationship technology as string');
      }
    }

    TagsNode? tags;
    PropertiesNode? properties;

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) &&
            _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in relationship: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(
          TokenType.rightBrace, "Expect '}' after relationship definition");
      _popContext();
    }

    return RelationshipNode(
      sourceId: sourceId,
      destinationId: destinationId,
      description: description,
      technology: technology,
      tags: tags?.tags ?? [],
      properties: properties?.properties ?? {},
      sourcePosition: sourcePosition,
    );
  }

  /// Parses the views section.
  ViewsNode _parseViews() {
    final sourcePosition = _current.position;
    logger.fine('DEBUG: ENTERED _parseViews');
    print('DEBUG: ENTERED _parseViews method');
    _pushContext(_ParsingContext.views);
    _consume(TokenType.leftBrace, "Expect '{' after views declaration");
    final systemLandscapeViews = <SystemLandscapeViewNode>[];
    final systemContextViews = <SystemContextViewNode>[];
    final containerViews = <ContainerViewNode>[];
    final componentViews = <ComponentViewNode>[];
    final dynamicViews = <DynamicViewNode>[];
    final deploymentViews = <DeploymentViewNode>[];
    final filteredViews = <FilteredViewNode>[];
    final customViews = <CustomViewNode>[];
    final imageViews = <ImageViewNode>[];
    final configuration = <String, String>{};
    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      if (_match(TokenType.systemLandscape)) {
        systemLandscapeViews.add(_parseSystemLandscapeView());
      } else if (_match(TokenType.systemContext)) {
        print('DEBUG: Found systemContext token, parsing system context view');
        systemContextViews.add(_parseSystemContextView());
      } else if (_match(TokenType.containerView)) {
        containerViews.add(_parseContainerView());
      } else if (_match(TokenType.componentView)) {
        componentViews.add(_parseComponentView());
      } else if (_match(TokenType.dynamicView)) {
        dynamicViews.add(_parseDynamicView());
      } else if (_match(TokenType.deploymentView)) {
        deploymentViews.add(_parseDeploymentView());
      } else if (_match(TokenType.filteredView)) {
        filteredViews.add(_parseFilteredView());
      } else if (_match(TokenType.customView)) {
        customViews.add(_parseCustomView());
      } else if (_match(TokenType.imageView)) {
        imageViews.add(_parseImageView());
      } else if (_match(TokenType.identifier) &&
          _current.lexeme == 'configuration') {
        configuration.addAll(_parseConfiguration());
      } else {
        print('DEBUG: Unexpected token in views: ${_current.lexeme}, type: ${_current.type}');
        _errorReporter.reportStandardError(
          'Unexpected token in views: \\${_current.lexeme}',
          _current.position.offset,
        );
        _advance();
      }
    }
    _consume(TokenType.rightBrace, "Expect '}' after views definition");
    _popContext();
    logger.fine('DEBUG: _parseViews done. Counts:');
    logger.fine('  SystemLandscapeViews: \\${systemLandscapeViews.length}');
    logger.fine('  SystemContextViews: \\${systemContextViews.length}');
    logger.fine('  ContainerViews: \\${containerViews.length}');
    logger.fine('  ComponentViews: \\${componentViews.length}');
    logger.fine('  DynamicViews: \\${dynamicViews.length}');
    logger.fine('  DeploymentViews: \\${deploymentViews.length}');
    logger.fine('  FilteredViews: \\${filteredViews.length}');
    logger.fine('  CustomViews: \\${customViews.length}');
    logger.fine('  ImageViews: \\${imageViews.length}');
    if (systemContextViews.isNotEmpty) {
      for (final v in systemContextViews) {
        logger
            .fine('    SystemContextView: key=\\${v.key}, title=\\${v.title}');
      }
    }
    if (containerViews.isNotEmpty) {
      for (final v in containerViews) {
        logger.fine('    ContainerView: key=\\${v.key}, title=\\${v.title}');
      }
    }
    // ...repeat for other view types as needed
    return ViewsNode(
      systemLandscapeViews: systemLandscapeViews,
      systemContextViews: systemContextViews,
      containerViews: containerViews,
      componentViews: componentViews,
      dynamicViews: dynamicViews,
      deploymentViews: deploymentViews,
      filteredViews: filteredViews,
      customViews: customViews,
      imageViews: imageViews,
      configuration: configuration,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a system landscape view.
  SystemLandscapeViewNode _parseSystemLandscapeView() {
    // Implementation similar to other view types
    final sourcePosition = _current.position;

    String key = _parseStringLiteral('Expect view key as string');
    String? title;
    String? description;

    if (_check(TokenType.string)) {
      title = _parseStringLiteral('Expect view title as string');

      if (_check(TokenType.string)) {
        description = _parseStringLiteral('Expect view description as string');
      }
    }

    final includes = <IncludeNode>[];
    final excludes = <ExcludeNode>[];
    AutoLayoutNode? autoLayout;
    final animations = <AnimationNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.view);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.include)) {
          includes.add(_parseInclude());
        } else if (_match(TokenType.exclude)) {
          excludes.add(_parseExclude());
        } else if (_match(TokenType.autoLayout)) {
          autoLayout = _parseAutoLayout();
        } else if (_match(TokenType.animation)) {
          animations.add(_parseAnimation());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in system landscape view: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after view definition");
      _popContext();
    }

    return SystemLandscapeViewNode(
      key: key,
      title: title,
      description: description,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a system context view.
  SystemContextViewNode _parseSystemContextView() {
    final sourcePosition = _current.position;

    // Parse required system identifier
    String systemId = _parseIdentifierOrString('Expect system identifier');

    // Parse optional key and description, matching Java logic
    String key = '';
    String? title;
    String? description;

    if (_check(TokenType.string)) {
      key = _parseStringLiteral('Expect view key as string');
      if (_check(TokenType.string)) {
        title = _parseStringLiteral('Expect view title as string');
        if (_check(TokenType.string)) {
          description =
              _parseStringLiteral('Expect view description as string');
        }
      }
    } else {
      // If key is omitted, generate a default (Java does this via workspace.getViews().generateViewKey)
      key = 'systemContext-' + systemId;
    }

    // TODO: Validate that systemId exists and is a software system (as in Java)
    // This should be done in the mapping step if not possible here.

    final includes = <IncludeNode>[];
    final excludes = <ExcludeNode>[];
    AutoLayoutNode? autoLayout;
    final animations = <AnimationNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.view);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        print('DEBUG: [Parser] Parsing system context view body token: ${_current.type} "${_current.lexeme}"');
        if (_match(TokenType.include)) {
          print('DEBUG: [Parser] Found include token, parsing include directive');
          final includeNode = _parseInclude();
          print('DEBUG: [Parser] Parsed include: "${includeNode.path}"');
          includes.add(includeNode);
        } else if (_match(TokenType.exclude)) {
          excludes.add(_parseExclude());
        } else if (_match(TokenType.autoLayout)) {
          autoLayout = _parseAutoLayout();
        } else if (_match(TokenType.animation)) {
          animations.add(_parseAnimation());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in system context view: \\${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after view definition");
      _popContext();
    }

    print('DEBUG: [Parser] Creating SystemContextViewNode with ${includes.length} includes and ${excludes.length} excludes');
    for (final include in includes) {
      print('DEBUG: [Parser] Include: "${include.path}"');
    }

    return SystemContextViewNode(
      key: key,
      systemId: systemId,
      title: title,
      description: description,
      autoLayout: autoLayout,
      animations: animations,
      includes: includes,
      excludes: excludes,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a container view.
  ContainerViewNode _parseContainerView() {
    final sourcePosition = _current.position;

    String systemId = _parseIdentifierOrString('Expect system identifier');
    String key = _parseStringLiteral('Expect view key as string');
    String? title;
    String? description;

    if (_check(TokenType.string)) {
      title = _parseStringLiteral('Expect view title as string');

      if (_check(TokenType.string)) {
        description = _parseStringLiteral('Expect view description as string');
      }
    }

    final includes = <IncludeNode>[];
    final excludes = <ExcludeNode>[];
    AutoLayoutNode? autoLayout;
    final animations = <AnimationNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.view);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.include)) {
          includes.add(_parseInclude());
        } else if (_match(TokenType.exclude)) {
          excludes.add(_parseExclude());
        } else if (_match(TokenType.autoLayout)) {
          autoLayout = _parseAutoLayout();
        } else if (_match(TokenType.animation)) {
          animations.add(_parseAnimation());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in container view: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after view definition");
      _popContext();
    }

    return ContainerViewNode(
      key: key,
      systemId: systemId,
      title: title,
      description: description,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a component view.
  ComponentViewNode _parseComponentView() {
    final sourcePosition = _current.position;

    String containerId =
        _parseIdentifierOrString('Expect container identifier');
    String key = _parseStringLiteral('Expect view key as string');
    String? title;
    String? description;

    if (_check(TokenType.string)) {
      title = _parseStringLiteral('Expect view title as string');

      if (_check(TokenType.string)) {
        description = _parseStringLiteral('Expect view description as string');
      }
    }

    final includes = <IncludeNode>[];
    final excludes = <ExcludeNode>[];
    AutoLayoutNode? autoLayout;
    final animations = <AnimationNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.view);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.include)) {
          includes.add(_parseInclude());
        } else if (_match(TokenType.exclude)) {
          excludes.add(_parseExclude());
        } else if (_match(TokenType.autoLayout)) {
          autoLayout = _parseAutoLayout();
        } else if (_match(TokenType.animation)) {
          animations.add(_parseAnimation());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in component view: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after view definition");
      _popContext();
    }

    return ComponentViewNode(
      key: key,
      containerId: containerId,
      title: title,
      description: description,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a dynamic view.
  DynamicViewNode _parseDynamicView() {
    final sourcePosition = _current.position;

    String? scope;

    if (!_check(TokenType.string)) {
      scope = _parseIdentifierOrString('Expect optional scope identifier');
    }

    String key = _parseStringLiteral('Expect view key as string');
    String? title;
    String? description;

    if (_check(TokenType.string)) {
      title = _parseStringLiteral('Expect view title as string');

      if (_check(TokenType.string)) {
        description = _parseStringLiteral('Expect view description as string');
      }
    }

    final includes = <IncludeNode>[];
    final excludes = <ExcludeNode>[];
    AutoLayoutNode? autoLayout;
    final animations = <AnimationNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.view);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.include)) {
          includes.add(_parseInclude());
        } else if (_match(TokenType.exclude)) {
          excludes.add(_parseExclude());
        } else if (_match(TokenType.autoLayout)) {
          autoLayout = _parseAutoLayout();
        } else if (_match(TokenType.animation)) {
          animations.add(_parseAnimation());
        } else if (_check(TokenType.identifier) &&
            _peekNext().type == TokenType.arrow) {
          // This is a relationship step in a dynamic view
          // For simplicity, we'll just add it as an animation step
          _parseImplicitRelationship();
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in dynamic view: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after view definition");
      _popContext();
    }

    return DynamicViewNode(
      key: key,
      description: description,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a deployment view.
  DeploymentViewNode _parseDeploymentView() {
    final sourcePosition = _current.position;

    String systemId = _parseIdentifierOrString('Expect system identifier');
    String environment =
        _parseStringLiteral('Expect environment name as string');
    String key = _parseStringLiteral('Expect view key as string');
    String? title;
    String? description;

    if (_check(TokenType.string)) {
      title = _parseStringLiteral('Expect view title as string');

      if (_check(TokenType.string)) {
        description = _parseStringLiteral('Expect view description as string');
      }
    }

    final includes = <IncludeNode>[];
    final excludes = <ExcludeNode>[];
    AutoLayoutNode? autoLayout;
    final animations = <AnimationNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.view);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.include)) {
          includes.add(_parseInclude());
        } else if (_match(TokenType.exclude)) {
          excludes.add(_parseExclude());
        } else if (_match(TokenType.autoLayout)) {
          autoLayout = _parseAutoLayout();
        } else if (_match(TokenType.animation)) {
          animations.add(_parseAnimation());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in deployment view: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after view definition");
      _popContext();
    }

    return DeploymentViewNode(
      key: key,
      environment: environment,
      title: title,
      description: description,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a filtered view.
  FilteredViewNode _parseFilteredView() {
    final sourcePosition = _current.position;

    String baseViewKey = _parseIdentifierOrString('Expect base view key');
    String key = _parseStringLiteral('Expect view key as string');
    String? title;
    String? description;

    if (_check(TokenType.string)) {
      title = _parseStringLiteral('Expect view title as string');

      if (_check(TokenType.string)) {
        description = _parseStringLiteral('Expect view description as string');
      }
    }

    final includes = <IncludeNode>[];
    final excludes = <ExcludeNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.view);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.include)) {
          includes.add(_parseInclude());
        } else if (_match(TokenType.exclude)) {
          excludes.add(_parseExclude());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in filtered view: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after view definition");
      _popContext();
    }

    return FilteredViewNode(
      key: key,
      baseViewKey: baseViewKey,
      mode: 'include',
      description: description,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a custom view.
  CustomViewNode _parseCustomView() {
    final sourcePosition = _current.position;

    String key = _parseStringLiteral('Expect view key as string');
    String? title;
    String? description;

    if (_check(TokenType.string)) {
      title = _parseStringLiteral('Expect view title as string');

      if (_check(TokenType.string)) {
        description = _parseStringLiteral('Expect view description as string');
      }
    }

    final includes = <IncludeNode>[];
    final excludes = <ExcludeNode>[];
    AutoLayoutNode? autoLayout;
    final animations = <AnimationNode>[];

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.view);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.include)) {
          includes.add(_parseInclude());
        } else if (_match(TokenType.exclude)) {
          excludes.add(_parseExclude());
        } else if (_match(TokenType.autoLayout)) {
          autoLayout = _parseAutoLayout();
        } else if (_match(TokenType.animation)) {
          animations.add(_parseAnimation());
        } else {
          _errorReporter.reportStandardError(
            'Unexpected token in custom view: ${_current.lexeme}',
            _current.position.offset,
          );
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after view definition");
      _popContext();
    }

    return CustomViewNode(
      key: key,
      title: title,
      description: description,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses an image view.
  ImageViewNode _parseImageView() {
    final sourcePosition = _current.position;

    String imageType = _parseIdentifierOrString('Expect image type');
    String key = _parseStringLiteral('Expect view key as string');
    String? title;
    String? description;
    String content = '';

    if (_check(TokenType.string)) {
      title = _parseStringLiteral('Expect view title as string');

      if (_check(TokenType.string)) {
        description = _parseStringLiteral('Expect view description as string');
      }
    }

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.view);

      // For simplicity, just consume everything until the closing brace
      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_check(TokenType.string)) {
          content = _parseStringLiteral('Expect image content as string');
        } else {
          content += _current.lexeme;
          _advance();
        }
      }

      _consume(TokenType.rightBrace, "Expect '}' after view definition");
      _popContext();
    }

    return ImageViewNode(
      key: key,
      imagePath: imageType,
      description: description,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses an include statement.
  IncludeNode _parseInclude() {
    final sourcePosition = _current.position;

    String expression;
    if (_check(TokenType.star)) {
      // Handle the "*" token specifically for include all
      expression = _current.lexeme;
      _advance();
    } else {
      // Handle identifier or string expressions
      expression = _parseIdentifierOrString('Expect include expression');
    }

    return IncludeNode(
      path: expression,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses an exclude statement.
  ExcludeNode _parseExclude() {
    final sourcePosition = _current.position;

    String expression = _parseIdentifierOrString('Expect exclude expression');

    return ExcludeNode(
      pattern: expression,
      sourcePosition: sourcePosition,
    );
  }

  /// Parses an auto layout statement.
  AutoLayoutNode _parseAutoLayout() {
    final sourcePosition = _current.position;

    String? rankDirection;
    int? rankSeparation;
    int? nodeSeparation;

    if (_check(TokenType.string)) {
      rankDirection = _parseStringLiteral('Expect rank direction as string');
    }

    if (_check(TokenType.integer)) {
      rankSeparation = int.parse(_current.lexeme);
      _advance();
    }

    if (_check(TokenType.integer)) {
      nodeSeparation = int.parse(_current.lexeme);
      _advance();
    }

    return AutoLayoutNode(
      sourcePosition: sourcePosition,
    );
  }

  /// Parses an animation step.
  AnimationNode _parseAnimation() {
    final sourcePosition = _current.position;

    int order = 1;

    if (_check(TokenType.integer)) {
      order = int.parse(_current.lexeme);
      _advance();
    }

    final elements = <String>[];
    final relationships = <String>[];

    if (_match(TokenType.leftBrace)) {
      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        // Parse elements and relationships
        _advance();
      }

      _consume(
          TokenType.rightBrace, "Expect '}' after animation step definition");
    }

    return AnimationNode(
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a styles section.
  StylesNode _parseStyles() {
    final sourcePosition = _current.position;

    _pushContext(_ParsingContext.styles);

    _consume(TokenType.leftBrace, "Expect '{' after styles declaration");

    final elementStyles = <ElementStyleNode>[];
    final relationshipStyles = <RelationshipStyleNode>[];

    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      if (_match(TokenType.identifier) && _current.lexeme == 'element') {
        elementStyles.add(_parseElementStyle());
      } else if (_match(TokenType.identifier) &&
          _current.lexeme == 'relationship') {
        relationshipStyles.add(_parseRelationshipStyle());
      } else {
        _errorReporter.reportStandardError(
          'Unexpected token in styles: ${_current.lexeme}',
          _current.position.offset,
        );
        _advance();
      }
    }

    _consume(TokenType.rightBrace, "Expect '}' after styles definition");

    _popContext();

    return StylesNode(
      sourcePosition: sourcePosition,
    );
  }

  /// Parses an element style.
  ElementStyleNode _parseElementStyle() {
    final sourcePosition = _current.position;

    String tag = _parseStringLiteral('Expect element tag as string');

    String? shape;
    String? icon;
    int? width;
    int? height;
    String? background;
    String? stroke;
    String? color;
    int? fontSize;
    String? border;
    double? opacity;
    final metadata = <String, String>{};

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.style);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        final property = _parseIdentifierOrString('Expect style property name');

        if (property == 'shape') {
          shape = _parseStringLiteral('Expect shape value as string');
        } else if (property == 'icon') {
          icon = _parseStringLiteral('Expect icon value as string');
        } else if (property == 'width') {
          width = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'height') {
          height = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'background') {
          background = _parseStringLiteral('Expect background color as string');
        } else if (property == 'stroke') {
          stroke = _parseStringLiteral('Expect stroke color as string');
        } else if (property == 'color') {
          color = _parseStringLiteral('Expect text color as string');
        } else if (property == 'fontSize') {
          fontSize = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'border') {
          border = _parseStringLiteral('Expect border style as string');
        } else if (property == 'opacity') {
          opacity = double.parse(_current.lexeme);
          _advance();
        } else {
          // Custom metadata property
          final value = _parseStringLiteral('Expect property value as string');
          metadata[property] = value;
        }
      }

      _consume(
          TokenType.rightBrace, "Expect '}' after element style definition");
      _popContext();
    }

    return ElementStyleNode(
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a relationship style.
  RelationshipStyleNode _parseRelationshipStyle() {
    final sourcePosition = _current.position;

    String tag = _parseStringLiteral('Expect relationship tag as string');

    int? thickness;
    String? color;
    String? style;
    String? routing;
    int? fontSize;
    int? width;
    String? position;
    double? opacity;
    final metadata = <String, String>{};

    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.style);

      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        final property = _parseIdentifierOrString('Expect style property name');

        if (property == 'thickness') {
          thickness = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'color') {
          color = _parseStringLiteral('Expect color value as string');
        } else if (property == 'style') {
          style = _parseStringLiteral('Expect style value as string');
        } else if (property == 'routing') {
          routing = _parseStringLiteral('Expect routing value as string');
        } else if (property == 'fontSize') {
          fontSize = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'width') {
          width = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'position') {
          position = _parseStringLiteral('Expect position value as string');
        } else if (property == 'opacity') {
          opacity = double.parse(_current.lexeme);
          _advance();
        } else {
          // Custom metadata property
          final value = _parseStringLiteral('Expect property value as string');
          metadata[property] = value;
        }
      }

      _consume(TokenType.rightBrace,
          "Expect '}' after relationship style definition");
      _popContext();
    }

    return RelationshipStyleNode(
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a list of themes.
  List<ThemeNode> _parseThemes() {
    final themes = <ThemeNode>[];

    if (_check(TokenType.string)) {
      _parseStringLiteral(
          'Expect theme URL as string'); // Parse and discard, or store if needed elsewhere
      themes.add(ThemeNode(
        sourcePosition: _current.position,
      ));

      while (_check(TokenType.comma)) {
        _advance(); // Consume comma
        _parseStringLiteral('Expect theme URL as string'); // Parse and discard
        themes.add(ThemeNode(
          sourcePosition: _current.position,
        ));
      }
    }

    return themes;
  }

  /// Parses a branding section.
  BrandingNode _parseBranding() {
    final sourcePosition = _current.position;

    _pushContext(_ParsingContext.branding);

    _consume(TokenType.leftBrace, "Expect '{' after branding declaration");

    String? logo;
    int? width;
    int? height;
    String? font;

    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      final property =
          _parseIdentifierOrString('Expect branding property name');

      if (property == 'logo') {
        logo = _parseStringLiteral('Expect logo URL as string');
      } else if (property == 'width') {
        width = int.parse(_current.lexeme);
        _advance();
      } else if (property == 'height') {
        height = int.parse(_current.lexeme);
        _advance();
      } else if (property == 'font') {
        font = _parseStringLiteral('Expect font name as string');
      } else {
        _errorReporter.reportStandardError(
          'Unexpected property in branding: $property',
          _current.position.offset,
        );
        _advance();
      }
    }

    _consume(TokenType.rightBrace, "Expect '}' after branding definition");

    _popContext();

    return BrandingNode(
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a terminology section.
  TerminologyNode _parseTerminology() {
    final sourcePosition = _current.position;

    _pushContext(_ParsingContext.terminology);

    _consume(TokenType.leftBrace, "Expect '{' after terminology declaration");

    String? enterprise;
    String? person;
    String? softwareSystem;
    String? container;
    String? component;
    String? code;
    String? deploymentNode;
    String? relationship;

    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      final term = _parseIdentifierOrString('Expect terminology term name');

      if (term == 'enterprise') {
        enterprise = _parseStringLiteral('Expect term value as string');
      } else if (term == 'person') {
        person = _parseStringLiteral('Expect term value as string');
      } else if (term == 'softwareSystem') {
        softwareSystem = _parseStringLiteral('Expect term value as string');
      } else if (term == 'container') {
        container = _parseStringLiteral('Expect term value as string');
      } else if (term == 'component') {
        component = _parseStringLiteral('Expect term value as string');
      } else if (term == 'code') {
        code = _parseStringLiteral('Expect term value as string');
      } else if (term == 'deploymentNode') {
        deploymentNode = _parseStringLiteral('Expect term value as string');
      } else if (term == 'relationship') {
        relationship = _parseStringLiteral('Expect term value as string');
      } else {
        _errorReporter.reportStandardError(
          'Unexpected term in terminology: $term',
          _current.position.offset,
        );
        _advance();
      }
    }

    _consume(TokenType.rightBrace, "Expect '}' after terminology definition");

    _popContext();

    return TerminologyNode(
      sourcePosition: sourcePosition,
    );
  }

  /// Parses a configuration section.
  Map<String, String> _parseConfiguration() {
    final config = <String, String>{};

    _pushContext(_ParsingContext.configuration);

    _consume(TokenType.leftBrace, "Expect '{' after configuration declaration");

    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      final key = _parseIdentifierOrString('Expect configuration key');
      final value = _parseStringLiteral('Expect configuration value as string');

      config[key] = value;
    }

    _consume(TokenType.rightBrace, "Expect '}' after configuration definition");

    _popContext();

    return config;
  }

  /// Parses a string literal with enhanced error recovery and normalization.
  ///
  /// This method handles both regular and multi-line string literals, provides
  /// detailed error messages for common string-related errors, and offers robust
  /// recovery strategies when invalid strings are encountered.
  ///
  /// @param errorMessage The error message to display if string parsing fails
  /// @return The parsed string value or a placeholder for error recovery
  String _parseStringLiteral(String errorMessage) {
    if (_check(TokenType.string)) {
      // Get the string value from the token
      final value = _current.value as String? ?? _current.lexeme;

      // Store the position for potential error reporting
      final tokenPosition = _current.position;
      _advance();

      // Check for concatenated strings (multiple adjacent string literals)
      // This is a common pattern in DSL files for readability:
      // "This is a long string "
      // "that spans multiple lines in the source code"
      if (_check(TokenType.string)) {
        final concatenatedParts = <String>[value];

        // Collect all adjacent string literals
        while (_check(TokenType.string)) {
          concatenatedParts.add(_current.value as String? ?? _current.lexeme);
          _advance();
        }

        // If we found multiple parts, join them
        if (concatenatedParts.length > 1) {
          _errorReporter.reportInfo(
            'Multiple adjacent string literals concatenated (${concatenatedParts.length} parts)',
            tokenPosition.offset,
          );

          return concatenatedParts.join('');
        }
      }

      return value;
    }

    // Error Recovery Strategy 1: Handle identifiers as strings (common error in DSL files)
    if (_check(TokenType.identifier)) {
      final value = _current.lexeme;
      final tokenPosition = _current.position;
      _advance();

      // Look ahead to see if there's a pattern of multiple identifiers that should be a string
      // (e.g., This is my string)
      final identifierParts = <String>[value];

      // Continue collecting identifiers as long as they appear to be part of a single string phrase
      while (_check(TokenType.identifier) ||
          _check(TokenType.dot) ||
          _check(TokenType.minus) ||
          _check(TokenType.plus)) {
        identifierParts.add(_current.lexeme);
        _advance();
      }

      final reconstructedString = identifierParts.join(' ').trim();

      _errorReporter.reportWarning(
        '$errorMessage (treating ${identifierParts.length > 1 ? "identifier sequence" : "identifier"} "${reconstructedString}" as a string literal)',
        tokenPosition.offset,
      );

      return reconstructedString;
    }

    // Error Recovery Strategy 2: Try to be flexible with other literals
    if (_check(TokenType.integer) ||
        _check(TokenType.double) ||
        _check(TokenType.boolean)) {
      final value = _current.lexeme;
      final tokenPosition = _current.position;
      _advance();

      _errorReporter.reportWarning(
        '$errorMessage (treating literal value "${value}" as a string)',
        tokenPosition.offset,
      );

      return value;
    }

    // Error Recovery Strategy 3: Handle common punctuation that might be mistaken for strings
    if (_check(TokenType.leftBrace) ||
        _check(TokenType.rightBrace) ||
        _check(TokenType.leftParen) ||
        _check(TokenType.rightParen) ||
        _check(TokenType.arrow)) {
      final value = _current.lexeme;
      final tokenPosition = _current.position;
      _advance();

      _errorReporter.reportStandardError(
        '$errorMessage (found "${value}" instead - strings must be quoted)',
        tokenPosition.offset,
      );

      return value;
    }

    // Error Recovery Strategy 4: Report the error and attempt advanced recovery
    _error(errorMessage);

    // Look ahead for a potential string token that might have been meant to be used here
    int lookAhead = 1;
    int maxLookAhead = 5; // Increased from 3 for better recovery chances

    while (lookAhead < maxLookAhead) {
      if (_position + lookAhead >= _tokens.length) break;

      final token = _tokens[_position + lookAhead];

      // If we find a string token nearby, use it
      if (token.type == TokenType.string) {
        _position += lookAhead; // Skip to that token
        _current = _tokens[_position];
        final value = _current.value as String? ?? _current.lexeme;
        _advance();

        _errorReporter.reportInfo(
          'Using string literal found after error point (skipped $lookAhead token(s))',
          _current.position.offset,
        );

        return value;
      }

      // If we find an identifier that is followed by structural elements,
      // it's likely meant to be a string
      if (token.type == TokenType.identifier &&
          _position + lookAhead + 1 < _tokens.length) {
        final nextToken = _tokens[_position + lookAhead + 1];

        if (nextToken.type == TokenType.leftBrace ||
            nextToken.type == TokenType.arrow ||
            nextToken.type == TokenType.equals) {
          _position += lookAhead; // Skip to that token
          _current = _tokens[_position];
          final value = _current.lexeme;
          _advance();

          _errorReporter.reportInfo(
            'Using identifier as string literal for recovery: "$value"',
            _current.position.offset,
          );

          return value;
        }
      }

      lookAhead++;
    }

    // Error Recovery Strategy 5: If we couldn't find a suitable token,
    // synchronize and return a context-aware placeholder
    final placeholder = _getContextualPlaceholder();
    _synchronize();
    return placeholder;
  }

  /// Generates a contextual placeholder based on the current parsing context
  String _getContextualPlaceholder() {
    switch (_currentContext) {
      case _ParsingContext.workspace:
        return '[Unnamed Workspace]';
      case _ParsingContext.model:
        return '[Unnamed Model Element]';
      case _ParsingContext.element:
        return '[Unnamed Element]';
      case _ParsingContext.view:
        return '[Unnamed View]';
      case _ParsingContext.style:
        return '[Unnamed Style]';
      default:
        return '[missing string]';
    }
  }

  /// Parses an identifier or string literal with enhanced error recovery.
  ///
  /// This method tries to accommodate various ways users might specify identifiers
  /// in the DSL, including strings, bare identifiers, and special handling for common
  /// patterns in Structurizr DSL files.
  ///
  /// @param errorMessage The error message to display if parsing fails
  /// @return The parsed identifier or a placeholder for error recovery
  String _parseIdentifierOrString(String errorMessage) {
    // Case 1: Standard identifier token
    if (_check(TokenType.identifier)) {
      final value = _current.lexeme;
      final position = _current.position;
      _advance();

      // Handle dot notation (common in DSL references like "system.container")
      String fullIdentifier = value;
      while (_match(TokenType.dot) && _check(TokenType.identifier)) {
        fullIdentifier += '.' + _current.lexeme;
        _advance();
      }

      // If different from the original value, report the compound identifier
      if (fullIdentifier != value) {
        _errorReporter.reportInfo(
          'Using compound identifier: "$fullIdentifier"',
          position.offset,
        );
      }

      return fullIdentifier;
    }
    // Case 2: String token (can be used as identifier in Structurizr DSL)
    else if (_check(TokenType.string)) {
      final stringValue = _parseStringLiteral(errorMessage);

      // If the string has spaces or special characters, issue a warning
      if (stringValue.contains(' ') ||
          stringValue.contains('-') ||
          !RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(stringValue)) {
        _errorReporter.reportInfo(
          'Using string as identifier: "$stringValue" (note that spaces or special characters might cause issues in references)',
          _current.position.offset,
        );
      }

      return stringValue;
    }
    // Case 3: Keyword used as identifier (common mistake)
    else if (_isKeyword(_current.type)) {
      final keyword = _current.lexeme;
      final position = _current.position;
      _advance();

      _errorReporter.reportWarning(
        '$errorMessage (using keyword "$keyword" as identifier - this might conflict with DSL syntax)',
        position.offset,
      );

      return keyword;
    }
    // Case 4: Number or boolean used as identifier
    else if (_check(TokenType.integer) ||
        _check(TokenType.double) ||
        _check(TokenType.boolean)) {
      final value = _current.lexeme;
      final position = _current.position;
      _advance();

      _errorReporter.reportWarning(
        '$errorMessage (treating literal "${value}" as an identifier)',
        position.offset,
      );

      return value;
    }
    // Case 5: Special handling for common patterns in references
    else if (_check(TokenType.leftBrace) ||
        _check(TokenType.rightBrace) ||
        _check(TokenType.arrow) ||
        _check(TokenType.this_)) {
      // Special case for 'this' keyword which is common in self-references
      if (_check(TokenType.this_)) {
        _advance();
        return 'this';
      }

      final value = _current.lexeme;
      final position = _current.position;
      _advance();

      _errorReporter.reportStandardError(
        '$errorMessage (found "$value" - expected identifier or string)',
        position.offset,
      );

      return '[invalid:$value]';
    }

    // Case 6: Report error and try advanced recovery
    _error(errorMessage);

    // Look ahead for tokens that might be valid identifiers
    int lookAhead = 1;
    int maxLookAhead = 3;

    while (lookAhead < maxLookAhead) {
      if (_position + lookAhead >= _tokens.length) break;

      final token = _tokens[_position + lookAhead];

      // If we find a suitable token for recovery, use it
      if (token.type == TokenType.identifier ||
          token.type == TokenType.string ||
          _isKeyword(token.type)) {
        _position += lookAhead;
        _current = _tokens[_position];

        // Use string or identifier parsing based on the token type
        if (token.type == TokenType.string) {
          return _parseStringLiteral('$errorMessage (recovery attempt)');
        } else {
          final value = _current.lexeme;
          _advance();

          _errorReporter.reportInfo(
            'Using recovered identifier: "$value"',
            _current.position.offset,
          );

          return value;
        }
      }

      lookAhead++;
    }

    // Generate a proper reference based on context
    final placeholder = _getContextualIdentifier();
    _synchronize();
    return placeholder;
  }

  /// Checks if the given token type is a keyword
  bool _isKeyword(TokenType type) {
    // Check against keywords that might be used as identifiers
    return type == TokenType.workspace ||
        type == TokenType.model ||
        type == TokenType.views ||
        type == TokenType.person ||
        type == TokenType.softwareSystem ||
        type == TokenType.container ||
        type == TokenType.component;
  }

  /// Generates contextual identifier based on current parsing context
  String _getContextualIdentifier() {
    // This can be expanded based on specific contexts in the grammar
    switch (_currentContext) {
      case _ParsingContext.workspace:
        return 'defaultWorkspace';
      case _ParsingContext.model:
        return 'defaultElement';
      case _ParsingContext.element:
        return 'defaultItem';
      case _ParsingContext.view:
        return 'defaultView';
      default:
        return 'missing_identifier';
    }
  }

  /// Advances to the next token.
  void _advance() {
    if (!_isAtEnd() && _tokens.isNotEmpty && _position < _tokens.length) {
      _previous = _current;
      _position++;
      if (_position < _tokens.length) {
        _current = _tokens[_position];
      }
    }
  }

  /// Consumes the current token if it matches the expected type.
  /// If not, reports an error with helpful context and suggestions.
  /// Implements error recovery strategies to continue parsing when possible.
  void _consume(TokenType type, String errorMessage) {
    if (_check(type)) {
      _advance();
      return;
    }

    // Enhanced error reporting with context-sensitive suggestions
    final contextMessage = _getContextSensitiveErrorMessage(type);
    final suggestion = _getSuggestionForMismatch(type, _current.type);

    String enhancedMessage = '$errorMessage, got ${_current.type}';
    if (contextMessage.isNotEmpty) {
      enhancedMessage += '\n$contextMessage';
    }
    if (suggestion.isNotEmpty) {
      enhancedMessage += '\nSuggestion: $suggestion';
    }

    _error(enhancedMessage);

    // Error recovery: attempt to insert missing token or skip invalid token
    if (_shouldInsertMissingToken(type)) {
      // Cases where it makes sense to continue as if the token was there
      _errorReporter.reportInfo(
        'Continuing as if ${type.toString()} was present',
        _current.position.offset,
      );
      // Don't advance, just pretend we saw the token
    } else if (_shouldSkipCurrentToken(type, _current.type)) {
      // Skip the current token and try again
      _advance();

      // If the next token matches what we want, consume it
      if (_check(type)) {
        _advance(); // Consume the token we wanted
      }
    } else {
      // Default recovery: synchronize to a recovery point
      _synchronize();
    }

    // Reset panic mode after recovery
    _panicMode = false;
  }

  /// Determines whether to insert a missing token and continue.
  /// This is useful for tokens like braces and delimiters that can be inferred.
  bool _shouldInsertMissingToken(TokenType type) {
    // We can insert these tokens for better recovery:
    return type == TokenType.semicolon || // Missing statement terminator
        (type == TokenType.rightBrace &&
            _isAtBlockEnd()); // Missing closing brace at logical block end
  }

  /// Determines whether to skip the current token and try again.
  /// This is useful for handling extraneous or misspelled tokens.
  bool _shouldSkipCurrentToken(TokenType expected, TokenType actual) {
    // Skip unexpected punctuation
    if (actual == TokenType.comma ||
        actual == TokenType.semicolon ||
        actual == TokenType.colon) {
      return true;
    }

    // Skip if we expected a string but got an identifier (common error)
    if (expected == TokenType.string && actual == TokenType.identifier) {
      return false; // Don't skip, treat identifier as if it were a string
    }

    return false;
  }

  /// Checks if we're at what appears to be a logical block end.
  bool _isAtBlockEnd() {
    // At end of file
    if (_isAtEnd()) return true;

    // Current token starts a new block or section that would come after a }
    final startSectionTokens = [
      TokenType.model,
      TokenType.views,
      TokenType.styles,
      TokenType.themes,
      TokenType.branding,
      TokenType.terminology,
      TokenType.configuration,
    ];

    return startSectionTokens.contains(_current.type);
  }

  /// Provides context-sensitive error messaging based on the expected token type.
  String _getContextSensitiveErrorMessage(TokenType expectedType) {
    final context = _currentContext;

    // Provide context based on what we're parsing
    switch (context) {
      case _ParsingContext.workspace:
        if (expectedType == TokenType.leftBrace) {
          return 'A workspace must have a body enclosed in curly braces { }';
        }
        return 'Workspace sections include: model, views, styles, themes, branding, etc.';

      case _ParsingContext.model:
        if (expectedType == TokenType.softwareSystem ||
            expectedType == TokenType.person ||
            expectedType == TokenType.container ||
            expectedType == TokenType.component) {
          return 'Expected model element declaration';
        }
        return 'Model elements include: person, softwareSystem, container, component, etc.';

      case _ParsingContext.element:
        if (expectedType == TokenType.string) {
          return 'Element properties often require string values in quotes, e.g., "example"';
        }
        return 'Element properties include: tags, description, technology, url, properties, etc.';

      case _ParsingContext.views:
        if (expectedType == TokenType.systemLandscape ||
            expectedType == TokenType.systemContext ||
            expectedType == TokenType.containerView) {
          return 'Expected view type declaration';
        }
        return 'View types include: systemLandscape, systemContext, container, component, etc.';

      case _ParsingContext.view:
        if (expectedType == TokenType.string) {
          return 'View properties like keys, titles, etc. require string values in quotes, e.g., "example"';
        }
        return 'View properties include: include, exclude, autoLayout, animation, etc.';

      case _ParsingContext.styles:
        if (expectedType == TokenType.string) {
          return 'Style tags require string values in quotes, e.g., "example"';
        }
        return 'Style sections include: element and relationship style declarations';

      case _ParsingContext.style:
        return 'Style properties include: shape, icon, color, background, stroke, etc.';

      default:
        return '';
    }
  }

  /// Provides syntax suggestions for common token mismatches.
  String _getSuggestionForMismatch(TokenType expected, TokenType actual) {
    // Common token pair mismatches with suggested fixes
    if (expected == TokenType.string && actual == TokenType.identifier) {
      return 'Enclose the identifier in quotes, e.g., "${_current.lexeme}"';
    }

    if (expected == TokenType.leftBrace && actual == TokenType.identifier) {
      return 'Add opening brace { before continuing';
    }

    if (expected == TokenType.rightBrace && actual == TokenType.eof) {
      return 'Add closing brace } to complete the block';
    }

    if (expected == TokenType.arrow && actual == TokenType.minus) {
      return 'Use -> for relationships (not just -)';
    }

    if ((expected == TokenType.systemContext ||
            expected == TokenType.containerView ||
            expected == TokenType.componentView) &&
        (actual == TokenType.container || actual == TokenType.component)) {
      // These cases might be ambiguous because container/component are used both as element types and view types
      return 'For a view type, check if you need a different keyword like systemContext, container, component, etc.';
    }

    return '';
  }

  /// Returns true if the current token matches the given type.
  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _current.type == type;
  }

  /// Returns true if we've reached the end of the tokens.
  bool _isAtEnd() {
    return _current.type == TokenType.eof;
  }

  /// Returns the next token without consuming it.
  Token _peekNext() {
    if (_position + 1 >= _tokens.length) {
      return _tokens.last;
    }
    return _tokens[_position + 1];
  }

  /// Matches the current token against the given type and advances if it matches.
  bool _match(TokenType type) {
    if (type == TokenType.documentation || type == TokenType.decisions) {
      logger.fine(
          'DEBUG: Checking for token: $type, current token: ${_current.type}, lexeme: ${_current.lexeme}, matches: ${_check(type)}');
    }

    // For documentation and decisions, also match identifier tokens with matching lexeme
    if ((type == TokenType.documentation &&
            _current.lexeme == 'documentation') ||
        (type == TokenType.decisions && _current.lexeme == 'decisions')) {
      logger.fine('DEBUG: Special case match by lexeme for $type');
      _advance();
      return true;
    }

    if (_check(type)) {
      _advance();
      return true;
    }

    return false;
  }

  /// Synchronizes the parser after an error.
  ///
  /// This method attempts to recover from syntax errors by skipping tokens
  /// until a synchronization point is reached. Synchronization points are:
  /// - Block start/end tokens: { }
  /// - Section keywords: model, views, styles, etc.
  /// - Element type keywords: person, softwareSystem, etc.
  /// - Statement terminators: ; (when used)
  /// - The end of the current context (determined by context stack)
  ///
  /// Additionally, it can suggest corrections for common mistakes.
  void _synchronize() {
    // Skip current token
    _advance();

    // Get current parsing context to make better recovery decisions
    final context = _currentContext;

    // If the token is ';', consume it as it's likely the end of a statement
    // that we're recovering from
    if (_check(TokenType.semicolon)) {
      _advance();
    }

    while (!_isAtEnd()) {
      // First check for common synchronization points across all contexts

      // Right brace usually ends the current context
      if (_check(TokenType.rightBrace)) {
        // Found end of block, good synchronization point
        return;
      }

      // Synchronize to statement boundaries
      if (_previous != null &&
          (_previous?.type == TokenType.semicolon ||
              _previous?.type == TokenType.rightBrace)) {
        // Found end of statement, good synchronization point
        return;
      }

      // Context-specific synchronization points
      switch (context) {
        case _ParsingContext.workspace:
          // Synchronize to major section keywords
          if (_check(TokenType.model) ||
              _check(TokenType.views) ||
              _check(TokenType.styles) ||
              _check(TokenType.themes) ||
              _check(TokenType.branding) ||
              _check(TokenType.terminology) ||
              _check(TokenType.documentation) || // Added for documentation
              _check(TokenType.decisions) || // Added for decisions
              _check(TokenType.configuration)) {
            return;
          }
          break;

        case _ParsingContext.model:
          // Synchronize to model element types
          if (_check(TokenType.person) ||
              _check(TokenType.softwareSystem) ||
              _check(TokenType.container) ||
              _check(TokenType.component) ||
              _check(TokenType.deploymentEnvironment) ||
              _check(TokenType.relationship)) {
            return;
          }
          break;

        case _ParsingContext.documentation:
          // Synchronize to documentation-specific elements
          if (_check(TokenType.content) ||
              _check(TokenType.section) ||
              _check(TokenType.format) ||
              _check(TokenType.rightBrace)) {
            return;
          }
          break;

        case _ParsingContext.decisions:
          // Synchronize to decision-specific elements
          if (_check(TokenType.decision) || _check(TokenType.rightBrace)) {
            return;
          }
          break;

        case _ParsingContext.decision:
          // Synchronize to decision properties
          if (_check(TokenType.title) ||
              _check(TokenType.status) ||
              _check(TokenType.date) ||
              _check(TokenType.content) ||
              _check(TokenType.format) ||
              // Use identifier for links to avoid TokenType.links error
              (_check(TokenType.identifier) && _current.lexeme == 'links') ||
              _check(TokenType.rightBrace)) {
            return;
          }
          break;

        case _ParsingContext.documentationSection:
          // Synchronize to section properties
          if (_check(TokenType.content) || _check(TokenType.rightBrace)) {
            return;
          }
          break;

        case _ParsingContext.views:
          // Synchronize to view types
          if (_check(TokenType.systemLandscape) ||
              _check(TokenType.systemContext) ||
              _check(TokenType.containerView) ||
              _check(TokenType.componentView) ||
              _check(TokenType.dynamicView) ||
              _check(TokenType.deploymentView) ||
              _check(TokenType.filteredView) ||
              _check(TokenType.customView) ||
              _check(TokenType.imageView) ||
              _check(TokenType.styles) ||
              _check(TokenType.themes) ||
              _check(TokenType.configuration)) {
            return;
          }
          break;

        case _ParsingContext.element:
        case _ParsingContext.view:
        case _ParsingContext.style:
          // For elements, views, and styles, synchronize on property tokens or relationships
          if (_check(TokenType.tags) ||
              _check(TokenType.description) ||
              _check(TokenType.technology) ||
              _check(TokenType.url) ||
              _check(TokenType.properties) ||
              _check(TokenType.location) ||
              _check(TokenType.arrow) || // Relationship
              _check(TokenType.include) || // View specific
              _check(TokenType.exclude) ||
              _check(TokenType.autoLayout) ||
              _check(TokenType.animation) ||
              _check(TokenType.shape) || // Style specific
              _check(TokenType.color)) {
            return;
          }
          // If we have an identifier that might be the next valid element, return
          if (_check(TokenType.identifier) &&
              _peekNext().type == TokenType.equals) {
            return;
          }
          break;

        default:
          break;
      }

      // Always synchronize on block boundaries
      if (_check(TokenType.leftBrace) || _check(TokenType.rightBrace)) {
        // Add a helpful diagnostic about blocks
        if (_check(TokenType.rightBrace)) {
          // We found a closing brace, which might be what we're looking for
          // Let's provide a helpful message based on context
          _errorReporter.reportInfo(
            'Synchronizing at closing brace after error - this ends the current ${_contextToString(context)} block',
            _current.position.offset,
          );
        }
        return;
      }

      // Check for missing quotes in strings
      if (_check(TokenType.identifier) && _contextRequiresStrings(context)) {
        _errorReporter.reportInfo(
          'Found identifier "${_current.lexeme}" where a string literal might be expected (missing quotes?)',
          _current.position.offset,
        );
      }

      _advance();
    }
  }

  /// Provides a string representation of the current parsing context.
  String _contextToString(_ParsingContext context) {
    switch (context) {
      case _ParsingContext.workspace:
        return 'workspace';
      case _ParsingContext.model:
        return 'model';
      case _ParsingContext.element:
        return 'element';
      case _ParsingContext.views:
        return 'views';
      case _ParsingContext.view:
        return 'view';
      case _ParsingContext.styles:
        return 'styles';
      case _ParsingContext.style:
        return 'style';
      case _ParsingContext.branding:
        return 'branding';
      case _ParsingContext.terminology:
        return 'terminology';
      case _ParsingContext.configuration:
        return 'configuration';
      default:
        return 'unknown';
    }
  }

  /// Determines whether the current context expects string literals for its properties.
  bool _contextRequiresStrings(_ParsingContext context) {
    // Most properties in the DSL require string literals
    return context == _ParsingContext.element ||
        context == _ParsingContext.view ||
        context == _ParsingContext.style;
  }

  /// Pushes a new parsing context onto the stack.
  void _pushContext(_ParsingContext contextType) {
    // Create a Context object from the ParsingContext enum
    final context = Context(
      contextType.toString().split('.').last,
      data: {'type': contextType},
    );
    _contextStack.push(context);
  }

  /// Pops the current parsing context from the stack.
  void _popContext() {
    if (!_contextStack.isEmpty()) {
      _contextStack.pop();
    }
  }

  /// Returns the current parsing context.
  _ParsingContext get _currentContext {
    if (_contextStack.isEmpty()) {
      return _ParsingContext.unknown;
    }

    // Extract the context type from the data map
    final context = _contextStack.current();
    if (context.data.containsKey('type')) {
      return context.data['type'] as _ParsingContext;
    }

    return _ParsingContext.unknown;
  }

  /// Accepts identifiers or keywords as variable names for assignments.
  String _parseVariableName(String errorMessage) {
    if (_check(TokenType.identifier) || _isKeyword(_current.type)) {
      final value = _current.lexeme;
      _advance();
      return value;
    }
    return _parseIdentifierOrString(errorMessage);
  }

  /// Returns the list of errors encountered during parsing (for test compatibility).
  List<ParserError> get errors => errorReporter.errors;
}

/// Enum representing different parsing contexts.
enum _ParsingContext {
  unknown,
  workspace,
  model,
  element,
  views,
  view,
  styles,
  style,
  branding,
  terminology,
  configuration,
  documentation,
  documentationSection,
  decisions,
  decision,
  properties,
}
