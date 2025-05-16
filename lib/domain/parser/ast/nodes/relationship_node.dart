import '../../error_reporter.dart';
import '../ast_base.dart';

/// Node representing a relationship between two elements.
class RelationshipNode extends AstNode {
  /// The source element ID.
  final String sourceId;
  
  /// The destination element ID.
  final String destinationId;
  
  /// The description of this relationship.
  final String? description;
  
  /// The technology of this relationship.
  final String? technology;
  
  /// The tags associated with this relationship.
  final TagsNode? tags;
  
  /// The properties associated with this relationship.
  final PropertiesNode? properties;
  
  /// Creates a new relationship node.
  RelationshipNode({
    required this.sourceId,
    required this.destinationId,
    this.description,
    this.technology,
    this.tags,
    this.properties,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitRelationshipNode(this);
  }
}