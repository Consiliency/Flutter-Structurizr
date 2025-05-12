import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart';

part 'view.freezed.dart';
part 'view.g.dart';

/// Routing strategy for relationships.
enum Routing {
  /// Direct straight line.
  direct,

  /// Curved path with control points.
  curved,

  /// Path with right angles.
  orthogonal,
}

/// Interface for all architecture views in Structurizr.
///
/// A view represents a specific visualization of the architecture model.
abstract class View {
  /// Unique key for this view.
  String get key;

  /// Optional title displayed on the diagram.
  String? get title;

  /// Description of this view.
  String? get description;

  /// Elements included in this view.
  List<ElementView> get elements;

  /// Relationships included in this view.
  List<RelationshipView> get relationships;

  /// Automatic layout configuration.
  AutomaticLayout? get automaticLayout;

  /// Animation steps (for dynamic views).
  List<AnimationStep> get animations;

  /// The type of this view (SystemLandscape, SystemContext, etc.).
  String get viewType;

  /// Adds an element to this view.
  View addElement(ElementView element);

  /// Adds a relationship to this view.
  View addRelationship(RelationshipView relationship);

  /// Checks if this view contains an element with the given ID.
  bool containsElement(String elementId) {
    return elements.any((e) => e.id == elementId);
  }

  /// Checks if this view contains a relationship with the given ID.
  bool containsRelationship(String relationshipId) {
    return relationships.any((r) => r.id == relationshipId);
  }

  /// Gets an element in this view by its ID.
  ElementView? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  /// Gets a relationship in this view by its ID.
  RelationshipView? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }
}

/// A basic implementation of the View interface for testing and general use.
@freezed
class BaseView with _$BaseView implements View {
  const BaseView._();

  /// Creates a new base view.
  const factory BaseView({
    required String key,
    String? title,
    String? description,
    @Default([]) List<ElementView> elements,
    @Default([]) List<RelationshipView> relationships,
    AutomaticLayout? automaticLayout,
    @Default([]) List<AnimationStep> animations,
    required String viewType,
  }) = _BaseView;

  /// Creates a base view from a JSON object.
  factory BaseView.fromJson(Map<String, dynamic> json) => _$BaseViewFromJson(json);

  @override
  BaseView addElement(ElementView element) {
    final updatedElements = [...elements, element];
    return copyWith(elements: updatedElements);
  }

  @override
  BaseView addRelationship(RelationshipView relationship) {
    final updatedRelationships = [...relationships, relationship];
    return copyWith(relationships: updatedRelationships);
  }

  @override
  bool containsElement(String elementId) {
    return elements.any((e) => e.id == elementId);
  }

  @override
  bool containsRelationship(String relationshipId) {
    return relationships.any((r) => r.id == relationshipId);
  }

  @override
  ElementView? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  @override
  RelationshipView? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }
}

/// System Landscape view showing all software systems and people.
@freezed
class SystemLandscapeView with _$SystemLandscapeView implements View {
  const SystemLandscapeView._();

  /// Creates a new system landscape view.
  const factory SystemLandscapeView({
    required String key,
    String? title,
    String? description,
    @Default([]) List<ElementView> elements,
    @Default([]) List<RelationshipView> relationships,
    AutomaticLayout? automaticLayout,
    @Default([]) List<AnimationStep> animations,
    @Default('SystemLandscape') String viewType,
    String? enterpriseName,
  }) = _SystemLandscapeView;

  /// Creates a system landscape view from a JSON object.
  factory SystemLandscapeView.fromJson(Map<String, dynamic> json) => _$SystemLandscapeViewFromJson(json);

  @override
  SystemLandscapeView addElement(ElementView element) {
    final updatedElements = [...elements, element];
    return copyWith(elements: updatedElements);
  }

  @override
  SystemLandscapeView addRelationship(RelationshipView relationship) {
    final updatedRelationships = [...relationships, relationship];
    return copyWith(relationships: updatedRelationships);
  }

  @override
  bool containsElement(String elementId) {
    return elements.any((e) => e.id == elementId);
  }

  @override
  bool containsRelationship(String relationshipId) {
    return relationships.any((r) => r.id == relationshipId);
  }

  @override
  ElementView? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  @override
  RelationshipView? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }
}

/// System Context view focusing on a single software system.
@freezed
class SystemContextView with _$SystemContextView implements View {
  const SystemContextView._();

  /// Creates a new system context view.
  const factory SystemContextView({
    required String key,
    String? title,
    String? description,
    @Default([]) List<ElementView> elements,
    @Default([]) List<RelationshipView> relationships,
    AutomaticLayout? automaticLayout,
    @Default([]) List<AnimationStep> animations,
    @Default('SystemContext') String viewType,
    required String softwareSystemId,
    String? enterpriseName,
  }) = _SystemContextView;

  /// Creates a system context view from a JSON object.
  factory SystemContextView.fromJson(Map<String, dynamic> json) => _$SystemContextViewFromJson(json);

  @override
  SystemContextView addElement(ElementView element) {
    final updatedElements = [...elements, element];
    return copyWith(elements: updatedElements);
  }

  @override
  SystemContextView addRelationship(RelationshipView relationship) {
    final updatedRelationships = [...relationships, relationship];
    return copyWith(relationships: updatedRelationships);
  }

  @override
  bool containsElement(String elementId) {
    return elements.any((e) => e.id == elementId);
  }

  @override
  bool containsRelationship(String relationshipId) {
    return relationships.any((r) => r.id == relationshipId);
  }

  @override
  ElementView? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  @override
  RelationshipView? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }
}

/// Container view showing the containers within a software system.
@freezed
class ContainerView with _$ContainerView implements View {
  const ContainerView._();

  /// Creates a new container view.
  const factory ContainerView({
    required String key,
    String? title,
    String? description,
    @Default([]) List<ElementView> elements,
    @Default([]) List<RelationshipView> relationships,
    AutomaticLayout? automaticLayout,
    @Default([]) List<AnimationStep> animations,
    @Default('Container') String viewType,
    required String softwareSystemId,
    @Default(false) bool externalSoftwareSystemBoundariesVisible,
  }) = _ContainerView;

  /// Creates a container view from a JSON object.
  factory ContainerView.fromJson(Map<String, dynamic> json) => _$ContainerViewFromJson(json);

  @override
  ContainerView addElement(ElementView element) {
    final updatedElements = [...elements, element];
    return copyWith(elements: updatedElements);
  }

  @override
  ContainerView addRelationship(RelationshipView relationship) {
    final updatedRelationships = [...relationships, relationship];
    return copyWith(relationships: updatedRelationships);
  }

  @override
  bool containsElement(String elementId) {
    return elements.any((e) => e.id == elementId);
  }

  @override
  bool containsRelationship(String relationshipId) {
    return relationships.any((r) => r.id == relationshipId);
  }

  @override
  ElementView? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  @override
  RelationshipView? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }
}

/// Component view showing the components within a container.
@freezed
class ComponentView with _$ComponentView implements View {
  const ComponentView._();

  /// Creates a new component view.
  const factory ComponentView({
    required String key,
    String? title,
    String? description,
    @Default([]) List<ElementView> elements,
    @Default([]) List<RelationshipView> relationships,
    AutomaticLayout? automaticLayout,
    @Default([]) List<AnimationStep> animations,
    @Default('Component') String viewType,
    required String softwareSystemId,
    required String containerId,
    @Default(false) bool externalContainerBoundariesVisible,
  }) = _ComponentView;

  /// Creates a component view from a JSON object.
  factory ComponentView.fromJson(Map<String, dynamic> json) => _$ComponentViewFromJson(json);

  @override
  ComponentView addElement(ElementView element) {
    final updatedElements = [...elements, element];
    return copyWith(elements: updatedElements);
  }

  @override
  ComponentView addRelationship(RelationshipView relationship) {
    final updatedRelationships = [...relationships, relationship];
    return copyWith(relationships: updatedRelationships);
  }

  @override
  bool containsElement(String elementId) {
    return elements.any((e) => e.id == elementId);
  }

  @override
  bool containsRelationship(String relationshipId) {
    return relationships.any((r) => r.id == relationshipId);
  }

  @override
  ElementView? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  @override
  RelationshipView? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }
}

/// Dynamic view showing a sequence of interactions.
@freezed
class DynamicView with _$DynamicView implements View {
  const DynamicView._();

  /// Creates a new dynamic view.
  const factory DynamicView({
    required String key,
    String? title,
    String? description,
    @Default([]) List<ElementView> elements,
    @Default([]) List<RelationshipView> relationships,
    AutomaticLayout? automaticLayout,
    @Default([]) List<AnimationStep> animations,
    @Default('Dynamic') String viewType,
    String? elementId,
    @Default(true) bool autoAnimationInterval,
  }) = _DynamicView;

  /// Creates a dynamic view from a JSON object.
  factory DynamicView.fromJson(Map<String, dynamic> json) => _$DynamicViewFromJson(json);

  @override
  DynamicView addElement(ElementView element) {
    final updatedElements = [...elements, element];
    return copyWith(elements: updatedElements);
  }

  @override
  DynamicView addRelationship(RelationshipView relationship) {
    final updatedRelationships = [...relationships, relationship];
    return copyWith(relationships: updatedRelationships);
  }

  @override
  bool containsElement(String elementId) {
    return elements.any((e) => e.id == elementId);
  }

  @override
  bool containsRelationship(String relationshipId) {
    return relationships.any((r) => r.id == relationshipId);
  }

  @override
  ElementView? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  @override
  RelationshipView? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }
}

/// Deployment view showing the deployment of containers to infrastructure.
@freezed
class DeploymentView with _$DeploymentView implements View {
  const DeploymentView._();

  /// Creates a new deployment view.
  const factory DeploymentView({
    required String key,
    String? title,
    String? description,
    @Default([]) List<ElementView> elements,
    @Default([]) List<RelationshipView> relationships,
    AutomaticLayout? automaticLayout,
    @Default([]) List<AnimationStep> animations,
    @Default('Deployment') String viewType,
    String? softwareSystemId,
    required String environment,
  }) = _DeploymentView;

  /// Creates a deployment view from a JSON object.
  factory DeploymentView.fromJson(Map<String, dynamic> json) => _$DeploymentViewFromJson(json);

  @override
  DeploymentView addElement(ElementView element) {
    final updatedElements = [...elements, element];
    return copyWith(elements: updatedElements);
  }

  @override
  DeploymentView addRelationship(RelationshipView relationship) {
    final updatedRelationships = [...relationships, relationship];
    return copyWith(relationships: updatedRelationships);
  }

  @override
  bool containsElement(String elementId) {
    return elements.any((e) => e.id == elementId);
  }

  @override
  bool containsRelationship(String relationshipId) {
    return relationships.any((r) => r.id == relationshipId);
  }

  @override
  ElementView? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  @override
  RelationshipView? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }
}

/// Filtered view showing a subset of another view.
@freezed
class FilteredView with _$FilteredView implements View {
  const FilteredView._();

  /// Creates a new filtered view.
  const factory FilteredView({
    required String key,
    String? title,
    String? description,
    @Default([]) List<ElementView> elements,
    @Default([]) List<RelationshipView> relationships,
    AutomaticLayout? automaticLayout,
    @Default([]) List<AnimationStep> animations,
    @Default('Filtered') String viewType,
    required String baseViewKey,
    String? filterMode,
    @Default([]) List<String> tags,
    @Default([]) List<String> includeTags,
    @Default([]) List<String> excludeTags,
  }) = _FilteredView;

  /// Creates a filtered view from a JSON object.
  factory FilteredView.fromJson(Map<String, dynamic> json) => _$FilteredViewFromJson(json);

  @override
  FilteredView addElement(ElementView element) {
    final updatedElements = [...elements, element];
    return copyWith(elements: updatedElements);
  }

  @override
  FilteredView addRelationship(RelationshipView relationship) {
    final updatedRelationships = [...relationships, relationship];
    return copyWith(relationships: updatedRelationships);
  }

  @override
  bool containsElement(String elementId) {
    return elements.any((e) => e.id == elementId);
  }

  @override
  bool containsRelationship(String relationshipId) {
    return relationships.any((r) => r.id == relationshipId);
  }

  @override
  ElementView? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  @override
  RelationshipView? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }
}

/// Element view in a diagram.
@freezed
class ElementView with _$ElementView {
  const ElementView._();

  /// Creates a new element view.
  const factory ElementView({
    /// ID of the element in the model.
    required String id,

    /// X position in the diagram.
    int? x,

    /// Y position in the diagram.
    int? y,

    /// Width of the element.
    int? width,

    /// Height of the element.
    int? height,

    /// Parent element ID for nested elements.
    String? parentId,
  }) = _ElementView;

  /// Creates an element view from a JSON object.
  factory ElementView.fromJson(Map<String, dynamic> json) => _$ElementViewFromJson(json);
}

/// Relationship view in a diagram.
@freezed
class RelationshipView with _$RelationshipView {
  const RelationshipView._();

  /// Creates a new relationship view.
  const factory RelationshipView({
    /// ID of the relationship in the model.
    required String id,

    /// Description override for this view.
    String? description,

    /// Display order (for dynamic views).
    String? order,

    /// Routing points for this relationship.
    @Default([]) List<Vertex> vertices,

    /// Position of the relationship label (0-100).
    int? position,

    /// ID of the source element.
    String? sourceId,

    /// ID of the destination element.
    String? destinationId,
  }) = _RelationshipView;

  /// Creates a relationship view from a JSON object.
  factory RelationshipView.fromJson(Map<String, dynamic> json) => _$RelationshipViewFromJson(json);
}

/// A vertex (point) in a relationship path.
@freezed
class Vertex with _$Vertex {
  const Vertex._();

  /// Creates a new vertex.
  const factory Vertex({
    /// X position in the diagram.
    required int x,
    
    /// Y position in the diagram.
    required int y,
  }) = _Vertex;

  /// Creates a vertex from a JSON object.
  factory Vertex.fromJson(Map<String, dynamic> json) => _$VertexFromJson(json);
}

/// Automatic layout configuration.
@freezed
class AutomaticLayout with _$AutomaticLayout {
  const AutomaticLayout._();

  /// Creates a new automatic layout configuration.
  const factory AutomaticLayout({
    /// Algorithm to use (e.g., "Graphviz", "ForceDirected").
    @Default('ForceDirected') String implementation,
    
    /// Rank direction (e.g., "TopBottom", "LeftRight").
    String? rankDirection,
    
    /// Rank separation for layered layouts.
    int? rankSeparation,
    
    /// Node separation for layered layouts.
    int? nodeSeparation,
    
    /// Edge separation for layered layouts.
    int? edgeSeparation,
  }) = _AutomaticLayout;

  /// Creates an automatic layout configuration from a JSON object.
  factory AutomaticLayout.fromJson(Map<String, dynamic> json) => _$AutomaticLayoutFromJson(json);
}

/// Animation step for dynamic views.
@freezed
class AnimationStep with _$AnimationStep {
  const AnimationStep._();

  /// Creates a new animation step.
  const factory AnimationStep({
    /// Step number.
    required int order,
    
    /// Elements to show in this step.
    @Default([]) List<String> elements,
    
    /// Relationships to show in this step.
    @Default([]) List<String> relationships,
  }) = _AnimationStep;

  /// Creates an animation step from a JSON object.
  factory AnimationStep.fromJson(Map<String, dynamic> json) => _$AnimationStepFromJson(json);
}

/// Custom view for user-defined diagrams.
@freezed
class CustomView with _$CustomView implements View {
  const CustomView._();

  /// Creates a new custom view.
  const factory CustomView({
    required String key,
    String? title,
    String? description,
    @Default([]) List<ElementView> elements,
    @Default([]) List<RelationshipView> relationships,
    AutomaticLayout? automaticLayout,
    @Default([]) List<AnimationStep> animations,
    @Default('Custom') String viewType,
    @Default([]) List<String> includeTags,
    @Default([]) List<String> excludeTags,
    @Default('A4_Landscape') String paperSize,
  }) = _CustomView;

  /// Creates a custom view from a JSON object.
  factory CustomView.fromJson(Map<String, dynamic> json) => _$CustomViewFromJson(json);

  @override
  CustomView addElement(ElementView element) {
    final updatedElements = [...elements, element];
    return copyWith(elements: updatedElements);
  }

  @override
  CustomView addRelationship(RelationshipView relationship) {
    final updatedRelationships = [...relationships, relationship];
    return copyWith(relationships: updatedRelationships);
  }

  @override
  bool containsElement(String elementId) {
    return elements.any((e) => e.id == elementId);
  }

  @override
  bool containsRelationship(String relationshipId) {
    return relationships.any((r) => r.id == relationshipId);
  }

  @override
  ElementView? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  @override
  RelationshipView? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }
}

/// Image view for embedded images.
@freezed
class ImageView with _$ImageView implements View {
  const ImageView._();

  /// Creates a new image view.
  const factory ImageView({
    required String key,
    String? title,
    String? description,
    @Default([]) List<ElementView> elements,
    @Default([]) List<RelationshipView> relationships,
    AutomaticLayout? automaticLayout,
    @Default([]) List<AnimationStep> animations,
    @Default('Image') String viewType,
    String? imageType,
    String? content,
    @Default('A4_Landscape') String paperSize,
  }) = _ImageView;

  /// Creates an image view from a JSON object.
  factory ImageView.fromJson(Map<String, dynamic> json) => _$ImageViewFromJson(json);

  @override
  ImageView addElement(ElementView element) {
    final updatedElements = [...elements, element];
    return copyWith(elements: updatedElements);
  }

  @override
  ImageView addRelationship(RelationshipView relationship) {
    final updatedRelationships = [...relationships, relationship];
    return copyWith(relationships: updatedRelationships);
  }

  @override
  bool containsElement(String elementId) {
    return elements.any((e) => e.id == elementId);
  }

  @override
  bool containsRelationship(String relationshipId) {
    return relationships.any((r) => r.id == relationshipId);
  }

  @override
  ElementView? getElementById(String elementId) {
    try {
      return elements.firstWhere((e) => e.id == elementId);
    } catch (_) {
      return null;
    }
  }

  @override
  RelationshipView? getRelationshipById(String relationshipId) {
    try {
      return relationships.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      return null;
    }
  }
}