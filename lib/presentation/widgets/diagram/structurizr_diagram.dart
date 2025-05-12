
/// A custom painter for drawing a grid in the background
class _GridPainter extends CustomPainter {
  /// The current zoom scale
  final double zoomScale;
  
  /// The current pan offset
  final Offset panOffset;
  
  /// The spacing between grid lines
  final double spacing;
  
  /// The color of the grid lines
  final Color color;
  
  /// Creates a new grid painter
  const _GridPainter({
    required this.zoomScale,
    required this.panOffset,
    required this.spacing,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    
    // Adjust grid spacing based on zoom
    final adjustedSpacing = spacing * zoomScale;
    
    // Calculate the visible area
    final visibleRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Calculate the grid offset
    final offsetX = panOffset.dx % adjustedSpacing;
    final offsetY = panOffset.dy % adjustedSpacing;
    
    // Calculate the number of vertical and horizontal lines needed
    final horizontalLineCount = (size.height / adjustedSpacing).ceil() + 1;
    final verticalLineCount = (size.width / adjustedSpacing).ceil() + 1;
    
    // Draw horizontal lines
    for (var i = 0; i < horizontalLineCount; i++) {
      final y = i * adjustedSpacing + offsetY;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Draw vertical lines
    for (var i = 0; i < verticalLineCount; i++) {
      final x = i * adjustedSpacing + offsetX;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.zoomScale != zoomScale ||
           oldDelegate.panOffset != panOffset ||
           oldDelegate.spacing != spacing ||
           oldDelegate.color != color;
  }
}

/// A custom painter for drawing the lasso selection
class _LassoPainter extends CustomPainter {
  /// The lasso selection
  final LassoSelection lassoSelection;
  
  /// The color of the lasso border
  final Color borderColor;
  
  /// The color of the lasso fill
  final Color fillColor;
  
  /// The width of the lasso border
  final double borderWidth;
  
  /// Creates a new lasso painter
  const _LassoPainter({
    required this.lassoSelection,
    required this.borderColor,
    required this.fillColor,
    required this.borderWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create paints for the border and fill
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    
    // Draw the lasso fill first, then the border
    canvas.drawPath(lassoSelection.path, fillPaint);
    canvas.drawPath(lassoSelection.path, borderPaint);
  }
  
  @override
  bool shouldRepaint(_LassoPainter oldDelegate) {
    return oldDelegate.lassoSelection != lassoSelection ||
           oldDelegate.borderColor != borderColor ||
           oldDelegate.fillColor != fillColor ||
           oldDelegate.borderWidth != borderWidth;
  }
}

/// A composite painter that combines multiple painters
class _CompositePainter extends CustomPainter {
  /// The grid painter (optional)
  final _GridPainter? gridPainter;
  
  /// The lasso painter (optional)
  final _LassoPainter? lassoPainter;
  
  /// Creates a new composite painter
  const _CompositePainter({
    this.gridPainter,
    this.lassoPainter,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Paint in order: grid first, then lasso
    gridPainter?.paint(canvas, size);
    lassoPainter?.paint(canvas, size);
  }
  
  @override
  bool shouldRepaint(_CompositePainter oldDelegate) {
    return oldDelegate.gridPainter != gridPainter ||
           oldDelegate.lassoPainter != lassoPainter;
  }
}