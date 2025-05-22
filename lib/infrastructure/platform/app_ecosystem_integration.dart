import 'dart:io';
import 'package:flutter/services.dart';

/// Platform app ecosystem integration service
/// Provides deep integration with platform-specific app features
class AppEcosystemIntegration {
  static const _channel = MethodChannel('com.structurizr.flutter/ecosystem');
  
  bool _isInitialized = false;
  List<ShortcutItem> _registeredShortcuts = [];
  List<QuickAction> _registeredQuickActions = [];

  /// Initialize ecosystem integration
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _setupPlatformIntegration();
      await _registerDefaultShortcuts();
      await _setupShareExtensions();
      _isInitialized = true;
    } catch (e) {
      // Graceful degradation if ecosystem features aren't available
      _isInitialized = false;
    }
  }

  /// Check if ecosystem integration is available
  bool get isAvailable => _isInitialized;

  /// Register app shortcuts (iOS: Home screen shortcuts, Android: App shortcuts)
  Future<bool> registerShortcuts(List<ShortcutItem> shortcuts) async {
    if (!_isInitialized) return false;
    
    try {
      final shortcutData = shortcuts.map((s) => s.toMap()).toList();
      
      final result = await _channel.invokeMethod<bool>('registerShortcuts', {
        'shortcuts': shortcutData,
      });
      
      if (result == true) {
        _registeredShortcuts = shortcuts;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get registered shortcuts
  List<ShortcutItem> get registeredShortcuts => List.unmodifiable(_registeredShortcuts);

  /// Register quick actions (iOS: 3D Touch, Android: App shortcuts)
  Future<bool> registerQuickActions(List<QuickAction> actions) async {
    if (!_isInitialized) return false;
    
    try {
      final actionData = actions.map((a) => a.toMap()).toList();
      
      final result = await _channel.invokeMethod<bool>('registerQuickActions', {
        'actions': actionData,
      });
      
      if (result == true) {
        _registeredQuickActions = actions;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get registered quick actions
  List<QuickAction> get registeredQuickActions => List.unmodifiable(_registeredQuickActions);

  /// Handle incoming shortcut action
  Future<void> handleShortcutAction(String actionId) async {
    final shortcut = _registeredShortcuts.where((s) => s.id == actionId).firstOrNull;
    if (shortcut?.onActivated != null) {
      shortcut!.onActivated!(actionId);
    }
  }

  /// Handle incoming quick action
  Future<void> handleQuickAction(String actionId) async {
    final action = _registeredQuickActions.where((a) => a.id == actionId).firstOrNull;
    if (action?.onActivated != null) {
      action!.onActivated!(actionId);
    }
  }

  /// Add app to Siri shortcuts (iOS only)
  Future<bool> registerSiriShortcuts(List<SiriShortcut> shortcuts) async {
    if (!Platform.isIOS || !_isInitialized) return false;
    
    try {
      final shortcutData = shortcuts.map((s) => s.toMap()).toList();
      
      final result = await _channel.invokeMethod<bool>('registerSiriShortcuts', {
        'shortcuts': shortcutData,
      });
      
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Register app with system share sheet
  Future<bool> registerShareReceiver({
    List<String>? mimeTypes,
    List<String>? fileExtensions,
  }) async {
    if (!_isInitialized) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('registerShareReceiver', {
        'mimeTypes': mimeTypes ?? ['text/plain', 'application/json'],
        'fileExtensions': fileExtensions ?? ['.dsl', '.json', '.txt'],
      });
      
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Set app badge number (iOS only)
  Future<bool> setAppBadge(int count) async {
    if (!Platform.isIOS || !_isInitialized) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('setAppBadge', {
        'count': count,
      });
      
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Clear app badge (iOS only)
  Future<bool> clearAppBadge() async {
    return await setAppBadge(0);
  }

  /// Register for push notifications
  Future<NotificationRegistrationResult> registerForNotifications() async {
    if (!_isInitialized) {
      return NotificationRegistrationResult(
        success: false,
        error: 'Ecosystem integration not initialized',
      );
    }
    
    try {
      final result = await _channel.invokeMethod<Map<String, dynamic>>('registerForNotifications');
      
      if (result != null) {
        return NotificationRegistrationResult(
          success: result['success'] == true,
          token: result['token'] as String?,
          error: result['error'] as String?,
          permissionGranted: result['permissionGranted'] == true,
        );
      }
      
      return NotificationRegistrationResult(
        success: false,
        error: 'Failed to register for notifications',
      );
    } catch (e) {
      return NotificationRegistrationResult(
        success: false,
        error: 'Notification registration error: $e',
      );
    }
  }

  /// Show local notification
  Future<bool> showLocalNotification({
    required String title,
    required String body,
    String? actionId,
    Map<String, dynamic>? userInfo,
  }) async {
    if (!_isInitialized) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('showLocalNotification', {
        'title': title,
        'body': body,
        'actionId': actionId,
        'userInfo': userInfo,
      });
      
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Add to widget gallery (iOS 14+ widgets, Android app widgets)
  Future<bool> registerWidgets(List<WidgetConfiguration> widgets) async {
    if (!_isInitialized) return false;
    
    try {
      final widgetData = widgets.map((w) => w.toMap()).toList();
      
      final result = await _channel.invokeMethod<bool>('registerWidgets', {
        'widgets': widgetData,
      });
      
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Register custom URL scheme
  Future<bool> registerUrlScheme(String scheme) async {
    if (!_isInitialized) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('registerUrlScheme', {
        'scheme': scheme,
      });
      
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Handle incoming URL
  Future<void> handleIncomingUrl(String url) async {
    // Parse and handle the URL based on scheme and path
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    
    switch (uri.scheme) {
      case 'structurizr':
        await _handleStructurizrUrl(uri);
        break;
      default:
        // Handle other schemes
        break;
    }
  }

  /// Set up platform-specific integration
  Future<void> _setupPlatformIntegration() async {
    if (Platform.isIOS) {
      await _setupIOSIntegration();
    } else if (Platform.isAndroid) {
      await _setupAndroidIntegration();
    }
  }

  /// Set up iOS-specific integration
  Future<void> _setupIOSIntegration() async {
    await _channel.invokeMethod('setupIOSIntegration', {
      'enableSiri': true,
      'enableShortcuts': true,
      'enableQuickActions': true,
      'enableWidgets': true,
    });
  }

  /// Set up Android-specific integration
  Future<void> _setupAndroidIntegration() async {
    await _channel.invokeMethod('setupAndroidIntegration', {
      'enableAppShortcuts': true,
      'enableQuickSettings': true,
      'enableWidgets': true,
      'enableShareTarget': true,
    });
  }

  /// Register default app shortcuts
  Future<void> _registerDefaultShortcuts() async {
    final defaultShortcuts = [
      ShortcutItem(
        id: 'new_workspace',
        title: 'New Workspace',
        subtitle: 'Create a new workspace',
        icon: 'ic_add',
        onActivated: (actionId) async {
          // Handle new workspace creation
        },
      ),
      ShortcutItem(
        id: 'recent_workspaces',
        title: 'Recent Workspaces',
        subtitle: 'View recently opened workspaces',
        icon: 'ic_history',
        onActivated: (actionId) async {
          // Handle recent workspaces view
        },
      ),
      ShortcutItem(
        id: 'quick_diagram',
        title: 'Quick Diagram',
        subtitle: 'Create a diagram from template',
        icon: 'ic_diagram',
        onActivated: (actionId) async {
          // Handle quick diagram creation
        },
      ),
    ];
    
    await registerShortcuts(defaultShortcuts);
  }

  /// Set up share extensions
  Future<void> _setupShareExtensions() async {
    await registerShareReceiver(
      mimeTypes: [
        'text/plain',
        'application/json',
        'text/xml',
        'application/xml',
      ],
      fileExtensions: [
        '.dsl',
        '.json',
        '.xml',
        '.txt',
        '.md',
      ],
    );
  }

  /// Handle Structurizr URL scheme
  Future<void> _handleStructurizrUrl(Uri uri) async {
    switch (uri.host) {
      case 'workspace':
        final workspaceId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        if (workspaceId != null) {
          // Handle workspace opening
        }
        break;
      
      case 'diagram':
        final diagramKey = uri.queryParameters['key'];
        if (diagramKey != null) {
          // Handle diagram viewing
        }
        break;
      
      default:
        // Handle other URL patterns
        break;
    }
  }
}

// Data classes for ecosystem integration

class ShortcutItem {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final Future<void> Function(String actionId)? onActivated;

  ShortcutItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onActivated,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'icon': icon,
  };
}

class QuickAction {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final Future<void> Function(String actionId)? onActivated;

  QuickAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onActivated,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'icon': icon,
  };
}

class SiriShortcut {
  final String id;
  final String phrase;
  final String title;
  final String subtitle;
  final Map<String, dynamic> userInfo;

  SiriShortcut({
    required this.id,
    required this.phrase,
    required this.title,
    required this.subtitle,
    this.userInfo = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'phrase': phrase,
    'title': title,
    'subtitle': subtitle,
    'userInfo': userInfo,
  };
}

class WidgetConfiguration {
  final String id;
  final String displayName;
  final String description;
  final WidgetSize size;
  final String configurationClass;

  WidgetConfiguration({
    required this.id,
    required this.displayName,
    required this.description,
    required this.size,
    required this.configurationClass,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'description': description,
    'size': size.toString(),
    'configurationClass': configurationClass,
  };
}

class NotificationRegistrationResult {
  final bool success;
  final String? token;
  final String? error;
  final bool permissionGranted;

  NotificationRegistrationResult({
    required this.success,
    this.token,
    this.error,
    this.permissionGranted = false,
  });
}

enum WidgetSize {
  small,
  medium,
  large,
  extraLarge,
}

extension ListExtension<T> on List<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}