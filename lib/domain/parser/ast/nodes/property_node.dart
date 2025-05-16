import '../../error_reporter.dart';
import '../ast_base.dart';

/// Node representing tags.
class TagsNode extends AstNode {
  /// The tags as a comma-separated string.
  final String tags;
  
  /// Creates a new tags node.
  TagsNode({
    required this.tags,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitTagsNode(this);
  }
}

/// Node representing properties.
class PropertiesNode extends AstNode {
  /// The properties.
  final List<PropertyNode> properties;
  
  /// Creates a new properties node.
  PropertiesNode({
    required this.properties,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitPropertiesNode(this);
  }
}

/// Node representing a property.
class PropertyNode extends AstNode {
  /// The name of the property.
  final String name;
  
  /// The value of the property.
  final String? value;
  
  /// Creates a new property node.
  PropertyNode({
    required this.name,
    this.value,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  /// The key representation of this property.
  String get key => name;
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitPropertyNode(this);
  }
}