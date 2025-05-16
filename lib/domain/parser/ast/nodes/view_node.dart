import '../../error_reporter.dart';
import '../ast_base.dart';

/// Node representing an element in a view.
class ElementNode {
  /// The ID of the element.
  final String id;
  
  /// The name of the element (optional).
  final String? name;
  
  /// Creates a new element node.
  ElementNode({
    required this.id,
    this.name,
  });
}

/// Base class for all view nodes.
abstract class ViewNode extends AstNode {
  /// The key of this view.
  final String key;
  
  /// The title of this view.
  final String? title;
  
  /// The description of this view.
  final String? description;
  
  /// The includes for this view.
  final List<IncludeNode> includes;
  
  /// The excludes for this view.
  final List<ExcludeNode> excludes;
  
  /// The auto layout settings for this view.
  final AutoLayoutNode? autoLayout;
  
  /// The animation steps for this view.
  final List<AnimationNode> animations;
  
  /// Creates a new view node.
  ViewNode({
    required this.key,
    this.title,
    this.description,
    this.includes = const [],
    this.excludes = const [],
    this.autoLayout,
    this.animations = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
}

/// Node representing a system landscape view.
class SystemLandscapeViewNode extends ViewNode {
  /// The elements included in this view.
  final List<ElementNode> _elements = [];
  
  /// Creates a new system landscape view node.
  SystemLandscapeViewNode({
    required String key,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitSystemLandscapeViewNode(this);
  }
  
  /// Adds an element to this view.
  ///
  /// Returns true if the element was added, false if it was already present.
  bool addElement(ElementNode element) {
    if (hasElement(element.id)) {
      return false;
    }
    _elements.add(element);
    return true;
  }
  
  /// Checks if an element with the given ID is included in this view.
  bool hasElement(String elementId) {
    return _elements.any((e) => e.id == elementId);
  }
  
  /// Gets all elements in this view.
  List<ElementNode> get elements => List.unmodifiable(_elements);
}

/// Node representing a system context view.
class SystemContextViewNode extends ViewNode {
  /// The ID of the software system.
  final String systemId;
  
  /// The elements included in this view.
  final List<ElementNode> _elements = [];
  
  /// Creates a new system context view node.
  SystemContextViewNode({
    required String key,
    required this.systemId,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitSystemContextViewNode(this);
  }
  
  /// Adds an element to this view.
  ///
  /// Returns true if the element was added, false if it was already present.
  bool addElement(ElementNode element) {
    if (hasElement(element.id)) {
      return false;
    }
    _elements.add(element);
    return true;
  }
  
  /// Checks if an element with the given ID is included in this view.
  bool hasElement(String elementId) {
    return _elements.any((e) => e.id == elementId);
  }
  
  /// Gets all elements in this view.
  List<ElementNode> get elements => List.unmodifiable(_elements);
}

/// Node representing a container view.
class ContainerViewNode extends ViewNode {
  /// The ID of the software system.
  final String systemId;
  
  /// The elements included in this view.
  final List<ElementNode> _elements = [];
  
  /// Creates a new container view node.
  ContainerViewNode({
    required String key,
    required this.systemId,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitContainerViewNode(this);
  }
  
  /// Adds an element to this view.
  ///
  /// Returns true if the element was added, false if it was already present.
  bool addElement(ElementNode element) {
    if (hasElement(element.id)) {
      return false;
    }
    _elements.add(element);
    return true;
  }
  
  /// Checks if an element with the given ID is included in this view.
  bool hasElement(String elementId) {
    return _elements.any((e) => e.id == elementId);
  }
  
  /// Gets all elements in this view.
  List<ElementNode> get elements => List.unmodifiable(_elements);
}

/// Node representing a component view.
class ComponentViewNode extends ViewNode {
  /// The ID of the container.
  final String containerId;
  
  /// The elements included in this view.
  final List<ElementNode> _elements = [];
  
  /// Creates a new component view node.
  ComponentViewNode({
    required String key,
    required this.containerId,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitComponentViewNode(this);
  }
  
  /// Adds an element to this view.
  ///
  /// Returns true if the element was added, false if it was already present.
  bool addElement(ElementNode element) {
    if (hasElement(element.id)) {
      return false;
    }
    _elements.add(element);
    return true;
  }
  
  /// Checks if an element with the given ID is included in this view.
  bool hasElement(String elementId) {
    return _elements.any((e) => e.id == elementId);
  }
  
  /// Gets all elements in this view.
  List<ElementNode> get elements => List.unmodifiable(_elements);
}

/// Node representing a dynamic view.
class DynamicViewNode extends ViewNode {
  /// The scope of the dynamic view (optional).
  final String? scope;
  
  /// The elements included in this view.
  final List<ElementNode> _elements = [];
  
  /// Creates a new dynamic view node.
  DynamicViewNode({
    required String key,
    this.scope,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitDynamicViewNode(this);
  }
  
  /// Adds an element to this view.
  ///
  /// Returns true if the element was added, false if it was already present.
  bool addElement(ElementNode element) {
    if (hasElement(element.id)) {
      return false;
    }
    _elements.add(element);
    return true;
  }
  
  /// Checks if an element with the given ID is included in this view.
  bool hasElement(String elementId) {
    return _elements.any((e) => e.id == elementId);
  }
  
  /// Gets all elements in this view.
  List<ElementNode> get elements => List.unmodifiable(_elements);
}

/// Node representing a deployment view.
class DeploymentViewNode extends ViewNode {
  /// The ID of the software system.
  final String systemId;
  
  /// The environment (e.g., "Production").
  final String environment;
  
  /// The elements included in this view.
  final List<ElementNode> _elements = [];
  
  /// Creates a new deployment view node.
  DeploymentViewNode({
    required String key,
    required this.systemId,
    required this.environment,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitDeploymentViewNode(this);
  }
  
  /// Adds an element to this view.
  ///
  /// Returns true if the element was added, false if it was already present.
  bool addElement(ElementNode element) {
    if (hasElement(element.id)) {
      return false;
    }
    _elements.add(element);
    return true;
  }
  
  /// Checks if an element with the given ID is included in this view.
  bool hasElement(String elementId) {
    return _elements.any((e) => e.id == elementId);
  }
  
  /// Gets all elements in this view.
  List<ElementNode> get elements => List.unmodifiable(_elements);
}

/// Node representing a filtered view.
class FilteredViewNode extends ViewNode {
  /// The key of the base view.
  final String baseViewKey;
  
  /// The elements included in this view.
  final List<ElementNode> _elements = [];
  
  /// Creates a new filtered view node.
  FilteredViewNode({
    required String key,
    required this.baseViewKey,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitFilteredViewNode(this);
  }
  
  /// Adds an element to this view.
  ///
  /// Returns true if the element was added, false if it was already present.
  bool addElement(ElementNode element) {
    if (hasElement(element.id)) {
      return false;
    }
    _elements.add(element);
    return true;
  }
  
  /// Checks if an element with the given ID is included in this view.
  bool hasElement(String elementId) {
    return _elements.any((e) => e.id == elementId);
  }
  
  /// Gets all elements in this view.
  List<ElementNode> get elements => List.unmodifiable(_elements);
}

/// Node representing a custom view.
class CustomViewNode extends ViewNode {
  /// The elements included in this view.
  final List<ElementNode> _elements = [];
  
  /// Creates a new custom view node.
  CustomViewNode({
    required String key,
    String? title,
    String? description,
    List<IncludeNode> includes = const [],
    List<ExcludeNode> excludes = const [],
    AutoLayoutNode? autoLayout,
    List<AnimationNode> animations = const [],
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    includes: includes,
    excludes: excludes,
    autoLayout: autoLayout,
    animations: animations,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitCustomViewNode(this);
  }
  
  /// Adds an element to this view.
  ///
  /// Returns true if the element was added, false if it was already present.
  bool addElement(ElementNode element) {
    if (hasElement(element.id)) {
      return false;
    }
    _elements.add(element);
    return true;
  }
  
  /// Checks if an element with the given ID is included in this view.
  bool hasElement(String elementId) {
    return _elements.any((e) => e.id == elementId);
  }
  
  /// Gets all elements in this view.
  List<ElementNode> get elements => List.unmodifiable(_elements);
}

/// Node representing an image view.
class ImageViewNode extends ViewNode {
  /// The type of the image.
  final String imageType;
  
  /// The content of the image.
  final String content;
  
  /// The elements included in this view.
  final List<ElementNode> _elements = [];
  
  /// Creates a new image view node.
  ImageViewNode({
    required String key,
    required this.imageType,
    required this.content,
    String? title,
    String? description,
    SourcePosition? sourcePosition,
  }) : super(
    key: key,
    title: title,
    description: description,
    sourcePosition: sourcePosition,
  );
  
  @override
  void accept(AstVisitor visitor) {
    visitor.visitImageViewNode(this);
  }
  
  /// Adds an element to this view.
  ///
  /// Returns true if the element was added, false if it was already present.
  bool addElement(ElementNode element) {
    if (hasElement(element.id)) {
      return false;
    }
    _elements.add(element);
    return true;
  }
  
  /// Checks if an element with the given ID is included in this view.
  bool hasElement(String elementId) {
    return _elements.any((e) => e.id == elementId);
  }
  
  /// Gets all elements in this view.
  List<ElementNode> get elements => List.unmodifiable(_elements);
}