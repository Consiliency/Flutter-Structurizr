import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';

/// Represents a relationship between two elements in the architecture model
/// with resolved source and destination elements.
///
/// This class extends the basic Relationship functionality by providing
/// direct access to source and destination elements through the model.
class ModeledRelationship extends Relationship {
  /// Reference to the model to resolve element references
  final Model _model;

  /// Creates a modeled relationship with the given properties.
  ModeledRelationship({
    required String id,
    required String sourceId,
    required String destinationId,
    required String description,
    String? technology,
    List<String> tags = const [],
    Map<String, String> properties = const {},
    String interactionStyle = "Synchronous",
    required Model model,
  }) : _model = model,
       super(
         id: id,
         sourceId: sourceId,
         destinationId: destinationId,
         description: description,
         technology: technology,
         tags: tags,
         properties: properties,
         interactionStyle: interactionStyle,
       );
  
  /// Creates a ModeledRelationship from a basic Relationship and a Model.
  factory ModeledRelationship.fromRelationship(Relationship relationship, Model model) {
    return ModeledRelationship(
      id: relationship.id,
      sourceId: relationship.sourceId,
      destinationId: relationship.destinationId,
      description: relationship.description,
      technology: relationship.technology,
      tags: relationship.tags,
      properties: relationship.properties,
      interactionStyle: relationship.interactionStyle,
      model: model,
    );
  }

  @override
  Element get source {
    final element = _model.getElementById(sourceId);
    if (element == null) {
      throw RelationshipNotFoundException(
        'Source element with ID $sourceId not found',
      );
    }
    return element;
  }

  @override
  Element get destination {
    final element = _model.getElementById(destinationId);
    if (element == null) {
      throw RelationshipNotFoundException(
        'Destination element with ID $destinationId not found',
      );
    }
    return element;
  }
}