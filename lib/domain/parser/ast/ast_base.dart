// This file re-exports the core AST types needed by tests and components 
// that expect to find them in ast_base.dart

export 'ast_node.dart';
export 'nodes/source_position.dart';
export 'nodes/model_node.dart';
export 'nodes/software_system_node.dart';
export 'nodes/container_node.dart';
export 'nodes/component_node.dart';
export 'nodes/person_node.dart';
export 'nodes/property_node.dart';
export 'nodes/properties_node.dart';
// Export only the relationship_node.dart file to avoid duplicate exports
export 'nodes/relationship_node.dart' hide RelationshipNode;
export 'nodes/include_node.dart';
export 'nodes/exclude_node.dart';
export 'nodes/model_element_node.dart';