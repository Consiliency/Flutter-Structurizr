import 'ast/ast_node.dart';
import 'error_reporter.dart';
import 'lexer/lexer.dart';
import 'lexer/token.dart';

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

  /// The tokens from the lexer.
  final List<Token> _tokens;

  /// The current position in the token list.
  int _position = 0;

  /// Variables defined in the DSL.
  final Map<String, Object> _variables = {};

  /// Stack of parsing contexts.
  final List<_ParsingContext> _contextStack = [];

  /// Flag indicating whether the parser is in panic mode (error recovery).
  bool _panicMode = false;

  /// Count of errors encountered during parsing.
  int _errorCount = 0;

  /// Maximum number of errors to report before stopping.
  static const int _maxErrorCount = 25;

  /// Creates a new parser for the given source code.
  Parser(String source)
      : _lexer = Lexer(source),
        _errorReporter = ErrorReporter(source),
        _tokens = [],
        _current = Token(
          type: TokenType.error,
          lexeme: '',
          position: SourcePosition(line: 0, column: 0, offset: 0),
        ) {
    _tokens.addAll(_lexer.scanTokens());
    _advance();
  }

  /// Returns the error reporter for this parser.
  ErrorReporter get errorReporter => _errorReporter;

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

      // Parse the workspace
      final workspace = _parseWorkspace();

      // Report parse statistics
      if (_errorCount > 0) {
        _errorReporter.reportInfo(
          'Parsing completed with $_errorCount errors.\n' +
          'The resulting model may be incomplete or contain placeholders for erroneous content.',
          0,
        );
      }

      return workspace;
    } catch (e) {
      // Only catch unexpected exceptions, not our controlled error handling
      _errorReporter.reportFatalError(
        'Fatal parsing error: $e',
        _current.position.offset,
      );

      // Return a minimal valid workspace that won't cause downstream errors
      return WorkspaceNode(
        name: 'Error',
        description: 'Parsing failed with errors - this is a placeholder workspace',
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
  
  /// Parses a workspace.
  WorkspaceNode _parseWorkspace() {
    _pushContext(_ParsingContext.workspace);
    
    _consume(TokenType.workspace, "Expect 'workspace' keyword");
    
    final name = _parseStringLiteral("Expect workspace name as string");
    String? description;
    
    if (_check(TokenType.string)) {
      description = _parseStringLiteral("Expect workspace description as string");
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
    
    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      if (_match(TokenType.model)) {
        model = _parseModel();
      } else if (_match(TokenType.views)) {
        views = _parseViews();
      } else if (_match(TokenType.styles)) {
        styles = _parseStyles();
      } else if (_match(TokenType.themes)) {
        themes.addAll(_parseThemes());
      } else if (_match(TokenType.branding)) {
        branding = _parseBranding();
      } else if (_match(TokenType.identifier) && _current.lexeme == 'terminology') {
        terminology = _parseTerminology();
      } else if (_match(TokenType.identifier) && _current.lexeme == 'properties') {
        properties = _parseProperties();
      } else if (_match(TokenType.identifier) && _current.lexeme == 'configuration') {
        configuration.addAll(_parseConfiguration());
      } else {
        _errorReporter.reportStandardError(
          "Unexpected token in workspace: ${_current.lexeme}",
          _current.position.offset,
        );
        _advance(); // Skip token and continue
      }
    }
    
    _consume(TokenType.rightBrace, "Expect '}' after workspace definition");
    
    _popContext();
    
    return WorkspaceNode(
      name: name,
      description: description,
      model: model,
      views: views,
      styles: styles,
      themes: themes,
      branding: branding,
      terminology: terminology,
      properties: properties,
      configuration: configuration,
      sourcePosition: _current.position,
    );
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
      if (_check(TokenType.identifier) || _check(TokenType.string)) {
        // Variable definition or element declaration
        final startToken = _current;
        
        if (_peekNext().type == TokenType.equals) {
          // Variable definition
          final varName = _parseIdentifierOrString("Expect variable name");
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
              "Unsupported variable assignment in model: ${_current.lexeme}",
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_match(TokenType.arrow)) {
          // Implicit relationship
          final source = startToken.lexeme;
          _errorReporter.reportStandardError(
            "Implicit relationships not supported yet",
            startToken.position.offset,
          );
          _synchronize();
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in model: ${_current.lexeme}",
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
      } else if (_match(TokenType.identifier) && _current.lexeme == 'enterprise') {
        // Parse enterprise name
        enterpriseName = _parseStringLiteral("Expect enterprise name as string");
      } else {
        _errorReporter.reportStandardError(
          "Unexpected token in model: ${_current.lexeme}",
          _current.position.offset,
        );
        _advance();
      }
    }
    
    _consume(TokenType.rightBrace, "Expect '}' after model definition");
    
    _popContext();
    
    return ModelNode(
      enterpriseName: enterpriseName,
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
    
    String name = _parseStringLiteral("Expect person name as string");
    String? description;
    String? location;
    
    if (_check(TokenType.string)) {
      description = _parseStringLiteral("Expect person description as string");
    }
    
    TagsNode? tags;
    PropertiesNode? properties;
    final relationships = <RelationshipNode>[];
    
    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);
      
      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) && _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_match(TokenType.identifier) && _current.lexeme == 'location') {
          location = _parseStringLiteral("Expect location as string");
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in person: ${_current.lexeme}",
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
      tags: tags,
      properties: properties,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a software system element.
  SoftwareSystemNode _parseSoftwareSystem(String? id) {
    final sourcePosition = _current.position;
    
    String name = _parseStringLiteral("Expect software system name as string");
    String? description;
    String? location;
    
    if (_check(TokenType.string)) {
      description = _parseStringLiteral("Expect software system description as string");
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
        } else if (_match(TokenType.identifier) && _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_match(TokenType.identifier) && _current.lexeme == 'location') {
          location = _parseStringLiteral("Expect location as string");
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.equals) {
          // Variable definition
          final varName = _parseIdentifierOrString("Expect variable name");
          _consume(TokenType.equals, "Expect '=' after variable name");
          
          if (_match(TokenType.container)) {
            final container = _parseContainer(varName, id ?? name.replaceAll(' ', ''));
            containers.add(container);
            _variables[varName] = container;
          } else {
            _errorReporter.reportStandardError(
              "Unsupported variable assignment in software system: ${_current.lexeme}",
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else if (_match(TokenType.container)) {
          containers.add(_parseContainer(null, id ?? name.replaceAll(' ', '')));
        } else if (_match(TokenType.deploymentEnvironment)) {
          deploymentEnvironments.add(_parseDeploymentEnvironment(null, id ?? name.replaceAll(' ', '')));
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in software system: ${_current.lexeme}",
            _current.position.offset,
          );
          _advance();
        }
      }
      
      _consume(TokenType.rightBrace, "Expect '}' after software system definition");
      _popContext();
    }
    
    final systemId = id ?? name.replaceAll(' ', '');
    
    return SoftwareSystemNode(
      id: systemId,
      name: name,
      description: description,
      location: location,
      tags: tags,
      properties: properties,
      containers: containers,
      deploymentEnvironments: deploymentEnvironments,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a container element.
  ContainerNode _parseContainer(String? id, String parentId) {
    final sourcePosition = _current.position;
    
    String name = _parseStringLiteral("Expect container name as string");
    String? description;
    String? technology;
    
    if (_check(TokenType.string)) {
      description = _parseStringLiteral("Expect container description as string");
      
      if (_check(TokenType.string)) {
        technology = _parseStringLiteral("Expect container technology as string");
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
        } else if (_match(TokenType.identifier) && _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.equals) {
          // Variable definition
          final varName = _parseIdentifierOrString("Expect variable name");
          _consume(TokenType.equals, "Expect '=' after variable name");
          
          if (_match(TokenType.component)) {
            final component = _parseComponent(varName, id ?? name.replaceAll(' ', ''));
            components.add(component);
            _variables[varName] = component;
          } else {
            _errorReporter.reportStandardError(
              "Unsupported variable assignment in container: ${_current.lexeme}",
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else if (_match(TokenType.component)) {
          components.add(_parseComponent(null, id ?? name.replaceAll(' ', '')));
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in container: ${_current.lexeme}",
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
      parentId: parentId,
      name: name,
      description: description,
      technology: technology,
      tags: tags,
      properties: properties,
      components: components,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a component element.
  ComponentNode _parseComponent(String? id, String parentId) {
    final sourcePosition = _current.position;
    
    String name = _parseStringLiteral("Expect component name as string");
    String? description;
    String? technology;
    
    if (_check(TokenType.string)) {
      description = _parseStringLiteral("Expect component description as string");
      
      if (_check(TokenType.string)) {
        technology = _parseStringLiteral("Expect component technology as string");
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
        } else if (_match(TokenType.identifier) && _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in component: ${_current.lexeme}",
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
      parentId: parentId,
      name: name,
      description: description,
      technology: technology,
      tags: tags,
      properties: properties,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a deployment environment.
  DeploymentEnvironmentNode _parseDeploymentEnvironment(String? id, String parentId) {
    final sourcePosition = _current.position;
    
    String name = _parseStringLiteral("Expect deployment environment name as string");
    String? description;
    
    if (_check(TokenType.string)) {
      description = _parseStringLiteral("Expect deployment environment description as string");
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
        } else if (_match(TokenType.identifier) && _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.equals) {
          // Variable definition
          final varName = _parseIdentifierOrString("Expect variable name");
          _consume(TokenType.equals, "Expect '=' after variable name");
          
          if (_match(TokenType.deploymentNode)) {
            final node = _parseDeploymentNode(varName, id ?? name.replaceAll(' ', ''));
            deploymentNodes.add(node);
            _variables[varName] = node;
          } else {
            _errorReporter.reportStandardError(
              "Unsupported variable assignment in deployment environment: ${_current.lexeme}",
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else if (_match(TokenType.deploymentNode)) {
          deploymentNodes.add(_parseDeploymentNode(null, id ?? name.replaceAll(' ', '')));
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in deployment environment: ${_current.lexeme}",
            _current.position.offset,
          );
          _advance();
        }
      }
      
      _consume(TokenType.rightBrace, "Expect '}' after deployment environment definition");
      _popContext();
    }
    
    final envId = id ?? name.replaceAll(' ', '');
    
    return DeploymentEnvironmentNode(
      id: envId,
      parentId: parentId,
      name: name,
      description: description,
      tags: tags,
      properties: properties,
      deploymentNodes: deploymentNodes,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a deployment node.
  DeploymentNodeNode _parseDeploymentNode(String? id, String parentId) {
    final sourcePosition = _current.position;
    
    String name = _parseStringLiteral("Expect deployment node name as string");
    String? description;
    String? technology;
    
    if (_check(TokenType.string)) {
      description = _parseStringLiteral("Expect deployment node description as string");
      
      if (_check(TokenType.string)) {
        technology = _parseStringLiteral("Expect deployment node technology as string");
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
        } else if (_match(TokenType.identifier) && _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.equals) {
          // Variable definition
          final varName = _parseIdentifierOrString("Expect variable name");
          _consume(TokenType.equals, "Expect '=' after variable name");
          
          if (_match(TokenType.deploymentNode)) {
            final node = _parseDeploymentNode(varName, id ?? name.replaceAll(' ', ''));
            children.add(node);
            _variables[varName] = node;
          } else if (_match(TokenType.infrastructureNode)) {
            final node = _parseInfrastructureNode(varName, id ?? name.replaceAll(' ', ''));
            infrastructureNodes.add(node);
            _variables[varName] = node;
          } else if (_match(TokenType.identifier) && _current.lexeme == 'containerInstance') {
            final instance = _parseContainerInstance(varName, id ?? name.replaceAll(' ', ''));
            containerInstances.add(instance);
            _variables[varName] = instance;
          } else {
            _errorReporter.reportStandardError(
              "Unsupported variable assignment in deployment node: ${_current.lexeme}",
              _current.position.offset,
            );
            _synchronize();
          }
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else if (_match(TokenType.deploymentNode)) {
          children.add(_parseDeploymentNode(null, id ?? name.replaceAll(' ', '')));
        } else if (_match(TokenType.infrastructureNode)) {
          infrastructureNodes.add(_parseInfrastructureNode(null, id ?? name.replaceAll(' ', '')));
        } else if (_match(TokenType.identifier) && _current.lexeme == 'containerInstance') {
          containerInstances.add(_parseContainerInstance(null, id ?? name.replaceAll(' ', '')));
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in deployment node: ${_current.lexeme}",
            _current.position.offset,
          );
          _advance();
        }
      }
      
      _consume(TokenType.rightBrace, "Expect '}' after deployment node definition");
      _popContext();
    }
    
    final nodeId = id ?? name.replaceAll(' ', '');
    
    return DeploymentNodeNode(
      id: nodeId,
      parentId: parentId,
      name: name,
      description: description,
      technology: technology,
      tags: tags,
      properties: properties,
      children: children,
      infrastructureNodes: infrastructureNodes,
      containerInstances: containerInstances,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses an infrastructure node.
  InfrastructureNodeNode _parseInfrastructureNode(String? id, String parentId) {
    final sourcePosition = _current.position;
    
    String name = _parseStringLiteral("Expect infrastructure node name as string");
    String? description;
    String? technology;
    
    if (_check(TokenType.string)) {
      description = _parseStringLiteral("Expect infrastructure node description as string");
      
      if (_check(TokenType.string)) {
        technology = _parseStringLiteral("Expect infrastructure node technology as string");
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
        } else if (_match(TokenType.identifier) && _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in infrastructure node: ${_current.lexeme}",
            _current.position.offset,
          );
          _advance();
        }
      }
      
      _consume(TokenType.rightBrace, "Expect '}' after infrastructure node definition");
      _popContext();
    }
    
    final nodeId = id ?? name.replaceAll(' ', '');
    
    return InfrastructureNodeNode(
      id: nodeId,
      parentId: parentId,
      name: name,
      description: description,
      technology: technology,
      tags: tags,
      properties: properties,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a container instance.
  ContainerInstanceNode _parseContainerInstance(String? id, String parentId) {
    final sourcePosition = _current.position;
    
    String containerId = _parseIdentifierOrString("Expect container reference as string or identifier");
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
        } else if (_match(TokenType.identifier) && _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.arrow) {
          relationships.add(_parseImplicitRelationship());
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in container instance: ${_current.lexeme}",
            _current.position.offset,
          );
          _advance();
        }
      }
      
      _consume(TokenType.rightBrace, "Expect '}' after container instance definition");
      _popContext();
    }
    
    final instanceId = id ?? '${containerId}Instance';
    
    return ContainerInstanceNode(
      id: instanceId,
      parentId: parentId,
      containerId: containerId,
      name: 'Container Instance',
      description: 'Instance of $containerId',
      instanceCount: instanceCount,
      tags: tags,
      properties: properties,
      relationships: relationships,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a tags declaration.
  TagsNode _parseTags() {
    final sourcePosition = _current.position;
    final tagsList = <String>[];
    
    if (_check(TokenType.string)) {
      tagsList.add(_parseStringLiteral("Expect tag as string"));
      
      while (_match(TokenType.comma)) {
        tagsList.add(_parseStringLiteral("Expect tag as string"));
      }
    }
    
    // Join tags with commas
    final tags = tagsList.join(', ');
    
    return TagsNode(
      tags: tags,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a properties declaration.
  PropertiesNode _parseProperties() {
    final sourcePosition = _current.position;
    final properties = <PropertyNode>[];
    
    if (_match(TokenType.leftBrace)) {
      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        final propName = _parseIdentifierOrString("Expect property name");
        String? propValue;
        
        if (_match(TokenType.equals)) {
          propValue = _parseStringLiteral("Expect property value as string");
        }
        
        properties.add(PropertyNode(
          name: propName,
          value: propValue,
          sourcePosition: _current.position,
        ));
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
    
    final sourceId = _parseIdentifierOrString("Expect source element identifier");
    _consume(TokenType.arrow, "Expect '->' between source and destination");
    final destinationId = _parseIdentifierOrString("Expect destination element identifier");
    
    String? description;
    String? technology;
    
    if (_check(TokenType.string)) {
      description = _parseStringLiteral("Expect relationship description as string");
      
      if (_check(TokenType.string)) {
        technology = _parseStringLiteral("Expect relationship technology as string");
      }
    }
    
    TagsNode? tags;
    PropertiesNode? properties;
    
    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);
      
      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) && _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in relationship: ${_current.lexeme}",
            _current.position.offset,
          );
          _advance();
        }
      }
      
      _consume(TokenType.rightBrace, "Expect '}' after relationship definition");
      _popContext();
    }
    
    return RelationshipNode(
      sourceId: sourceId,
      destinationId: destinationId,
      description: description,
      technology: technology,
      tags: tags,
      properties: properties,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses an implicit relationship (source -> destination).
  RelationshipNode _parseImplicitRelationship() {
    final sourcePosition = _current.position;
    
    final sourceId = _parseIdentifierOrString("Expect source element identifier");
    _consume(TokenType.arrow, "Expect '->' between source and destination");
    final destinationId = _parseIdentifierOrString("Expect destination element identifier");
    
    String? description;
    String? technology;
    
    if (_check(TokenType.string)) {
      description = _parseStringLiteral("Expect relationship description as string");
      
      if (_check(TokenType.string)) {
        technology = _parseStringLiteral("Expect relationship technology as string");
      }
    }
    
    TagsNode? tags;
    PropertiesNode? properties;
    
    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.element);
      
      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_match(TokenType.tags)) {
          tags = _parseTags();
        } else if (_match(TokenType.identifier) && _current.lexeme == 'properties') {
          properties = _parseProperties();
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in relationship: ${_current.lexeme}",
            _current.position.offset,
          );
          _advance();
        }
      }
      
      _consume(TokenType.rightBrace, "Expect '}' after relationship definition");
      _popContext();
    }
    
    return RelationshipNode(
      sourceId: sourceId,
      destinationId: destinationId,
      description: description,
      technology: technology,
      tags: tags,
      properties: properties,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses the views section.
  ViewsNode _parseViews() {
    final sourcePosition = _current.position;
    
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
      } else if (_match(TokenType.identifier) && _current.lexeme == 'configuration') {
        configuration.addAll(_parseConfiguration());
      } else {
        _errorReporter.reportStandardError(
          "Unexpected token in views: ${_current.lexeme}",
          _current.position.offset,
        );
        _advance();
      }
    }
    
    _consume(TokenType.rightBrace, "Expect '}' after views definition");
    
    _popContext();
    
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
    
    String key = _parseStringLiteral("Expect view key as string");
    String? title;
    String? description;
    
    if (_check(TokenType.string)) {
      title = _parseStringLiteral("Expect view title as string");
      
      if (_check(TokenType.string)) {
        description = _parseStringLiteral("Expect view description as string");
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
            "Unexpected token in system landscape view: ${_current.lexeme}",
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
      includes: includes,
      excludes: excludes,
      autoLayout: autoLayout,
      animations: animations,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a system context view.
  SystemContextViewNode _parseSystemContextView() {
    final sourcePosition = _current.position;
    
    String systemId = _parseIdentifierOrString("Expect system identifier");
    String key = _parseStringLiteral("Expect view key as string");
    String? title;
    String? description;
    
    if (_check(TokenType.string)) {
      title = _parseStringLiteral("Expect view title as string");
      
      if (_check(TokenType.string)) {
        description = _parseStringLiteral("Expect view description as string");
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
            "Unexpected token in system context view: ${_current.lexeme}",
            _current.position.offset,
          );
          _advance();
        }
      }
      
      _consume(TokenType.rightBrace, "Expect '}' after view definition");
      _popContext();
    }
    
    return SystemContextViewNode(
      key: key,
      systemId: systemId,
      title: title,
      description: description,
      includes: includes,
      excludes: excludes,
      autoLayout: autoLayout,
      animations: animations,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a container view.
  ContainerViewNode _parseContainerView() {
    final sourcePosition = _current.position;
    
    String systemId = _parseIdentifierOrString("Expect system identifier");
    String key = _parseStringLiteral("Expect view key as string");
    String? title;
    String? description;
    
    if (_check(TokenType.string)) {
      title = _parseStringLiteral("Expect view title as string");
      
      if (_check(TokenType.string)) {
        description = _parseStringLiteral("Expect view description as string");
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
            "Unexpected token in container view: ${_current.lexeme}",
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
      includes: includes,
      excludes: excludes,
      autoLayout: autoLayout,
      animations: animations,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a component view.
  ComponentViewNode _parseComponentView() {
    final sourcePosition = _current.position;
    
    String containerId = _parseIdentifierOrString("Expect container identifier");
    String key = _parseStringLiteral("Expect view key as string");
    String? title;
    String? description;
    
    if (_check(TokenType.string)) {
      title = _parseStringLiteral("Expect view title as string");
      
      if (_check(TokenType.string)) {
        description = _parseStringLiteral("Expect view description as string");
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
            "Unexpected token in component view: ${_current.lexeme}",
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
      includes: includes,
      excludes: excludes,
      autoLayout: autoLayout,
      animations: animations,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a dynamic view.
  DynamicViewNode _parseDynamicView() {
    final sourcePosition = _current.position;
    
    String? scope;
    
    if (!_check(TokenType.string)) {
      scope = _parseIdentifierOrString("Expect optional scope identifier");
    }
    
    String key = _parseStringLiteral("Expect view key as string");
    String? title;
    String? description;
    
    if (_check(TokenType.string)) {
      title = _parseStringLiteral("Expect view title as string");
      
      if (_check(TokenType.string)) {
        description = _parseStringLiteral("Expect view description as string");
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
        } else if (_check(TokenType.identifier) && _peekNext().type == TokenType.arrow) {
          // This is a relationship step in a dynamic view
          // For simplicity, we'll just add it as an animation step
          _parseImplicitRelationship();
        } else {
          _errorReporter.reportStandardError(
            "Unexpected token in dynamic view: ${_current.lexeme}",
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
      scope: scope,
      title: title,
      description: description,
      includes: includes,
      excludes: excludes,
      autoLayout: autoLayout,
      animations: animations,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a deployment view.
  DeploymentViewNode _parseDeploymentView() {
    final sourcePosition = _current.position;
    
    String systemId = _parseIdentifierOrString("Expect system identifier");
    String environment = _parseStringLiteral("Expect environment name as string");
    String key = _parseStringLiteral("Expect view key as string");
    String? title;
    String? description;
    
    if (_check(TokenType.string)) {
      title = _parseStringLiteral("Expect view title as string");
      
      if (_check(TokenType.string)) {
        description = _parseStringLiteral("Expect view description as string");
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
            "Unexpected token in deployment view: ${_current.lexeme}",
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
      systemId: systemId,
      environment: environment,
      title: title,
      description: description,
      includes: includes,
      excludes: excludes,
      autoLayout: autoLayout,
      animations: animations,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a filtered view.
  FilteredViewNode _parseFilteredView() {
    final sourcePosition = _current.position;
    
    String baseViewKey = _parseIdentifierOrString("Expect base view key");
    String key = _parseStringLiteral("Expect view key as string");
    String? title;
    String? description;
    
    if (_check(TokenType.string)) {
      title = _parseStringLiteral("Expect view title as string");
      
      if (_check(TokenType.string)) {
        description = _parseStringLiteral("Expect view description as string");
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
            "Unexpected token in filtered view: ${_current.lexeme}",
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
      title: title,
      description: description,
      includes: includes,
      excludes: excludes,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a custom view.
  CustomViewNode _parseCustomView() {
    final sourcePosition = _current.position;
    
    String key = _parseStringLiteral("Expect view key as string");
    String? title;
    String? description;
    
    if (_check(TokenType.string)) {
      title = _parseStringLiteral("Expect view title as string");
      
      if (_check(TokenType.string)) {
        description = _parseStringLiteral("Expect view description as string");
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
            "Unexpected token in custom view: ${_current.lexeme}",
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
      includes: includes,
      excludes: excludes,
      autoLayout: autoLayout,
      animations: animations,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses an image view.
  ImageViewNode _parseImageView() {
    final sourcePosition = _current.position;
    
    String imageType = _parseIdentifierOrString("Expect image type");
    String key = _parseStringLiteral("Expect view key as string");
    String? title;
    String? description;
    String content = '';
    
    if (_check(TokenType.string)) {
      title = _parseStringLiteral("Expect view title as string");
      
      if (_check(TokenType.string)) {
        description = _parseStringLiteral("Expect view description as string");
      }
    }
    
    if (_match(TokenType.leftBrace)) {
      _pushContext(_ParsingContext.view);
      
      // For simplicity, just consume everything until the closing brace
      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_check(TokenType.string)) {
          content = _parseStringLiteral("Expect image content as string");
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
      imageType: imageType,
      content: content,
      title: title,
      description: description,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses an include statement.
  IncludeNode _parseInclude() {
    final sourcePosition = _current.position;
    
    String expression = _parseIdentifierOrString("Expect include expression");
    
    return IncludeNode(
      expression: expression,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses an exclude statement.
  ExcludeNode _parseExclude() {
    final sourcePosition = _current.position;
    
    String expression = _parseIdentifierOrString("Expect exclude expression");
    
    return ExcludeNode(
      expression: expression,
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
      rankDirection = _parseStringLiteral("Expect rank direction as string");
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
      rankDirection: rankDirection,
      rankSeparation: rankSeparation,
      nodeSeparation: nodeSeparation,
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
      
      _consume(TokenType.rightBrace, "Expect '}' after animation step definition");
    }
    
    return AnimationNode(
      order: order,
      elements: elements,
      relationships: relationships,
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
      } else if (_match(TokenType.identifier) && _current.lexeme == 'relationship') {
        relationshipStyles.add(_parseRelationshipStyle());
      } else {
        _errorReporter.reportStandardError(
          "Unexpected token in styles: ${_current.lexeme}",
          _current.position.offset,
        );
        _advance();
      }
    }
    
    _consume(TokenType.rightBrace, "Expect '}' after styles definition");
    
    _popContext();
    
    return StylesNode(
      elementStyles: elementStyles,
      relationshipStyles: relationshipStyles,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses an element style.
  ElementStyleNode _parseElementStyle() {
    final sourcePosition = _current.position;
    
    String tag = _parseStringLiteral("Expect element tag as string");
    
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
        final property = _parseIdentifierOrString("Expect style property name");
        
        if (property == 'shape') {
          shape = _parseStringLiteral("Expect shape value as string");
        } else if (property == 'icon') {
          icon = _parseStringLiteral("Expect icon value as string");
        } else if (property == 'width') {
          width = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'height') {
          height = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'background') {
          background = _parseStringLiteral("Expect background color as string");
        } else if (property == 'stroke') {
          stroke = _parseStringLiteral("Expect stroke color as string");
        } else if (property == 'color') {
          color = _parseStringLiteral("Expect text color as string");
        } else if (property == 'fontSize') {
          fontSize = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'border') {
          border = _parseStringLiteral("Expect border style as string");
        } else if (property == 'opacity') {
          opacity = double.parse(_current.lexeme);
          _advance();
        } else {
          // Custom metadata property
          final value = _parseStringLiteral("Expect property value as string");
          metadata[property] = value;
        }
      }
      
      _consume(TokenType.rightBrace, "Expect '}' after element style definition");
      _popContext();
    }
    
    return ElementStyleNode(
      tag: tag,
      shape: shape,
      icon: icon,
      width: width,
      height: height,
      background: background,
      stroke: stroke,
      color: color,
      fontSize: fontSize,
      border: border,
      opacity: opacity,
      metadata: metadata,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a relationship style.
  RelationshipStyleNode _parseRelationshipStyle() {
    final sourcePosition = _current.position;
    
    String tag = _parseStringLiteral("Expect relationship tag as string");
    
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
        final property = _parseIdentifierOrString("Expect style property name");
        
        if (property == 'thickness') {
          thickness = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'color') {
          color = _parseStringLiteral("Expect color value as string");
        } else if (property == 'style') {
          style = _parseStringLiteral("Expect style value as string");
        } else if (property == 'routing') {
          routing = _parseStringLiteral("Expect routing value as string");
        } else if (property == 'fontSize') {
          fontSize = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'width') {
          width = int.parse(_current.lexeme);
          _advance();
        } else if (property == 'position') {
          position = _parseStringLiteral("Expect position value as string");
        } else if (property == 'opacity') {
          opacity = double.parse(_current.lexeme);
          _advance();
        } else {
          // Custom metadata property
          final value = _parseStringLiteral("Expect property value as string");
          metadata[property] = value;
        }
      }
      
      _consume(TokenType.rightBrace, "Expect '}' after relationship style definition");
      _popContext();
    }
    
    return RelationshipStyleNode(
      tag: tag,
      thickness: thickness,
      color: color,
      style: style,
      routing: routing,
      fontSize: fontSize,
      width: width,
      position: position,
      opacity: opacity,
      metadata: metadata,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a list of themes.
  List<ThemeNode> _parseThemes() {
    final themes = <ThemeNode>[];
    
    if (_check(TokenType.string)) {
      final url = _parseStringLiteral("Expect theme URL as string");
      themes.add(ThemeNode(
        url: url,
        sourcePosition: _current.position,
      ));
      
      while (_check(TokenType.comma)) {
        _advance(); // Consume comma
        final nextUrl = _parseStringLiteral("Expect theme URL as string");
        themes.add(ThemeNode(
          url: nextUrl,
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
      final property = _parseIdentifierOrString("Expect branding property name");
      
      if (property == 'logo') {
        logo = _parseStringLiteral("Expect logo URL as string");
      } else if (property == 'width') {
        width = int.parse(_current.lexeme);
        _advance();
      } else if (property == 'height') {
        height = int.parse(_current.lexeme);
        _advance();
      } else if (property == 'font') {
        font = _parseStringLiteral("Expect font name as string");
      } else {
        _errorReporter.reportStandardError(
          "Unexpected property in branding: $property",
          _current.position.offset,
        );
        _advance();
      }
    }
    
    _consume(TokenType.rightBrace, "Expect '}' after branding definition");
    
    _popContext();
    
    return BrandingNode(
      logo: logo,
      width: width,
      height: height,
      font: font,
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
      final term = _parseIdentifierOrString("Expect terminology term name");
      
      if (term == 'enterprise') {
        enterprise = _parseStringLiteral("Expect term value as string");
      } else if (term == 'person') {
        person = _parseStringLiteral("Expect term value as string");
      } else if (term == 'softwareSystem') {
        softwareSystem = _parseStringLiteral("Expect term value as string");
      } else if (term == 'container') {
        container = _parseStringLiteral("Expect term value as string");
      } else if (term == 'component') {
        component = _parseStringLiteral("Expect term value as string");
      } else if (term == 'code') {
        code = _parseStringLiteral("Expect term value as string");
      } else if (term == 'deploymentNode') {
        deploymentNode = _parseStringLiteral("Expect term value as string");
      } else if (term == 'relationship') {
        relationship = _parseStringLiteral("Expect term value as string");
      } else {
        _errorReporter.reportStandardError(
          "Unexpected term in terminology: $term",
          _current.position.offset,
        );
        _advance();
      }
    }
    
    _consume(TokenType.rightBrace, "Expect '}' after terminology definition");
    
    _popContext();
    
    return TerminologyNode(
      enterprise: enterprise,
      person: person,
      softwareSystem: softwareSystem,
      container: container,
      component: component,
      code: code,
      deploymentNode: deploymentNode,
      relationship: relationship,
      sourcePosition: sourcePosition,
    );
  }
  
  /// Parses a configuration section.
  Map<String, String> _parseConfiguration() {
    final config = <String, String>{};
    
    _pushContext(_ParsingContext.configuration);
    
    _consume(TokenType.leftBrace, "Expect '{' after configuration declaration");
    
    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      final key = _parseIdentifierOrString("Expect configuration key");
      final value = _parseStringLiteral("Expect configuration value as string");
      
      config[key] = value;
    }
    
    _consume(TokenType.rightBrace, "Expect '}' after configuration definition");
    
    _popContext();
    
    return config;
  }
  
  /// Parses a string literal.
  /// Uses error recovery to handle missing or invalid strings.
  String _parseStringLiteral(String errorMessage) {
    if (_check(TokenType.string)) {
      final value = _current.value as String;
      _advance();
      return value;
    }

    // If we have an identifier, treat it as if it were a string (common error)
    if (_check(TokenType.identifier)) {
      final value = _current.lexeme;
      _advance();

      _errorReporter.reportWarning(
        '$errorMessage (treating identifier "${value}" as a string literal)',
        _current.position.offset,
      );

      return value;
    }

    // Otherwise, report the error and try to recover
    _error(errorMessage);

    // Synchronize to next token and return a placeholder
    _synchronize();
    return '[missing string]';
  }

  /// Parses an identifier or string literal.
  /// Uses error recovery to handle missing or invalid identifiers/strings.
  String _parseIdentifierOrString(String errorMessage) {
    if (_check(TokenType.identifier)) {
      final value = _current.lexeme;
      _advance();
      return value;
    } else if (_check(TokenType.string)) {
      return _parseStringLiteral(errorMessage);
    }

    // Handle other value types as best we can
    if (_check(TokenType.integer) || _check(TokenType.double) || _check(TokenType.boolean)) {
      final value = _current.lexeme;
      _advance();

      _errorReporter.reportWarning(
        '$errorMessage (treating literal "${value}" as an identifier/string)',
        _current.position.offset,
      );

      return value;
    }

    // Otherwise, report the error and try to recover
    _error(errorMessage);

    // Synchronize to next token and return a placeholder
    _synchronize();
    return '[missing identifier]';
  }
  
  /// Advances to the next token.
  void _advance() {
    if (!_isAtEnd()) {
      _position++;
      _current = _tokens[_position];
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
           (type == TokenType.rightBrace && _isAtBlockEnd()); // Missing closing brace at logical block end
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

    while (!_isAtEnd()) {
      // Synchronize points based on context
      switch (context) {
        case _ParsingContext.workspace:
          // Synchronize to major section keywords
          if (_check(TokenType.model) ||
              _check(TokenType.views) ||
              _check(TokenType.styles) ||
              _check(TokenType.themes) ||
              _check(TokenType.branding) ||
              _check(TokenType.terminology) ||
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
              _check(TokenType.arrow) ||   // Relationship
              _check(TokenType.include) || // View specific
              _check(TokenType.exclude) ||
              _check(TokenType.autoLayout) ||
              _check(TokenType.animation) ||
              _check(TokenType.shape) ||   // Style specific
              _check(TokenType.color)) {
            return;
          }
          // If we have an identifier that might be the next valid element, return
          if (_check(TokenType.identifier) && _peekNext().type == TokenType.equals) {
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
      case _ParsingContext.workspace: return 'workspace';
      case _ParsingContext.model: return 'model';
      case _ParsingContext.element: return 'element';
      case _ParsingContext.views: return 'views';
      case _ParsingContext.view: return 'view';
      case _ParsingContext.styles: return 'styles';
      case _ParsingContext.style: return 'style';
      case _ParsingContext.branding: return 'branding';
      case _ParsingContext.terminology: return 'terminology';
      case _ParsingContext.configuration: return 'configuration';
      default: return 'unknown';
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
  void _pushContext(_ParsingContext context) {
    _contextStack.add(context);
  }
  
  /// Pops the current parsing context from the stack.
  void _popContext() {
    if (_contextStack.isNotEmpty) {
      _contextStack.removeLast();
    }
  }
  
  /// Returns the current parsing context.
  _ParsingContext get _currentContext {
    if (_contextStack.isEmpty) {
      return _ParsingContext.unknown;
    }
    return _contextStack.last;
  }
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
}