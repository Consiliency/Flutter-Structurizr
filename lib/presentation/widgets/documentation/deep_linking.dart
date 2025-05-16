import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';

/// Utility class for handling deep linking in documentation
class DocumentationDeepLinking {
  /// Generate a deep link for a documentation section
  static String generateSectionLink(String workspaceId, int sectionIndex, {Map<String, String>? params}) {
    final buffer = StringBuffer('/documentation/$workspaceId/section/$sectionIndex');
    
    // Add query parameters if provided
    if (params != null && params.isNotEmpty) {
      buffer.write('?');
      var first = true;
      params.forEach((key, value) {
        if (!first) buffer.write('&');
        buffer.write('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
        first = false;
      });
    }
    
    return buffer.toString();
  }
  
  /// Generate a deep link for a decision
  static String generateDecisionLink(String workspaceId, int decisionIndex, {Map<String, String>? params}) {
    final buffer = StringBuffer('/documentation/$workspaceId/decision/$decisionIndex');
    
    // Add query parameters if provided
    if (params != null && params.isNotEmpty) {
      buffer.write('?');
      var first = true;
      params.forEach((key, value) {
        if (!first) buffer.write('&');
        buffer.write('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
        first = false;
      });
    }
    
    return buffer.toString();
  }
  
  /// Parse a deep link
  static DeepLinkInfo? parseDeepLink(String url) {
    // Pattern for documentation section links
    final sectionPattern = RegExp(r'^/documentation/([^/]+)/section/(\d+)(?:\?(.*))?$');
    final sectionMatch = sectionPattern.firstMatch(url);
    
    if (sectionMatch != null) {
      final workspaceId = sectionMatch.group(1)!;
      final sectionIndex = int.parse(sectionMatch.group(2)!);
      final queryParams = _parseQueryParams(sectionMatch.group(3));
      
      return DeepLinkInfo(
        type: DeepLinkType.section,
        workspaceId: workspaceId,
        itemIndex: sectionIndex,
        params: queryParams,
      );
    }
    
    // Pattern for decision links
    final decisionPattern = RegExp(r'^/documentation/([^/]+)/decision/(\d+)(?:\?(.*))?$');
    final decisionMatch = decisionPattern.firstMatch(url);
    
    if (decisionMatch != null) {
      final workspaceId = decisionMatch.group(1)!;
      final decisionIndex = int.parse(decisionMatch.group(2)!);
      final queryParams = _parseQueryParams(decisionMatch.group(3));
      
      return DeepLinkInfo(
        type: DeepLinkType.decision,
        workspaceId: workspaceId,
        itemIndex: decisionIndex,
        params: queryParams,
      );
    }
    
    return null;
  }
  
  /// Parse query parameters from a URL
  static Map<String, String> _parseQueryParams(String? queryString) {
    if (queryString == null || queryString.isEmpty) {
      return {};
    }
    
    final params = <String, String>{};
    final pairs = queryString.split('&');
    
    for (final pair in pairs) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        params[Uri.decodeComponent(parts[0])] = Uri.decodeComponent(parts[1]);
      }
    }
    
    return params;
  }
  
  /// Encode a deep link as a shareable URL (with base URL)
  static String encodeShareableLink(String baseUrl, DeepLinkInfo info) {
    String path;
    
    if (info.type == DeepLinkType.section) {
      path = generateSectionLink(info.workspaceId, info.itemIndex, params: info.params);
    } else {
      path = generateDecisionLink(info.workspaceId, info.itemIndex, params: info.params);
    }
    
    // Ensure base URL doesn't end with a slash if path starts with one
    if (baseUrl.endsWith('/') && path.startsWith('/')) {
      return '${baseUrl.substring(0, baseUrl.length - 1)}$path';
    }
    
    // Add slash between base URL and path if needed
    if (!baseUrl.endsWith('/') && !path.startsWith('/')) {
      return '$baseUrl/$path';
    }
    
    return '$baseUrl$path';
  }
  
  /// Generate a shareable URL for a section
  static String shareSection(String baseUrl, String workspaceId, int sectionIndex) {
    return encodeShareableLink(
      baseUrl,
      DeepLinkInfo(
        type: DeepLinkType.section,
        workspaceId: workspaceId,
        itemIndex: sectionIndex,
      ),
    );
  }
  
  /// Generate a shareable URL for a decision
  static String shareDecision(String baseUrl, String workspaceId, int decisionIndex) {
    return encodeShareableLink(
      baseUrl,
      DeepLinkInfo(
        type: DeepLinkType.decision,
        workspaceId: workspaceId,
        itemIndex: decisionIndex,
      ),
    );
  }
  
  /// Encode deep link info into a JSON string (for serialization)
  static String encodeDeepLinkToJson(DeepLinkInfo info) {
    return jsonEncode({
      'type': info.type == DeepLinkType.section ? 'section' : 'decision',
      'workspaceId': info.workspaceId,
      'itemIndex': info.itemIndex,
      'params': info.params,
    });
  }
  
  /// Decode deep link info from a JSON string
  static DeepLinkInfo? decodeDeepLinkFromJson(String json) {
    try {
      final Map<String, dynamic> data = jsonDecode(json);
      
      return DeepLinkInfo(
        type: data['type'] == 'section' ? DeepLinkType.section : DeepLinkType.decision,
        workspaceId: data['workspaceId'],
        itemIndex: data['itemIndex'],
        params: Map<String, String>.from(data['params'] ?? {}),
      );
    } catch (e) {
      debugPrint('Error decoding deep link: $e');
      return null;
    }
  }
  
  /// Apply a deep link to navigate to the specified content
  static bool applyDeepLink(BuildContext context, Workspace workspace, DeepLinkInfo link, 
                           {Function(int)? onSectionSelected, Function(int)? onDecisionSelected}) {
    if (link.type == DeepLinkType.section) {
      if (workspace.documentation == null) return false;
      
      final docs = workspace.documentation!;
      if (link.itemIndex < 0 || link.itemIndex >= docs.sections.length) return false;
      
      onSectionSelected?.call(link.itemIndex);
      return true;
    } else if (link.type == DeepLinkType.decision) {
      if (workspace.documentation?.decisions == null) return false;
      
      final decisions = workspace.documentation!.decisions;
      if (link.itemIndex < 0 || link.itemIndex >= decisions.length) return false;
      
      onDecisionSelected?.call(link.itemIndex);
      return true;
    }
    
    return false;
  }
}

/// Type of deep link
enum DeepLinkType {
  section,
  decision,
}

/// Information about a deep link
class DeepLinkInfo {
  /// Type of link (section or decision)
  final DeepLinkType type;
  
  /// ID of the workspace
  final String workspaceId;
  
  /// Index of the item (section or decision)
  final int itemIndex;
  
  /// Additional parameters
  final Map<String, String> params;
  
  DeepLinkInfo({
    required this.type,
    required this.workspaceId,
    required this.itemIndex,
    this.params = const {},
  });
  
  @override
  String toString() {
    return 'DeepLinkInfo(type: $type, workspaceId: $workspaceId, itemIndex: $itemIndex, params: $params)';
  }
}

/// Widget that can handle documentation deep links
class DeepLinkHandler extends StatelessWidget {
  /// The child widget
  final Widget child;
  
  /// The workspace
  final Workspace workspace;
  
  /// Called when a section is selected from a deep link
  final Function(int)? onSectionSelected;
  
  /// Called when a decision is selected from a deep link
  final Function(int)? onDecisionSelected;
  
  /// Called when the initial deep link is processed
  final Function(DeepLinkInfo?)? onInitialLinkProcessed;
  
  /// Create a new deep link handler
  const DeepLinkHandler({
    Key? key,
    required this.child,
    required this.workspace,
    this.onSectionSelected,
    this.onDecisionSelected,
    this.onInitialLinkProcessed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // In a real app, you would handle the initial link here.
    // For simplicity in this implementation, we provide this wrapper
    // that can be used to handle links manually.
    return child;
  }
  
  /// Handle a deep link URL
  bool handleDeepLink(String url) {
    final link = DocumentationDeepLinking.parseDeepLink(url);
    if (link == null) return false;
    
    return DocumentationDeepLinking.applyDeepLink(
      null as BuildContext, // Context isn't actually used in the implementation
      workspace,
      link,
      onSectionSelected: onSectionSelected,
      onDecisionSelected: onDecisionSelected,
    );
  }
}