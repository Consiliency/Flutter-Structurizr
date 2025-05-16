import '../../error_reporter.dart';
import '../ast_base.dart';

/// A node representing a workspace.
class WorkspaceNode extends AstNode {
  /// The name of the workspace.
  final String name;
  
  /// The description of the workspace.
  final String? description;
  
  /// The model section of the workspace.
  final ModelNode? model;
  
  /// The views section of the workspace.
  final ViewsNode? views;
  
  /// The styles section of the workspace.
  final StylesNode? styles;
  
  /// The themes of the workspace.
  final List<ThemeNode> themes;
  
  /// The branding of the workspace.
  final BrandingNode? branding;
  
  /// The terminology of the workspace.
  final TerminologyNode? terminology;
  
  /// The properties of the workspace.
  final PropertiesNode? properties;
  
  /// The configuration of the workspace.
  final Map<String, String> configuration;
  
  /// The documentation of the workspace.
  final DocumentationNode? documentation;
  
  /// The architecture decision records.
  final List<DecisionNode>? decisions;
  
  /// The directives used to include files.
  final List<DirectiveNode>? directives;
  
  /// Creates a new workspace node.
  WorkspaceNode({
    required this.name,
    this.description,
    this.model,
    this.views,
    this.styles,
    this.themes = const [],
    this.branding,
    this.terminology,
    this.properties,
    this.configuration = const {},
    this.documentation,
    this.decisions,
    this.directives,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitWorkspaceNode(this);
  }
}