import '../ast_node.dart' show AstNode, AstVisitor;
import 'person_node.dart' show PersonNode;
import 'software_system_node.dart' show SoftwareSystemNode;
import 'relationship_node.dart' show RelationshipNode;
import 'deployment_environment_node.dart' show DeploymentEnvironmentNode;
import 'source_position.dart' show SourcePosition;

class ModelNode extends AstNode {
  final String name;
  final List<PersonNode> people;
  final List<SoftwareSystemNode> softwareSystems;
  final List<RelationshipNode> relationships;
  final List<DeploymentEnvironmentNode> deploymentEnvironments;
  ModelNode(
      {this.name = '',
      this.people = const [],
      this.softwareSystems = const [],
      this.relationships = const [],
      this.deploymentEnvironments = const [],
      SourcePosition? sourcePosition})
      : super(sourcePosition);
  void addGroup(dynamic group) {}
  void addEnterprise(dynamic enterprise) {}
  void addElement(dynamic element) {}
  void addImpliedRelationship(dynamic relationship) {}
  @override
  void accept(AstVisitor visitor) {}
}
