import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart' show SourcePosition;
import 'view_property_node.dart';
import 'include_node.dart';
import 'exclude_node.dart';
import 'tags_node.dart';

/// Enum for the type of view (system context, container, etc.)
enum ViewNodeType {
  systemLandscape,
  systemContext,
  container,
  component,
  filtered,
  dynamic,
  deployment,
  custom,
  image,
}

class ViewNode extends AstNode {
  final ViewNodeType type;
  String? title;
  String? description;
  final List<ViewPropertyNode> properties;
  final List<AstNode> children;
  final List<IncludeNode> includes;
  final List<ExcludeNode> excludes;
  final List<TagsNode> tags;

  ViewNode({
    required this.type,
    this.title,
    this.description,
    this.properties = const [],
    this.children = const [],
    this.includes = const [],
    this.excludes = const [],
    this.tags = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  void addProperty(ViewPropertyNode property) => properties.add(property);
  void addChild(AstNode child) => children.add(child);
  void addInclude(IncludeNode include) => includes.add(include);
  void addExclude(ExcludeNode exclude) => excludes.add(exclude);
  void addTags(TagsNode tagsNode) => tags.add(tagsNode);

  @override
  void accept(AstVisitor visitor) => visitor.visitViewNode(this);
}
