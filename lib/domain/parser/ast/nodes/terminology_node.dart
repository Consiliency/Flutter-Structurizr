import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class TerminologyNode extends AstNode {
  final String? enterprise;
  final String? person;
  final String? softwareSystem;
  final String? container;
  final String? component;
  final String? deploymentNode;
  final String? infrastructureNode;
  final String? code;
  final String? relationship;
  
  TerminologyNode({
    this.enterprise,
    this.person,
    this.softwareSystem,
    this.container,
    this.component,
    this.deploymentNode,
    this.infrastructureNode,
    this.code,
    this.relationship,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {}
}
