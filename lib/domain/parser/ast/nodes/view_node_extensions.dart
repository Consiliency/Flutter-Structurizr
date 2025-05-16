import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'view_node.dart';

/// Extensions for ViewNode to support additional functionality needed for
/// system context view parsing and building.
extension ViewNodeExtensions on ViewNode {
  static final Expando<Map<String, dynamic>> _propertiesExpando = Expando();
  static final Expando<Map<String, ElementNode>> _elementsExpando = Expando();

  Map<String, dynamic> get _properties =>
      _propertiesExpando[this] ??= <String, dynamic>{};
  Map<String, ElementNode> get _elements =>
      _elementsExpando[this] ??= <String, ElementNode>{};
  
  /// Adds an element to this view node.
  void addElement(ElementNode element) {
    _elements[element.id] = element;
  }
  
  /// Sets a property on this view node.
  void setProperty(String key, dynamic value) {
    _properties[key] = value;
  }
  
  /// Gets a property from this view node.
  dynamic getProperty(String key) {
    return _properties[key];
  }
  
  /// Checks if a property exists on this view node.
  bool hasProperty(String key) {
    return _properties.containsKey(key);
  }
  
  /// Checks if an element with the given ID exists in this view.
  bool hasElement(String elementId) {
    return _elements.containsKey(elementId);
  }
  
  /// Gets all elements in this view.
  Map<String, ElementNode> getElements() {
    return _elements;
  }
}

/// Extensions for SystemContextViewNode to support additional functionality.
extension SystemContextViewNodeExtensions on SystemContextViewNode {
  /// Sets an include rule on this system context view node.
  void setIncludeRule(IncludeNode rule) {
    // Since the includes are a final field, we can't modify the list directly
    // This is a limitation of the current AST implementation
    // In a real implementation, we'd need to allow for dynamic modification of these fields
    print('DEBUG: [SystemContextViewNode] Setting include rule: ${rule.expression}');
    // For now, we could track this in a separate map if needed
  }
  
  /// Sets an exclude rule on this system context view node.
  void setExcludeRule(ExcludeNode rule) {
    // Since the excludes are a final field, we can't modify the list directly
    // This is a limitation of the current AST implementation
    print('DEBUG: [SystemContextViewNode] Setting exclude rule: ${rule.expression}');
    // For now, we could track this in a separate map if needed
  }
  
  /// Sets the inheritance relationship for this system context view node.
  void setInheritance(ViewNode parentView) {
    // For now, we'll use the property mechanism to store the inheritance reference
    setProperty('inheritedFromViewKey', parentView.key);
  }
}