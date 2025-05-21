// Mock node implementations for tests

import 'package:flutter_structurizr/domain/parser/ast/nodes/source_position.dart';

class PersonNode {
  final String name;
  
  PersonNode({required this.name});
}

class SoftwareSystemNode {
  final String name;
  
  SoftwareSystemNode({required this.name});
}

class RelationshipNode {
  final String sourceId;
  final String destinationId;
  final String description;
  final SourcePosition? sourcePosition;
  
  RelationshipNode({
    required this.sourceId,
    required this.destinationId,
    required this.description,
    this.sourcePosition,
  });
}
