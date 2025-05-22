import 'package:flutter/material.dart' hide Container, Border, Element, View;
import 'package:flutter_structurizr/domain/style/styles.dart' hide Border;

/// Utilities for line style rendering
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double startX = 0;
    const double dashWidth = 5;
    const double dashSpace = 3;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dotted line painter
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    double startX = 0;
    const double dotSize = 2;
    const double dotSpace = 3;

    while (startX < size.width) {
      canvas.drawCircle(
        Offset(startX + dotSize / 2, size.height / 2),
        dotSize / 2,
        paint,
      );
      startX += dotSize + dotSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Orthogonal routing painter
class OrthogonalRoutingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width / 2, size.height / 2);
    path.lineTo(size.width / 2, size.height / 4);
    path.lineTo(size.width, size.height / 4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Curved routing painter
class CurvedRoutingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height / 2,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Renders a line style preview
class LineStylePreviewPainter extends CustomPainter {
  final LineStyle lineStyle;
  final Color color;
  final double thickness;

  LineStylePreviewPainter({
    required this.lineStyle,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    switch (lineStyle) {
      case LineStyle.solid:
        canvas.drawLine(
          Offset(0, size.height / 2),
          Offset(size.width, size.height / 2),
          paint,
        );
        break;
      case LineStyle.dashed:
        double startX = 0;
        const double dashWidth = 5;
        const double dashSpace = 3;

        while (startX < size.width) {
          canvas.drawLine(
            Offset(startX, size.height / 2),
            Offset(startX + dashWidth, size.height / 2),
            paint,
          );
          startX += dashWidth + dashSpace;
        }
        break;
      case LineStyle.dotted:
        double startX = 0;
        final double dotSize = thickness;
        final double dotSpace = thickness + 2;

        final dotPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        while (startX < size.width) {
          canvas.drawCircle(
            Offset(startX + dotSize / 2, size.height / 2),
            dotSize / 2,
            dotPaint,
          );
          startX += dotSize + dotSpace;
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant LineStylePreviewPainter oldDelegate) =>
      oldDelegate.lineStyle != lineStyle ||
      oldDelegate.color != color ||
      oldDelegate.thickness != thickness;
}
