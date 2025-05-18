import '../ast_node.dart';
import 'source_position.dart' show SourcePosition;

class ImageViewNode extends AstNode {
  final String key;
  final String imagePath;
  final String? description;
  ImageViewNode(
      {required this.key,
      required this.imagePath,
      this.description,
      SourcePosition? sourcePosition})
      : super(sourcePosition);

  @override
  void accept(AstVisitor visitor) => visitor.visitImageViewNode(this);
}
