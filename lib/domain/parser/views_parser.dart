// Remove legacy AST imports
// import 'ast/ast_node.dart';
// import 'ast/nodes/view_node.dart';
// import 'ast/nodes/views_node.dart';
// Remove legacy node type references and prepare for new node structure
// Remove all references to ViewNode, ViewsNode, AstNode, and related types
import 'context_stack.dart';
import 'error_reporter.dart';
import 'lexer/token.dart';
import 'ast/nodes/views_node.dart';
import 'ast/nodes/view_node.dart';
import 'ast/nodes/system_landscape_view_node.dart';
import 'ast/nodes/system_context_view_node.dart';
import 'ast/nodes/container_view_node.dart';
import 'ast/nodes/component_view_node.dart';
import 'ast/nodes/dynamic_view_node.dart';
import 'ast/nodes/deployment_view_node.dart';
import 'ast/nodes/filtered_view_node.dart';
import 'ast/nodes/custom_view_node.dart';
import 'ast/nodes/image_view_node.dart';
import 'ast/nodes/include_node.dart';
import 'ast/nodes/exclude_node.dart';
import 'ast/nodes/auto_layout_node.dart';
import 'ast/nodes/animation_node.dart';
import 'ast/nodes/source_position.dart';

/// Parser for the views section of a Structurizr DSL workspace.
///
/// This parser handles all view definitions including system context views,
/// container views, component views, dynamic views, deployment views, filtered views,
/// and their properties like includes, excludes, auto layout, and animations.
class ViewsParser {
  /// Error reporter for reporting parsing errors.
  final ErrorReporter _errorReporter;

  /// Current position in the token stream.
  int _current = 0;

  /// The token stream to parse.
  late List<Token> _tokens;

  /// The context stack for keeping track of the parser context
  final ContextStack _contextStack;

  /// Creates a new views parser.
  ViewsParser(this._errorReporter) : _contextStack = ContextStack();

  /// Parses a views section in the DSL.
  ///
  /// This method processes the 'views' block in a Structurizr DSL workspace,
  /// parsing all the contained view definitions and returning a ViewsNode
  /// containing all the parsed views.
  ///
  /// @param tokens The token stream to parse.
  /// @return A ViewsNode containing all the parsed views.
  ViewsNode parse(List<Token> tokens) {
    _tokens = tokens;
    _current = 0;

    // Create an empty views node
    ViewsNode viewsNode = ViewsNode(
      position: _peek().position,
    );

    // Push the views context to the stack
    _contextStack.push(Context('views'));

    // Check if we have a views block
    if (_check(TokenType.views)) {
      _advance(); // Consume "views"

      // Handle views block opening brace
      if (_check(TokenType.leftBrace)) {
        _advance(); // Consume "{"

        // Parse view definitions until we hit the closing brace
        while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
          try {
            // Parse a view block and add it to the appropriate collection
            final viewNode = _parseViewBlock(_tokens.sublist(_current));

            // Advance the current position based on tokens consumed in _parseViewBlock
            // This is necessary because _parseViewBlock works on a sublist
            while (_current < _tokens.length &&
                _tokens[_current].position.offset <
                    ((viewNode.sourcePosition is SourcePosition)
                        ? (viewNode.sourcePosition as SourcePosition).offset
                        : 0) /* + viewNode.position!.length */) {
              _current++;
            }

            // Add the view to the appropriate collection based on its type
            if (viewNode is SystemLandscapeViewNode) {
              viewsNode = viewsNode
                  .addSystemLandscapeView(viewNode);
            } else if (viewNode is SystemContextViewNode) {
              viewsNode = viewsNode
                  .addSystemContextView(viewNode);
            } else if (viewNode is ContainerViewNode) {
              viewsNode =
                  viewsNode.addContainerView(viewNode);
            } else if (viewNode is ComponentViewNode) {
              // Add component view
              viewsNode = ViewsNode(
                position: viewsNode.position,
                systemLandscapeViews: viewsNode.systemLandscapeViews,
                systemContextViews: viewsNode.systemContextViews,
                containerViews: viewsNode.containerViews,
                componentViews: viewNode is ComponentViewNode
                    ? [
                        ...viewsNode.componentViews,
                        viewNode
                      ]
                    : viewsNode.componentViews,
                dynamicViews: viewsNode.dynamicViews,
                deploymentViews: viewsNode.deploymentViews,
                filteredViews: viewsNode.filteredViews,
                customViews: viewsNode.customViews,
                imageViews: viewsNode.imageViews,
                configuration: viewsNode.configuration,
              );
            } else if (viewNode is DynamicViewNode) {
              // Add dynamic view
              viewsNode = ViewsNode(
                position: viewsNode.position,
                systemLandscapeViews: viewsNode.systemLandscapeViews,
                systemContextViews: viewsNode.systemContextViews,
                containerViews: viewsNode.containerViews,
                componentViews: viewsNode.componentViews,
                dynamicViews: viewNode is DynamicViewNode
                    ? [...viewsNode.dynamicViews, viewNode]
                    : viewsNode.dynamicViews,
                deploymentViews: viewsNode.deploymentViews,
                filteredViews: viewsNode.filteredViews,
                customViews: viewsNode.customViews,
                imageViews: viewsNode.imageViews,
                configuration: viewsNode.configuration,
              );
            } else if (viewNode is DeploymentViewNode) {
              // Add deployment view
              viewsNode = ViewsNode(
                position: viewsNode.position,
                systemLandscapeViews: viewsNode.systemLandscapeViews,
                systemContextViews: viewsNode.systemContextViews,
                containerViews: viewsNode.containerViews,
                componentViews: viewsNode.componentViews,
                dynamicViews: viewsNode.dynamicViews,
                deploymentViews: viewNode is DeploymentViewNode
                    ? [
                        ...viewsNode.deploymentViews,
                        viewNode
                      ]
                    : viewsNode.deploymentViews,
                filteredViews: viewsNode.filteredViews,
                customViews: viewsNode.customViews,
                imageViews: viewsNode.imageViews,
                configuration: viewsNode.configuration,
              );
            } else if (viewNode is FilteredViewNode) {
              viewsNode =
                  viewsNode.addFilteredView(viewNode);
            } else if (viewNode is CustomViewNode) {
              // Add custom view
              viewsNode = ViewsNode(
                position: viewsNode.position,
                systemLandscapeViews: viewsNode.systemLandscapeViews,
                systemContextViews: viewsNode.systemContextViews,
                containerViews: viewsNode.containerViews,
                componentViews: viewsNode.componentViews,
                dynamicViews: viewsNode.dynamicViews,
                deploymentViews: viewsNode.deploymentViews,
                filteredViews: viewsNode.filteredViews,
                customViews: viewNode is CustomViewNode
                    ? [...viewsNode.customViews, viewNode]
                    : viewsNode.customViews,
                imageViews: viewsNode.imageViews,
                configuration: viewsNode.configuration,
              );
            } else if (viewNode is ImageViewNode) {
              // Add image view
              viewsNode = ViewsNode(
                position: viewsNode.position,
                systemLandscapeViews: viewsNode.systemLandscapeViews,
                systemContextViews: viewsNode.systemContextViews,
                containerViews: viewsNode.containerViews,
                componentViews: viewsNode.componentViews,
                dynamicViews: viewsNode.dynamicViews,
                deploymentViews: viewsNode.deploymentViews,
                filteredViews: viewsNode.filteredViews,
                customViews: viewsNode.customViews,
                imageViews: viewNode is ImageViewNode
                    ? [...viewsNode.imageViews, viewNode]
                    : viewsNode.imageViews,
                configuration: viewsNode.configuration,
              );
            }
          } catch (e) {
            // Report parsing error and try to continue
            _errorReporter.reportStandardError(
                'Error parsing view: ${e.toString()}', _peek().position.offset);

            // Skip to the next view definition or the end of the views block
            _synchronize();
          }
        }

        // Consume closing brace
        if (_check(TokenType.rightBrace)) {
          _advance();
        } else {
          _errorReporter.reportStandardError(
              'Expected "}" after views block', _peek().position.offset);
        }
      } else {
        _errorReporter.reportStandardError(
            'Expected "{" after views keyword', _peek().position.offset);
      }
    }

    // Pop the views context from the stack
    _contextStack.pop();

    return viewsNode;
  }

  /// Parses a view block and returns the appropriate view node.
  ///
  /// This method identifies the type of view (system context, container, etc.)
  /// and delegates to the appropriate view-specific parser.
  ///
  /// @param tokens The token stream to parse.
  /// @return A ViewNode of the appropriate type.
  dynamic _parseViewBlock(List<Token> tokens) {
    _tokens = tokens;
    _current = 0;

    final startPosition = _peek().position;

    // Push a view block context to the stack
    _contextStack.push(Context('viewBlock'));

    // Determine view type
    if (_check(TokenType.systemLandscape)) {
      return _parseSystemLandscapeView(startPosition);
    } else if (_check(TokenType.systemContext)) {
      return _parseSystemContextView(startPosition);
    } else if (_check(TokenType.container)) {
      return _parseContainerView(startPosition);
    } else if (_check(TokenType.component)) {
      return _parseComponentView(startPosition);
    } else if (_check(TokenType.dynamicView)) {
      return _parseDynamicView(startPosition);
    } else if (_check(TokenType.deploymentView)) {
      return _parseDeploymentView(startPosition);
    } else if (_check(TokenType.filteredView)) {
      return _parseFilteredView(startPosition);
    } else if (_check(TokenType.customView)) {
      return _parseCustomView(startPosition);
    } else if (_check(TokenType.imageView)) {
      return _parseImageView(startPosition);
    } else {
      _errorReporter.reportStandardError(
          'Expected view type', _peek().position.offset);
      _contextStack.pop(); // Pop the view block context
      throw Exception('Expected view type');
    }
  }

  /// Parses a system landscape view.
  ///
  /// A system landscape view shows all of the software systems and people in a
  /// given environment, optionally filtered by a set of include/exclude tags.
  ///
  /// @param startPosition The position of the view definition.
  /// @return A SystemLandscapeViewNode representing the parsed view.
  SystemLandscapeViewNode _parseSystemLandscapeView(
      SourcePosition startPosition) {
    // Push system landscape view context to the stack
    _contextStack.push(Context('systemLandscapeView'));
    _advance(); // Consume "systemLandscape"

    // Parse view key
    String key = _parseIdentifier('view key');

    // Parse title (required)
    String title = _parseStringLiteral('view title');

    // Parse optional description
    String? description;
    if (_check(TokenType.string)) {
      description = _parseStringLiteral('view description');
    }

    // Prepare view node with basic properties
    SystemLandscapeViewNode viewNode = SystemLandscapeViewNode(
      key: key,
      title: title,
      description: description,
      sourcePosition: startPosition,
    );

    // Parse view body if present
    if (_check(TokenType.leftBrace)) {
      viewNode = _parseViewBody(viewNode) as SystemLandscapeViewNode;
    }

    // Pop system landscape view context from the stack
    _contextStack.pop();

    return viewNode;
  }

  /// Parses a system context view.
  ///
  /// A system context view shows a specific software system in the context of the
  /// people and other software systems that interact with it.
  ///
  /// @param startPosition The position of the view definition.
  /// @return A SystemContextViewNode representing the parsed view.
  SystemContextViewNode _parseSystemContextView(SourcePosition startPosition) {
    // Push system context view context to the stack
    _contextStack.push(Context('systemContextView'));
    _advance(); // Consume "systemContext"

    // Parse system ID
    String systemId = _parseIdentifier('system identifier');

    // Parse view key (the same as system ID by default)
    String key = systemId;

    // Parse title (required)
    String title = _parseStringLiteral('view title');

    // Parse optional description
    String? description;
    if (_check(TokenType.string)) {
      description = _parseStringLiteral('view description');
    }

    // Prepare view node with basic properties
    SystemContextViewNode viewNode = SystemContextViewNode(
      key: key,
      systemId: systemId,
      title: title,
      description: description,
      sourcePosition: startPosition,
    );

    // Parse view body if present
    if (_check(TokenType.leftBrace)) {
      viewNode = _parseViewBody(viewNode) as SystemContextViewNode;
    }

    // Pop system context view context from the stack
    _contextStack.pop();

    return viewNode;
  }

  /// Parses a container view.
  ///
  /// A container view shows the containers that make up a specific software system.
  ///
  /// @param startPosition The position of the view definition.
  /// @return A ContainerViewNode representing the parsed view.
  ContainerViewNode _parseContainerView(SourcePosition startPosition) {
    // Push container view context to the stack
    _contextStack.push(Context('containerView'));
    _advance(); // Consume "containerView"

    // Parse system ID
    String systemId = _parseIdentifier('system identifier');

    // Parse view key (the same as system ID by default)
    String key = systemId;

    // Parse title (required)
    String title = _parseStringLiteral('view title');

    // Parse optional description
    String? description;
    if (_check(TokenType.string)) {
      description = _parseStringLiteral('view description');
    }

    // Prepare view node with basic properties
    ContainerViewNode viewNode = ContainerViewNode(
      key: key,
      systemId: systemId,
      title: title,
      description: description,
      sourcePosition: startPosition,
    );

    // Parse view body if present
    if (_check(TokenType.leftBrace)) {
      viewNode = _parseViewBody(viewNode) as ContainerViewNode;
    }

    // Pop container view context from the stack
    _contextStack.pop();

    return viewNode;
  }

  /// Parses a component view.
  ///
  /// A component view shows the components that make up a specific container.
  ///
  /// @param startPosition The position of the view definition.
  /// @return A ComponentViewNode representing the parsed view.
  ComponentViewNode _parseComponentView(SourcePosition startPosition) {
    // Push component view context to the stack
    _contextStack.push(Context('componentView'));
    _advance(); // Consume "componentView"

    // Parse container ID
    String containerId = _parseIdentifier('container identifier');

    // Parse view key (the same as container ID by default)
    String key = containerId;

    // Parse title (required)
    String title = _parseStringLiteral('view title');

    // Parse optional description
    String? description;
    if (_check(TokenType.string)) {
      description = _parseStringLiteral('view description');
    }

    // Prepare view node with basic properties
    ComponentViewNode viewNode = ComponentViewNode(
      key: key,
      containerId: containerId,
      title: title,
      description: description,
      sourcePosition: startPosition,
    );

    // Parse view body if present
    if (_check(TokenType.leftBrace)) {
      viewNode = _parseViewBody(viewNode) as ComponentViewNode;
    }

    // Pop component view context from the stack
    _contextStack.pop();

    return viewNode;
  }

  /// Parses a dynamic view.
  ///
  /// A dynamic view shows a sequence of interactions between elements for a use case or user story.
  ///
  /// @param startPosition The position of the view definition.
  /// @return A DynamicViewNode representing the parsed view.
  DynamicViewNode _parseDynamicView(SourcePosition startPosition) {
    // Push dynamic view context to the stack
    _contextStack.push(Context('dynamicView'));
    _advance(); // Consume "dynamic"

    // Parse optional scope
    String? scope;
    if (!_check(TokenType.string) && !_check(TokenType.leftBrace)) {
      scope = _parseIdentifier('scope');
    }

    // Parse view key (auto-generated if scope is present)
    String key = scope ?? 'dynamic';

    // Parse title (required)
    String title = _parseStringLiteral('view title');

    // Parse optional description
    String? description;
    if (_check(TokenType.string)) {
      description = _parseStringLiteral('view description');
    }

    // Prepare view node with basic properties
    DynamicViewNode viewNode = DynamicViewNode(
      key: key,
      description: description,
      sourcePosition: startPosition,
    );

    // Parse view body if present
    if (_check(TokenType.leftBrace)) {
      viewNode = _parseViewBody(viewNode) as DynamicViewNode;
    }

    // Pop dynamic view context from the stack
    _contextStack.pop();

    return viewNode;
  }

  /// Parses a deployment view.
  ///
  /// A deployment view shows how containers are mapped to deployment nodes in a specific environment.
  ///
  /// @param startPosition The position of the view definition.
  /// @return A DeploymentViewNode representing the parsed view.
  DeploymentViewNode _parseDeploymentView(SourcePosition startPosition) {
    // Push deployment view context to the stack
    _contextStack.push(Context('deploymentView'));
    _advance(); // Consume "deployment"

    // Parse system ID
    String systemId = _parseIdentifier('system identifier');

    // Parse environment
    String environment = _parseIdentifier('environment');

    // Parse view key (auto-generated if not provided)
    String key = '${systemId}_${environment}';

    // Parse title (required)
    String title = _parseStringLiteral('view title');

    // Parse optional description
    String? description;
    if (_check(TokenType.string)) {
      description = _parseStringLiteral('view description');
    }

    // Prepare view node with basic properties
    DeploymentViewNode viewNode = DeploymentViewNode(
      key: key,
      environment: environment,
      title: title,
      description: description,
      sourcePosition: startPosition,
    );

    // Parse view body if present
    if (_check(TokenType.leftBrace)) {
      viewNode = _parseViewBody(viewNode) as DeploymentViewNode;
    }

    // Pop deployment view context from the stack
    _contextStack.pop();

    return viewNode;
  }

  /// Parses a filtered view.
  ///
  /// A filtered view is a view based on another view, but with elements
  /// filtered by a set of include/exclude tags.
  ///
  /// @param startPosition The position of the view definition.
  /// @return A FilteredViewNode representing the parsed view.
  FilteredViewNode _parseFilteredView(SourcePosition startPosition) {
    // Push filtered view context to the stack
    _contextStack.push(Context('filteredView'));
    _advance(); // Consume "filteredView"

    // Parse view key
    String key = _parseStringLiteral('view key');

    // Base view key will be set in the view body
    String baseViewKey = '';

    // Parse optional title and description
    String? title;
    String? description;

    if (_check(TokenType.string)) {
      title = _parseStringLiteral('view title');

      if (_check(TokenType.string)) {
        description = _parseStringLiteral('view description');
      }
    }

    // Create initial filtered view node
    FilteredViewNode viewNode = FilteredViewNode(
      key: key,
      baseViewKey: baseViewKey, // Will be set in _parseViewBody
      description: description,
      sourcePosition: startPosition,
      mode: 'include',
    );

    // Parse view body if present
    if (_check(TokenType.leftBrace)) {
      _advance(); // Consume "{"

      // Parse view contents until closing brace
      while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
        if (_check(TokenType.identifier) && _peek().lexeme == 'baseOn') {
          _advance(); // Consume "baseOn"
          String baseOn = _parseStringLiteral('base view key');

          // Update the base view key
          viewNode = FilteredViewNode(
            key: viewNode.key,
            baseViewKey: baseOn,
            description: viewNode.description,
            sourcePosition: viewNode.sourcePosition,
            mode: 'include',
          );
        } else if (_check(TokenType.include)) {
          IncludeNode includeNode = _parseInclude();

          // Add include to view
          viewNode = FilteredViewNode(
            key: viewNode.key,
            baseViewKey: viewNode.baseViewKey,
            description: viewNode.description,
            sourcePosition: viewNode.sourcePosition,
            mode: 'include',
          );
        } else if (_check(TokenType.exclude)) {
          ExcludeNode excludeNode = _parseExclude();

          // Add exclude to view
          viewNode = FilteredViewNode(
            key: viewNode.key,
            baseViewKey: viewNode.baseViewKey,
            description: viewNode.description,
            sourcePosition: viewNode.sourcePosition,
            mode: 'include',
          );
        } else if (_check(TokenType.title)) {
          ViewPropertyNode property =
              _parseViewProperty(_tokens.sublist(_current));

          // Update title
          viewNode = FilteredViewNode(
            key: viewNode.key,
            baseViewKey: viewNode.baseViewKey,
            description: viewNode.description,
            sourcePosition: viewNode.sourcePosition,
            mode: 'include',
          );
        } else if (_check(TokenType.description)) {
          ViewPropertyNode property =
              _parseViewProperty(_tokens.sublist(_current));

          // Update description
          viewNode = FilteredViewNode(
            key: viewNode.key,
            baseViewKey: viewNode.baseViewKey,
            description: property.value,
            sourcePosition: viewNode.sourcePosition,
            mode: 'include',
          );
        } else {
          _errorReporter.reportStandardError(
              'Unexpected token in filtered view body',
              _peek().position.offset);
          _advance(); // Skip the unexpected token
        }
      }

      // Consume closing brace
      if (_check(TokenType.rightBrace)) {
        _advance();
      } else {
        _errorReporter.reportStandardError(
            'Expected "}" after filtered view body', _peek().position.offset);
      }
    }

    // Validate filtered view properties
    if (viewNode.baseViewKey.isEmpty) {
      _errorReporter.reportStandardError(
          'Filtered view must specify "baseOn" property', startPosition.offset);
    }

    // Pop filtered view context from the stack
    _contextStack.pop();

    return viewNode;
  }

  /// Parses a custom view.
  ///
  /// A custom view allows creating arbitrary diagrams that aren't based on any specific model element.
  ///
  /// @param startPosition The position of the view definition.
  /// @return A CustomViewNode representing the parsed view.
  CustomViewNode _parseCustomView(SourcePosition startPosition) {
    // Push custom view context to the stack
    _contextStack.push(Context('customView'));
    _advance(); // Consume "custom"

    // Parse view key
    String key = _parseIdentifier('view key');

    // Parse title (required)
    String title = _parseStringLiteral('view title');

    // Parse optional description
    String? description;
    if (_check(TokenType.string)) {
      description = _parseStringLiteral('view description');
    }

    // Prepare view node with basic properties
    CustomViewNode viewNode = CustomViewNode(
      key: key,
      title: title,
      description: description,
      sourcePosition: startPosition,
    );

    // Parse view body if present
    if (_check(TokenType.leftBrace)) {
      viewNode = _parseViewBody(viewNode) as CustomViewNode;
    }

    // Pop custom view context from the stack
    _contextStack.pop();

    return viewNode;
  }

  /// Parses an image view.
  ///
  /// An image view represents an externally created image to be included in the documentation.
  ///
  /// @param startPosition The position of the view definition.
  /// @return An ImageViewNode representing the parsed view.
  ImageViewNode _parseImageView(SourcePosition startPosition) {
    // Push image view context to the stack
    _contextStack.push(Context('imageView'));
    _advance(); // Consume "image"

    // Parse view key
    String key = _parseIdentifier('view key');

    // Parse image content
    String content = _parseStringLiteral('image content');

    // Parse optional description
    String? description;
    if (_check(TokenType.string)) {
      description = _parseStringLiteral('view description');
    }

    // Create image view node
    ImageViewNode viewNode = ImageViewNode(
      key: key,
      imagePath: content,
      description: description,
      sourcePosition: startPosition,
    );

    // Pop image view context from the stack
    _contextStack.pop();

    return viewNode;
  }

  /// Parses the body of a view.
  ///
  /// This method handles the common elements inside a view definition block,
  /// such as include/exclude statements, auto layout, animations, etc.
  ///
  /// @param viewNode The view node to update with the parsed body elements.
  /// @return The updated view node.
  dynamic _parseViewBody(dynamic viewNode) {
    _advance(); // Consume "{"

    // Lists to accumulate elements
    List<IncludeNode> includes = (viewNode is SystemContextViewNode)
        ? List<IncludeNode>.from((viewNode).includes)
        : [];
    List<ExcludeNode> excludes = (viewNode is SystemContextViewNode)
        ? List<ExcludeNode>.from((viewNode).excludes)
        : [];
    List<AnimationNode> animations = (viewNode is SystemContextViewNode)
        ? List<AnimationNode>.from(
            (viewNode).animations)
        : [];
    AutoLayoutNode? autoLayout = (viewNode is SystemContextViewNode)
        ? (viewNode).autoLayout as AutoLayoutNode?
        : null;

    // Parse view contents until closing brace
    while (!_check(TokenType.rightBrace) && !_isAtEnd()) {
      print('DEBUG: [ViewsParser] Parsing view body token: ${_peek().type} "${_peek().lexeme}"');
      if (_check(TokenType.include)) {
        print('DEBUG: [ViewsParser] Found include token, parsing include directive');
        IncludeNode includeNode = _parseInclude();
        print('DEBUG: [ViewsParser] Parsed include: "${includeNode.path}"');
        includes.add(includeNode);
      } else if (_check(TokenType.exclude)) {
        ExcludeNode excludeNode = _parseExclude();
        excludes.add(excludeNode);
      } else if (_check(TokenType.autoLayout)) {
        autoLayout = _parseAutoLayout();
      } else if (_check(TokenType.animation)) {
        AnimationNode animationNode = _parseAnimation(animations.length);
        animations.add(animationNode);
      } else if (_check(TokenType.title)) {
        ViewPropertyNode property =
            _parseViewProperty(_tokens.sublist(_current));

        // Update title based on property
        viewNode = _updateViewNodeProperty(viewNode, 'title', property.value);
      } else if (_check(TokenType.description)) {
        ViewPropertyNode property =
            _parseViewProperty(_tokens.sublist(_current));

        // Update description based on property
        viewNode =
            _updateViewNodeProperty(viewNode, 'description', property.value);
      } else {
        _errorReporter.reportStandardError(
            'Unexpected token in view body', _peek().position.offset);
        _advance(); // Skip the unexpected token
      }
    }

    // Consume closing brace
    if (_check(TokenType.rightBrace)) {
      _advance();
    } else {
      _errorReporter.reportStandardError(
          'Expected "}" after view body', _peek().position.offset);
    }

    // Create updated view node with all collected elements
    return _updateViewNodeElements(
        viewNode, includes, excludes, autoLayout, animations);
  }

  /// Updates a view node with a new property value.
  dynamic _updateViewNodeProperty(
      dynamic viewNode, String propertyName, String value) {
    if (viewNode is SystemLandscapeViewNode) {
      if (propertyName == 'title') {
        return SystemLandscapeViewNode(
          key: viewNode.key,
          title: value,
          description: viewNode.description,
          sourcePosition: viewNode.sourcePosition,
        );
      } else if (propertyName == 'description') {
        return SystemLandscapeViewNode(
          key: viewNode.key,
          title: viewNode.title,
          description: value,
          sourcePosition: viewNode.sourcePosition,
        );
      }
    } else if (viewNode is SystemContextViewNode) {
      if (propertyName == 'title') {
        return SystemContextViewNode(
          key: viewNode.key,
          systemId: viewNode.systemId,
          title: value,
          description: viewNode.description,
          sourcePosition: viewNode.sourcePosition,
        );
      } else if (propertyName == 'description') {
        return SystemContextViewNode(
          key: viewNode.key,
          systemId: viewNode.systemId,
          title: viewNode.title,
          description: value,
          sourcePosition: viewNode.sourcePosition,
        );
      }
    } else if (viewNode is ContainerViewNode) {
      if (propertyName == 'title') {
        return ContainerViewNode(
          key: viewNode.key,
          systemId: viewNode.systemId,
          title: value,
          description: viewNode.description,
          sourcePosition: viewNode.sourcePosition,
        );
      } else if (propertyName == 'description') {
        return ContainerViewNode(
          key: viewNode.key,
          systemId: viewNode.systemId,
          title: viewNode.title,
          description: value,
          sourcePosition: viewNode.sourcePosition,
        );
      }
    } else if (viewNode is ComponentViewNode) {
      if (propertyName == 'title') {
        return ComponentViewNode(
          key: viewNode.key,
          containerId: viewNode.containerId,
          title: value,
          description: viewNode.description,
          sourcePosition: viewNode.sourcePosition,
        );
      } else if (propertyName == 'description') {
        return ComponentViewNode(
          key: viewNode.key,
          containerId: viewNode.containerId,
          title: viewNode.title,
          description: value,
          sourcePosition: viewNode.sourcePosition,
        );
      }
    } else if (viewNode is DynamicViewNode) {
      if (propertyName == 'title') {
        return DynamicViewNode(
          key: viewNode.key,
          description: viewNode.description,
          sourcePosition: viewNode.sourcePosition,
        );
      } else if (propertyName == 'description') {
        return DynamicViewNode(
          key: viewNode.key,
          description: value,
          sourcePosition: viewNode.sourcePosition,
        );
      }
    } else if (viewNode is DeploymentViewNode) {
      if (propertyName == 'title') {
        return DeploymentViewNode(
          key: viewNode.key,
          environment: viewNode.environment,
          title: value,
          description: viewNode.description,
          sourcePosition: viewNode.sourcePosition,
        );
      } else if (propertyName == 'description') {
        return DeploymentViewNode(
          key: viewNode.key,
          environment: viewNode.environment,
          title: viewNode.title,
          description: value,
          sourcePosition: viewNode.sourcePosition,
        );
      }
    } else if (viewNode is CustomViewNode) {
      if (propertyName == 'title') {
        return CustomViewNode(
          key: viewNode.key,
          title: value,
          description: viewNode.description,
          sourcePosition: viewNode.sourcePosition,
        );
      } else if (propertyName == 'description') {
        return CustomViewNode(
          key: viewNode.key,
          title: viewNode.title,
          description: value,
          sourcePosition: viewNode.sourcePosition,
        );
      }
    }

    return viewNode;
  }

  /// Updates a view node with collected elements (includes, excludes, etc.).
  dynamic _updateViewNodeElements(
      dynamic viewNode,
      List<IncludeNode> includes,
      List<ExcludeNode> excludes,
      AutoLayoutNode? autoLayout,
      List<AnimationNode> animations) {
    if (viewNode is SystemLandscapeViewNode) {
      return SystemLandscapeViewNode(
        key: viewNode.key,
        title: viewNode.title,
        description: viewNode.description,
        sourcePosition: viewNode.sourcePosition,
      );
    } else if (viewNode is SystemContextViewNode) {
      return SystemContextViewNode(
        key: viewNode.key,
        systemId: viewNode.systemId,
        title: viewNode.title,
        description: viewNode.description,
        sourcePosition: viewNode.sourcePosition,
      );
    } else if (viewNode is ContainerViewNode) {
      return ContainerViewNode(
        key: viewNode.key,
        systemId: viewNode.systemId,
        title: viewNode.title,
        description: viewNode.description,
        sourcePosition: viewNode.sourcePosition,
      );
    } else if (viewNode is ComponentViewNode) {
      return ComponentViewNode(
        key: viewNode.key,
        containerId: viewNode.containerId,
        title: viewNode.title,
        description: viewNode.description,
        sourcePosition: viewNode.sourcePosition,
      );
    } else if (viewNode is DynamicViewNode) {
      return DynamicViewNode(
        key: viewNode.key,
        description: viewNode.description,
        sourcePosition: viewNode.sourcePosition,
      );
    } else if (viewNode is DeploymentViewNode) {
      return DeploymentViewNode(
        key: viewNode.key,
        environment: viewNode.environment,
        title: viewNode.title,
        description: viewNode.description,
        sourcePosition: viewNode.sourcePosition,
      );
    } else if (viewNode is CustomViewNode) {
      return CustomViewNode(
        key: viewNode.key,
        title: viewNode.title,
        description: viewNode.description,
        sourcePosition: viewNode.sourcePosition,
      );
    }

    return viewNode;
  }

  /// Parses an include statement.
  IncludeNode _parseInclude() {
    _advance(); // Consume "include"

    String expression;
    if (_check(TokenType.identifier) ||
        (_check(TokenType.star) || _peek().lexeme == '*')) {
      expression = _advance().lexeme;
    } else if (_check(TokenType.string)) {
      expression = _parseStringLiteral('include expression');
    } else {
      _errorReporter.reportStandardError(
          'Expected identifier or * after include', _peek().position.offset);
      expression = '*'; // Default to including everything
    }

    return IncludeNode(
      path: expression,
      sourcePosition: _previous().position,
    );
  }

  /// Parses an exclude statement.
  ExcludeNode _parseExclude() {
    _advance(); // Consume "exclude"

    String expression;
    if (_check(TokenType.identifier) ||
        (_check(TokenType.star) || _peek().lexeme == '*')) {
      expression = _advance().lexeme;
    } else if (_check(TokenType.string)) {
      expression = _parseStringLiteral('exclude expression');
    } else {
      _errorReporter.reportStandardError(
          'Expected identifier or * after exclude', _peek().position.offset);
      expression = ''; // Empty expression
    }

    return ExcludeNode(
      pattern: expression,
      sourcePosition: _previous().position,
    );
  }

  /// Parses an auto layout statement.
  AutoLayoutNode _parseAutoLayout() {
    final startPosition = _peek().position;
    _advance(); // Consume "autoLayout"

    return AutoLayoutNode(
      sourcePosition: startPosition,
    );
  }

  /// Parses an animation step.
  AnimationNode _parseAnimation(int order) {
    final startPosition = _peek().position;
    _advance(); // Consume "animation"

    return AnimationNode(
      sourcePosition: startPosition,
    );
  }

  /// Parses a view property.
  ///
  /// This method handles properties within a view definition, such as title, description, etc.
  ///
  /// @param tokens The token stream to parse.
  /// @return A ViewPropertyNode representing the parsed property.
  ViewPropertyNode _parseViewProperty(List<Token> tokens) {
    _tokens = tokens;
    _current = 0;

    final startPosition = _peek().position;

    String name = _advance().lexeme.toLowerCase(); // Normalize property name
    String value = _parseStringLiteral('property value');

    return ViewPropertyNode(
      name: name,
      value: value,
      sourcePosition: startPosition,
    );
  }

  /// Parses inheritance between views.
  ///
  /// This method handles 'extends' or 'baseOn' directives that establish inheritance
  /// relationships between views.
  ///
  /// @param tokens The token stream to parse.
  void _parseInheritance(List<Token> tokens) {
    // Push inheritance context to the stack
    _contextStack.push(Context('inheritance'));
    _tokens = tokens;
    _current = 0;

    if (_check(TokenType.identifier) && _peek().lexeme == 'extends') {
      _advance(); // Consume "extends"

      // Parse base view identifier
      if (_check(TokenType.identifier)) {
        String baseViewId = _advance().lexeme;
        // In a complete implementation, we would update the current view to extend the base view
      } else {
        _errorReporter.reportStandardError(
            'Expected identifier after extends', _peek().position.offset);
      }
    } else if (_check(TokenType.identifier) && _peek().lexeme == 'baseOn') {
      _advance(); // Consume "baseOn"

      // Parse base view key
      String baseViewKey;
      if (_check(TokenType.string)) {
        baseViewKey = _parseStringLiteral('base view key');
        // In a complete implementation, we would update the current view to be based on the base view
      } else {
        _errorReporter.reportStandardError(
            'Expected string literal after baseOn', _peek().position.offset);
      }
    } else {
      _errorReporter.reportStandardError(
          'Expected extends or baseOn', _peek().position.offset);
    }

    // Pop inheritance context from the stack
    _contextStack.pop();
  }

  /// Parses include/exclude statements in views.
  ///
  /// This method handles 'include' and 'exclude' statements that define
  /// what elements are shown or hidden in a view.
  ///
  /// @param tokens The token stream to parse.
  void _parseIncludeExclude(List<Token> tokens) {
    // Push include/exclude context to the stack
    _contextStack.push(Context('includeExclude'));
    _tokens = tokens;
    _current = 0;

    if (_check(TokenType.include)) {
      _parseInclude();
    } else if (_check(TokenType.exclude)) {
      _parseExclude();
    } else {
      _errorReporter.reportStandardError(
          'Expected include or exclude', _peek().position.offset);
    }

    // Pop include/exclude context from the stack
    _contextStack.pop();
  }

  /// Parses an identifier.
  String _parseIdentifier(String context) {
    if (_check(TokenType.identifier)) {
      return _advance().lexeme;
    } else {
      _errorReporter.reportStandardError(
          'Expected identifier for $context', _peek().position.offset);
      return ''; // Return empty string as a fallback
    }
  }

  /// Parses a string literal.
  String _parseStringLiteral(String context) {
    if (_check(TokenType.string)) {
      String value = _advance().lexeme;
      // Remove surrounding quotes
      return value.substring(1, value.length - 1);
    } else {
      _errorReporter.reportStandardError(
          'Expected string literal for $context', _peek().position.offset);
      return ''; // Return empty string as a fallback
    }
  }

  /// Synchronizes the parser after an error.
  void _synchronize() {
    _advance();

    while (!_isAtEnd()) {
      // Skip until we find a closing brace or a new view type
      if (_previous().type == TokenType.rightBrace) return;

      switch (_peek().type) {
        case TokenType.systemLandscape:
        case TokenType.systemContext:
        case TokenType.containerView:
        case TokenType.componentView:
        case TokenType.dynamicView:
        case TokenType.deploymentView:
        case TokenType.filteredView:
        case TokenType.customView:
        case TokenType.imageView:
          return;
        default:
          _advance();
      }
    }
  }

  /// Advances to the next token and returns the previous token.
  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  /// Returns the current token without consuming it.
  Token _peek() {
    return _tokens[_current];
  }

  /// Returns the previous token.
  Token _previous() {
    return _tokens[_current - 1];
  }

  /// Checks if the current token is of the specified type.
  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  /// Checks if we've reached the end of the token stream.
  bool _isAtEnd() {
    return _current >= _tokens.length ||
        _tokens[_current].type == TokenType.eof;
  }
}

/// Represents a property of a view in the Structurizr DSL.
///
/// This class captures a name-value property pair in a view definition,
/// such as title, description, or other configuration options.
class ViewPropertyNode {
  /// The name of the property.
  final String name;

  /// The value of the property.
  final String value;

  /// Creates a new view property node.
  ViewPropertyNode({
    required this.name,
    required this.value,
    SourcePosition? sourcePosition,
  });

  @override
  String toString() {
    return 'ViewPropertyNode{name: $name, value: $value}';
  }
}

/// Extension methods to help with testing and adding views to a ViewsNode.
extension ViewsNodeExtensions on ViewsNode {
  /// Adds a system landscape view to this ViewsNode.
  ViewsNode addSystemLandscapeView(SystemLandscapeViewNode view) {
    return ViewsNode(
      position: position,
      systemLandscapeViews: [...systemLandscapeViews, view],
      systemContextViews: systemContextViews,
      containerViews: containerViews,
      componentViews: componentViews,
      dynamicViews: dynamicViews,
      deploymentViews: deploymentViews,
      filteredViews: filteredViews,
      customViews: customViews,
      imageViews: imageViews,
      configuration: configuration,
    );
  }

  /// Adds a system context view to this ViewsNode.
  ViewsNode addSystemContextView(SystemContextViewNode view) {
    return ViewsNode(
      position: position,
      systemLandscapeViews: systemLandscapeViews,
      systemContextViews: [...systemContextViews, view],
      containerViews: containerViews,
      componentViews: componentViews,
      dynamicViews: dynamicViews,
      deploymentViews: deploymentViews,
      filteredViews: filteredViews,
      customViews: customViews,
      imageViews: imageViews,
      configuration: configuration,
    );
  }

  /// Adds a container view to this ViewsNode.
  ViewsNode addContainerView(ContainerViewNode view) {
    return ViewsNode(
      position: position,
      systemLandscapeViews: systemLandscapeViews,
      systemContextViews: systemContextViews,
      containerViews: [...containerViews, view],
      componentViews: componentViews,
      dynamicViews: dynamicViews,
      deploymentViews: deploymentViews,
      filteredViews: filteredViews,
      customViews: customViews,
      imageViews: imageViews,
      configuration: configuration,
    );
  }

  /// Adds a filtered view to this ViewsNode.
  ViewsNode addFilteredView(FilteredViewNode view) {
    return ViewsNode(
      position: position,
      systemLandscapeViews: systemLandscapeViews,
      systemContextViews: systemContextViews,
      containerViews: containerViews,
      componentViews: componentViews,
      dynamicViews: dynamicViews,
      deploymentViews: deploymentViews,
      filteredViews: [...filteredViews, view],
      customViews: customViews,
      imageViews: imageViews,
      configuration: configuration,
    );
  }

  /// Adds a view of any type to this ViewsNode.
  ViewsNode addView(ViewNode viewNode) {
    if (viewNode is SystemLandscapeViewNode) {
      return addSystemLandscapeView(viewNode as SystemLandscapeViewNode);
    } else if (viewNode is SystemContextViewNode) {
      return addSystemContextView(viewNode as SystemContextViewNode);
    } else if (viewNode is ContainerViewNode) {
      return addContainerView(viewNode as ContainerViewNode);
    } else if (viewNode is ComponentViewNode) {
      return ViewsNode(
        position: position,
        systemLandscapeViews: systemLandscapeViews,
        systemContextViews: systemContextViews,
        containerViews: containerViews,
        componentViews: [...componentViews, viewNode as ComponentViewNode],
        dynamicViews: dynamicViews,
        deploymentViews: deploymentViews,
        filteredViews: filteredViews,
        customViews: customViews,
        imageViews: imageViews,
        configuration: configuration,
      );
    } else if (viewNode is DynamicViewNode) {
      return ViewsNode(
        position: position,
        systemLandscapeViews: systemLandscapeViews,
        systemContextViews: systemContextViews,
        containerViews: containerViews,
        componentViews: componentViews,
        dynamicViews: [...dynamicViews, viewNode as DynamicViewNode],
        deploymentViews: deploymentViews,
        filteredViews: filteredViews,
        customViews: customViews,
        imageViews: imageViews,
        configuration: configuration,
      );
    } else if (viewNode is DeploymentViewNode) {
      return ViewsNode(
        position: position,
        systemLandscapeViews: systemLandscapeViews,
        systemContextViews: systemContextViews,
        containerViews: containerViews,
        componentViews: componentViews,
        dynamicViews: dynamicViews,
        deploymentViews: [...deploymentViews, viewNode as DeploymentViewNode],
        filteredViews: filteredViews,
        customViews: customViews,
        imageViews: imageViews,
        configuration: configuration,
      );
    } else if (viewNode is FilteredViewNode) {
      return addFilteredView(viewNode as FilteredViewNode);
    } else if (viewNode is CustomViewNode) {
      return ViewsNode(
        position: position,
        systemLandscapeViews: systemLandscapeViews,
        systemContextViews: systemContextViews,
        containerViews: containerViews,
        componentViews: componentViews,
        dynamicViews: dynamicViews,
        deploymentViews: deploymentViews,
        filteredViews: filteredViews,
        customViews: [...customViews, viewNode as CustomViewNode],
        imageViews: imageViews,
        configuration: configuration,
      );
    } else if (viewNode is ImageViewNode) {
      return ViewsNode(
        position: position,
        systemLandscapeViews: systemLandscapeViews,
        systemContextViews: systemContextViews,
        containerViews: containerViews,
        componentViews: componentViews,
        dynamicViews: dynamicViews,
        deploymentViews: deploymentViews,
        filteredViews: filteredViews,
        customViews: customViews,
        imageViews: [...imageViews, viewNode as ImageViewNode],
        configuration: configuration,
      );
    }

    // Default case - just return the original node
    return this;
  }
}
