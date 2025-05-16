import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/modeled_relationship.dart';

/// A utility class for finding relationships in a model.
///
/// This class provides convenient methods for finding relationships
/// between elements in the architecture model.
class RelationshipFinder {
  final Model _model;

  /// Creates a new relationship finder for the given model.
  RelationshipFinder(this._model);

  /// Finds all relationships in the model.
  List<ModeledRelationship> findAllRelationships() {
    return _model.getAllRelationships()
        .map((r) => ModeledRelationship.fromRelationship(r, _model))
        .toList();
  }

  /// Finds all relationships involving the specified element (either as source or destination).
  List<ModeledRelationship> findRelationshipsInvolving(Element element) {
    final relationships = <ModeledRelationship>[];
    
    // Add relationships where the element is the source
    relationships.addAll(element.relationships
        .map((r) => ModeledRelationship.fromRelationship(r, _model)));
    
    // Add relationships where the element is the destination
    for (final e in _model.getAllElements()) {
      for (final r in e.relationships) {
        if (r.destinationId == element.id) {
          relationships.add(ModeledRelationship.fromRelationship(r, _model));
        }
      }
    }
    
    return relationships;
  }

  /// Finds a relationship between two elements.
  ModeledRelationship? findRelationshipBetween(String sourceId, String destinationId, {String? description}) {
    return _model.findRelationshipBetween(sourceId, destinationId, description);
  }

  /// Finds all relationships between two elements.
  List<ModeledRelationship> findAllRelationshipsBetween(String sourceId, String destinationId) {
    final source = _model.getElementById(sourceId);
    if (source == null) return [];
    
    return source.relationships
        .where((r) => r.destinationId == destinationId)
        .map((r) => ModeledRelationship.fromRelationship(r, _model))
        .toList();
  }

  /// Finds all relationships with the given tag.
  List<ModeledRelationship> findRelationshipsByTag(String tag) {
    return _model.getAllRelationships()
        .where((r) => r.tags.contains(tag))
        .map((r) => ModeledRelationship.fromRelationship(r, _model))
        .toList();
  }
}