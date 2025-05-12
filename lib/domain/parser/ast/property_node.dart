import '../error_reporter.dart';
import 'ast_node.dart';

/// This file is kept for backward compatibility
/// All actual node implementations are now in ast_nodes.dart
/// Import this file to get access to property-related nodes
/// 
/// @deprecated Use ast_node.dart instead

// Re-export the property-related nodes from ast_node.dart
export 'ast_node.dart' show
    TagsNode,
    PropertiesNode,
    PropertyNode,
    StylesNode,
    ElementStyleNode,
    RelationshipStyleNode,
    ThemeNode,
    BrandingNode,
    TerminologyNode;