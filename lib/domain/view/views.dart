import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';

part 'views.freezed.dart';
part 'views.g.dart';

/// Collection of architecture views for a workspace.
@freezed
class Views with _$Views {
  const Views._();

  /// Creates a new views collection with the given properties.
  const factory Views({
    /// System landscape views.
    @Default([]) List<SystemLandscapeView> systemLandscapeViews,

    /// System context views.
    @Default([]) List<SystemContextView> systemContextViews,

    /// Container views.
    @Default([]) List<ContainerView> containerViews,

    /// Component views.
    @Default([]) List<ComponentView> componentViews,

    /// Dynamic views.
    @Default([]) List<DynamicView> dynamicViews,

    /// Deployment views.
    @Default([]) List<DeploymentView> deploymentViews,

    /// Filtered views.
    @Default([]) List<FilteredView> filteredViews,

    /// Custom views.
    @Default([]) List<CustomView> customViews,

    /// Image views.
    @Default([]) List<ImageView> imageViews,

    /// Configuration for these views.
    ViewConfiguration? configuration,

    /// Styles for these views.
    Styles? styles,
  }) = _Views;

  /// Creates a views collection from a JSON object.
  factory Views.fromJson(Map<String, dynamic> json) => _$ViewsFromJson(json);
  
  /// Gets all views in this collection, flattened into a single list.
  List<View> getAllViews() {
    final views = <View>[];

    views.addAll(systemLandscapeViews);
    views.addAll(systemContextViews);
    views.addAll(containerViews);
    views.addAll(componentViews);
    views.addAll(dynamicViews);
    views.addAll(deploymentViews);
    views.addAll(filteredViews);
    views.addAll(customViews);
    views.addAll(imageViews);

    return views;
  }
  
  /// Gets a view by its key.
  View? getViewByKey(String key) {
    try {
      return getAllViews().firstWhere((v) => v.key == key);
    } catch (_) {
      return null;
    }
  }
  
  /// Checks if a view with the given key exists.
  bool containsViewWithKey(String key) {
    return getAllViews().any((v) => v.key == key);
  }
  
  /// Adds a system landscape view.
  Views addSystemLandscapeView(SystemLandscapeView view) {
    return copyWith(systemLandscapeViews: [...systemLandscapeViews, view]);
  }
  
  /// Adds a system context view.
  Views addSystemContextView(SystemContextView view) {
    return copyWith(systemContextViews: [...systemContextViews, view]);
  }
  
  /// Adds a container view.
  Views addContainerView(ContainerView view) {
    return copyWith(containerViews: [...containerViews, view]);
  }
  
  /// Adds a component view.
  Views addComponentView(ComponentView view) {
    return copyWith(componentViews: [...componentViews, view]);
  }
  
  /// Adds a dynamic view.
  Views addDynamicView(DynamicView view) {
    return copyWith(dynamicViews: [...dynamicViews, view]);
  }
  
  /// Adds a deployment view.
  Views addDeploymentView(DeploymentView view) {
    return copyWith(deploymentViews: [...deploymentViews, view]);
  }
  
  /// Adds a filtered view.
  Views addFilteredView(FilteredView view) {
    return copyWith(filteredViews: [...filteredViews, view]);
  }

  /// Adds a custom view.
  Views addCustomView(CustomView view) {
    return copyWith(customViews: [...customViews, view]);
  }

  /// Adds an image view.
  Views addImageView(ImageView view) {
    return copyWith(imageViews: [...imageViews, view]);
  }

  /// Updates the styles for these views.
  Views updateStyles(Styles styles) {
    return copyWith(styles: styles);
  }
}

/// Configuration for views.
@freezed
class ViewConfiguration with _$ViewConfiguration {
  const ViewConfiguration._();

  /// Creates a new view configuration with the given properties.
  const factory ViewConfiguration({
    /// Default view key.
    String? defaultView,
    
    /// Last modified date.
    DateTime? lastModifiedDate,
    
    /// Properties of the views.
    @Default({}) Map<String, String> properties,
    
    /// Terminology customization.
    Terminology? terminology,
  }) = _ViewConfiguration;

  /// Creates a view configuration from a JSON object.
  factory ViewConfiguration.fromJson(Map<String, dynamic> json) => _$ViewConfigurationFromJson(json);
}

/// Customized terminology for views.
@freezed
class Terminology with _$Terminology {
  const Terminology._();

  /// Creates a new terminology with the given properties.
  const factory Terminology({
    /// Custom term for "Person".
    String? person,
    
    /// Custom term for "Software System".
    String? softwareSystem,
    
    /// Custom term for "Container".
    String? container,
    
    /// Custom term for "Component".
    String? component,
    
    /// Custom term for "Code Element".
    String? codeElement,
    
    /// Custom term for "Deployment Node".
    String? deploymentNode,
    
    /// Custom term for "Relationship".
    String? relationship,
    
    /// Custom term for "Enterprise".
    String? enterprise,
  }) = _Terminology;

  /// Creates a terminology from a JSON object.
  factory Terminology.fromJson(Map<String, dynamic> json) => _$TerminologyFromJson(json);
}