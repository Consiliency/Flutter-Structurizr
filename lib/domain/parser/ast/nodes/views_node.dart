import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';
import 'system_landscape_view_node.dart';
import 'system_context_view_node.dart';
import 'container_view_node.dart';
import 'component_view_node.dart';
import 'dynamic_view_node.dart';
import 'deployment_view_node.dart';
import 'filtered_view_node.dart';
import 'custom_view_node.dart';
import 'image_view_node.dart';

class ViewsNode extends AstNode {
  final List<SystemLandscapeViewNode> systemLandscapeViews;
  final List<SystemContextViewNode> systemContextViews;
  final List<ContainerViewNode> containerViews;
  final List<ComponentViewNode> componentViews;
  final List<DynamicViewNode> dynamicViews;
  final List<DeploymentViewNode> deploymentViews;
  final List<FilteredViewNode> filteredViews;
  final List<CustomViewNode> customViews;
  final List<ImageViewNode> imageViews;
  final Map<String, String>? configuration;
  final SourcePosition? position;

  ViewsNode({
    this.systemLandscapeViews = const [],
    this.systemContextViews = const [],
    this.containerViews = const [],
    this.componentViews = const [],
    this.dynamicViews = const [],
    this.deploymentViews = const [],
    this.filteredViews = const [],
    this.customViews = const [],
    this.imageViews = const [],
    this.configuration,
    this.position,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition ?? position);

  @override
  void accept(AstVisitor visitor) {
    visitor.visitViewsNode(this);
  }
}
