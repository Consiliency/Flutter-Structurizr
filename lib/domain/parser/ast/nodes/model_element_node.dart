import 'source_position.dart';

// UPGRADED STUBS: Now include all fields used by parser, builder, and tests.

// Only keep RelationshipNode, ElementNode, ModelElementNode, and view node types for DTO/model purposes.

class RelationshipNode {
  final String sourceId;
  final String destinationId;
  final String? description;
  final String? technology;
  final List<String> tags;
  final Map<String, String> properties;
  final SourcePosition? sourcePosition;
  RelationshipNode({
    required this.sourceId,
    required this.destinationId,
    this.description,
    this.technology,
    this.tags = const [],
    this.properties = const {},
    this.sourcePosition,
  });
}

class ElementNode {
  final String id;
  final String name;
  final SourcePosition? sourcePosition;
  ElementNode({required this.id, required this.name, this.sourcePosition});
}

class ModelElementNode {
  final String id;
  final String name;
  final List<ModelElementNode> children;
  final List<RelationshipNode> relationships;
  final Map<String, String> properties;
  final SourcePosition? sourcePosition;
  ModelElementNode({
    required this.id,
    required this.name,
    this.children = const [],
    this.relationships = const [],
    this.properties = const {},
    this.sourcePosition,
  });
}

// --- Removed node class stubs that have dedicated files ---
// class SystemLandscapeViewNode { ... }
// class SystemContextViewNode { ... }
// class ContainerViewNode { ... }
// class ComponentViewNode { ... }
// class DynamicViewNode { ... }
// class DeploymentViewNode { ... }
// class FilteredViewNode { ... }
// class CustomViewNode { ... }
// class ImageViewNode { ... }
// class StylesNode { ... }
// class ThemeNode { ... }
// class BrandingNode { ... }
// class TerminologyNode { ... }

// --- Mutator methods for all node types ---

extension RelationshipNodeMutators on RelationshipNode {
  void setProperty(String key, String value) {/* no-op for stub */}
  void setDescription(String desc) {/* no-op for stub */}
}
