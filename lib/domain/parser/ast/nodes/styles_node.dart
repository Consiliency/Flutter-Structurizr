import '../ast_node.dart' show AstNode, AstVisitor;
import 'source_position.dart';

class StylesNode extends AstNode {
  StylesNode({SourcePosition? sourcePosition}) : super(sourcePosition);
  @override
  void accept(AstVisitor visitor) {}

  List<dynamic> get elements => const [];
  List<dynamic> get relationships => const [];
  List<dynamic> get elementStyles => const [];
  List<dynamic> get relationshipStyles => const [];
}

class ElementStyleNode extends AstNode {
  final String? tag;
  final String? color;
  final int? thickness;
  final int? fontSize;
  final double? opacity;
  final String? shape;
  final String? icon;
  final String? width;
  final String? height;
  final String? style;
  final String? border;
  final String? background;
  final String? stroke;
  
  ElementStyleNode({
    this.tag,
    this.color,
    this.thickness,
    this.fontSize,
    this.opacity,
    this.shape,
    this.icon,
    this.width,
    this.height,
    this.style,
    this.border,
    this.background,
    this.stroke,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {}
}

class RelationshipStyleNode extends AstNode {
  final String? tag;
  final String? color;
  final int? thickness;
  final int? fontSize;
  final double? opacity;
  final bool? dashed;
  final String? routing;
  final String? style;
  
  RelationshipStyleNode({
    this.tag,
    this.color,
    this.thickness,
    this.fontSize,
    this.opacity,
    this.dashed,
    this.routing,
    this.style,
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);
  
  @override
  void accept(AstVisitor visitor) {}
}
