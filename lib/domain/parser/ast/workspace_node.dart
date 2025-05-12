import '../error_reporter.dart';
import 'ast_node.dart';

/// This file is kept for backward compatibility
/// All actual node implementations are now in ast_nodes.dart
/// Import this file to get access to workspace-related nodes
/// 
/// @deprecated Use ast_node.dart instead

// Re-export the workspace-related nodes from ast_node.dart
export 'ast_node.dart' show
    WorkspaceNode,
    ViewsNode;