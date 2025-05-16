// Import View and concrete view types from view.dart to avoid conflicts with Flutter's View
import 'package:flutter_structurizr/domain/view/view.dart';

// Re-export the imported types
export 'package:flutter_structurizr/domain/view/view.dart';

// Alias for View and view types to avoid conflicts
typedef ModelView = View;

// Aliases for concrete view types to avoid conflicts with Flutter's built-in types
typedef ModelSystemLandscapeView = SystemLandscapeView;
typedef ModelSystemContextView = SystemContextView;
typedef ModelContainerView = ContainerView;
typedef ModelComponentView = ComponentView;
typedef ModelDynamicView = DynamicView;
typedef ModelDeploymentView = DeploymentView;
typedef ModelFilteredView = FilteredView;
typedef ModelCustomView = CustomView;
typedef ModelImageView = ImageView;

// Also provide aliases for view-related classes to maintain consistency
typedef ModelElementView = ElementView;
typedef ModelRelationshipView = RelationshipView;
typedef ModelAutomaticLayout = AutomaticLayout;
typedef ModelAnimationStep = AnimationStep;
typedef ModelVertex = Vertex;