/// This file provides helper exports to resolve naming conflicts between
/// Flutter built-in classes and Structurizr domain model classes.
///
/// Use these exports when you need to import both Flutter widgets and
/// Structurizr model classes in the same file.

// Re-export Flutter components with problematic names hidden
export 'package:flutter/material.dart' hide Container, Element, View, Border;

// Re-export Structurizr domain models with clear naming using aliases
export 'package:flutter_structurizr/domain/model/container_alias.dart';
export 'package:flutter_structurizr/domain/model/element_alias.dart';
export 'package:flutter_structurizr/domain/view/view_alias.dart';
export 'package:flutter_structurizr/domain/style/styles.dart' hide Border;
export 'package:flutter_structurizr/domain/model/model.dart' hide Container, Person, Element;
export 'package:flutter_structurizr/domain/model/person.dart';

/// When working with Flutter UI components that conflict with Structurizr model names:
///
/// 1. For Structurizr model classes, use the following aliases:
///    - ModelContainer (instead of Container)
///    - ModelElement (instead of Element)
///    - ModelView (instead of View)
///    - ModelSystemLandscapeView (instead of SystemLandscapeView)
///    - ModelSystemContextView (instead of SystemContextView)
///    - ModelContainerView (instead of ContainerView)
///    - ModelComponentView (instead of ComponentView)
///    - ModelDynamicView (instead of DynamicView)
///    - ModelDeploymentView (instead of DeploymentView)
///    - ModelFilteredView (instead of FilteredView)
///    - ModelCustomView (instead of CustomView)
///    - ModelImageView (instead of ImageView)
///    - ModelElementView (instead of ElementView)
///    - ModelRelationshipView (instead of RelationshipView)
///
/// 2. Instead of Flutter's Container, use:
///    - Material with padding
///    - SizedBox for simple dimensions
///    - Padding for adding space
///    - DecoratedBox for styling
///
/// 3. Instead of Flutter's Element, use:
///    - Widget or BuildContext directly
///
/// 4. Instead of Flutter's View, use:
///    - Widget or specific widget types
///
/// 5. For Border conflicts:
///    - Use BoxBorder, Border.all(), etc. with full qualification
///
/// Example usage:
/// ```dart
/// import 'package:flutter_structurizr/util/import_helper.dart';
///
/// class MyWidget extends StatelessWidget {
///   final ModelContainer container; // This is the Structurizr Container with alias
///   final ModelElement element; // This is the Structurizr Element with alias
///
///   const MyWidget({
///     Key? key,
///     required this.container,
///     required this.element,
///   }) : super(key: key);
///
///   @override
///   Widget build(BuildContext context) {
///     return Material( // Instead of Flutter's Container
///       child: Padding(
///         padding: const EdgeInsets.all(8.0),
///         child: Column(
///           children: [
///             Text(container.name),
///             Text(element.description ?? 'No description'),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```