import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class ImageViewNode extends AstNode {
  final String key;
  final String imagePath;
  final String? description;
  final String? title;
  final String? imageType;
  final String? content;
  final dynamic autoLayout;
  final List<dynamic> animations;
  final List<dynamic> includes;
  final List<dynamic> excludes;
  
  ImageViewNode({
    required this.key,
    required this.imagePath,
    this.description,
    this.title,
    this.imageType,
    this.content,
    this.autoLayout,
    this.animations = const [],
    this.includes = const [],
    this.excludes = const [],
    SourcePosition? sourcePosition,
  }) : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitImageViewNode(this);
}
