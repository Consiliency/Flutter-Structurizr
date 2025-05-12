import '../error_reporter.dart';

/// Enumeration of all possible token types in the Structurizr DSL.
enum TokenType {
  // Basic tokens
  eof,         // End of file
  error,       // Error token

  // Literals
  identifier,  // Identifiers (e.g., variable names)
  string,      // String literals
  integer,     // Integer literals
  double,      // Floating point literals
  boolean,     // Boolean literals (true/false)

  // Punctuation
  leftBrace,   // {
  rightBrace,  // }
  leftParen,   // (
  rightParen,  // )
  arrow,       // ->
  equals,      // =
  comma,       // ,
  colon,       // :
  dot,         // .
  semicolon,   // ;
  plus,        // +
  minus,       // -
  star,        // *
  slash,       // /
  hash,        // #
  at,          // @
  bang,        // !
  pipe,        // |

  // Keywords - Workspace level
  workspace,
  model,
  views,
  styles,
  themes,
  branding,
  configuration,
  terminology,

  // Keywords - Model elements
  person,
  softwareSystem,
  container,
  component,
  deploymentEnvironment,
  deploymentNode,
  infrastructureNode,
  group,
  enterprise,

  // Keywords - Container instance
  containerInstance,
  instances,

  // Keywords - Relationships
  relationship,
  ref,
  this_,       // 'this' keyword for self-reference

  // Keywords - Properties
  tags,
  description,
  technology,
  url,
  properties,
  perspectives,
  location,
  name,
  elements,

  // Keywords - Views
  systemLandscape,
  systemContext,
  containerView,
  componentView,
  dynamicView,
  deploymentView,
  filteredView,
  customView,
  imageView,

  // Keywords - View properties
  title,
  autoLayout,
  animation,
  include,
  exclude,
  key,

  // Keywords - Animation
  order,

  // Keywords - Dynamic view
  step,

  // Keywords - Layout
  rankDirection,
  rankSeparation,
  nodeSeparation,

  // Keywords - Styling
  shape,
  icon,
  color,
  background,
  stroke,
  fontSize,
  border,
  opacity,
  width,
  height,
  thickness,
  routing,
  position,

  // Styling shapes
  boxShape,
  circleShape,
  cylinderShape,
  ellipseShape,
  hexagonShape,
  folderShape,
  personShape,
  pipeShape,
  robotShape,
  roundedboxShape,
  webBrowserShape,

  // Directives
  identifiers, // For directives like !identifiers
}

/// A mapping of string keywords to their corresponding TokenType.
final Map<String, TokenType> keywords = {
  // Workspace level
  'workspace': TokenType.workspace,
  'model': TokenType.model,
  'views': TokenType.views,
  'styles': TokenType.styles,
  'themes': TokenType.themes,
  'branding': TokenType.branding,
  'configuration': TokenType.configuration,
  'terminology': TokenType.terminology,

  // Model elements
  'person': TokenType.person,
  'softwareSystem': TokenType.softwareSystem,
  'container': TokenType.container,
  'component': TokenType.component,
  'deploymentEnvironment': TokenType.deploymentEnvironment,
  'deploymentNode': TokenType.deploymentNode,
  'infrastructureNode': TokenType.infrastructureNode,
  'group': TokenType.group,
  'enterprise': TokenType.enterprise,

  // Container instance
  'containerInstance': TokenType.containerInstance,
  'instances': TokenType.instances,

  // Relationships
  'relationship': TokenType.relationship,
  'ref': TokenType.ref,
  'this': TokenType.this_,

  // Properties
  'tags': TokenType.tags,
  'description': TokenType.description,
  'technology': TokenType.technology,
  'url': TokenType.url,
  'properties': TokenType.properties,
  'perspectives': TokenType.perspectives,
  'location': TokenType.location,
  'name': TokenType.name,
  'elements': TokenType.elements,

  // Views
  'systemLandscape': TokenType.systemLandscape,
  'systemContext': TokenType.systemContext,
  'container': TokenType.containerView,
  'component': TokenType.componentView,
  'dynamic': TokenType.dynamicView,
  'deployment': TokenType.deploymentView,
  'filtered': TokenType.filteredView,
  'custom': TokenType.customView,
  'image': TokenType.imageView,

  // View properties
  'title': TokenType.title,
  'autoLayout': TokenType.autoLayout,
  'animation': TokenType.animation,
  'include': TokenType.include,
  'exclude': TokenType.exclude,
  'key': TokenType.key,

  // Animation
  'order': TokenType.order,

  // Dynamic view
  'step': TokenType.step,

  // Layout
  'rankDirection': TokenType.rankDirection,
  'rankSeparation': TokenType.rankSeparation,
  'nodeSeparation': TokenType.nodeSeparation,

  // Styling
  'shape': TokenType.shape,
  'icon': TokenType.icon,
  'color': TokenType.color,
  'background': TokenType.background,
  'stroke': TokenType.stroke,
  'fontSize': TokenType.fontSize,
  'border': TokenType.border,
  'opacity': TokenType.opacity,
  'width': TokenType.width,
  'height': TokenType.height,
  'thickness': TokenType.thickness,
  'routing': TokenType.routing,
  'position': TokenType.position,

  // Shapes
  'Box': TokenType.boxShape,
  'Circle': TokenType.circleShape,
  'Cylinder': TokenType.cylinderShape,
  'Ellipse': TokenType.ellipseShape,
  'Hexagon': TokenType.hexagonShape,
  'Folder': TokenType.folderShape,
  'Person': TokenType.personShape,
  'Pipe': TokenType.pipeShape,
  'Robot': TokenType.robotShape,
  'RoundedBox': TokenType.roundedboxShape,
  'WebBrowser': TokenType.webBrowserShape,

  // Directives
  'identifiers': TokenType.identifiers,

  // Boolean literals
  'true': TokenType.boolean,
  'false': TokenType.boolean,
};

/// Represents a single token in the Structurizr DSL.
class Token {
  /// The type of this token
  final TokenType type;

  /// The original text of this token
  final String lexeme;

  /// The position in the source code where this token starts
  final SourcePosition position;

  /// The value of this token (for literals)
  final Object? value;

  /// The line number where this token appears
  int get line => position.line;

  /// The column number where this token starts
  int get column => position.column;

  /// Creates a new token.
  Token({
    required this.type,
    required this.lexeme,
    required this.position,
    this.value,
  });

  /// Creates a copy of this token with a different type.
  Token copyWith({TokenType? type}) {
    return Token(
      type: type ?? this.type,
      lexeme: lexeme,
      position: position,
      value: value,
    );
  }

  @override
  String toString() {
    if (value != null) {
      return '$type: "$lexeme" ($value) at $position';
    }
    return '$type: "$lexeme" at $position';
  }
}