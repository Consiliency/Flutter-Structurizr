/// Represents a position in source code.
///
/// This class tracks the line, column, and character offset of a token
/// or node in the source code.
class SourcePosition {
  /// The 1-based line number in the source.
  final int line;
  
  /// The 1-based column number in the source.
  final int column;
  
  /// The 0-based character offset from the start of the source.
  final int offset;
  
  /// Creates a new source position with the given line, column, and offset.
  const SourcePosition(this.line, this.column, [this.offset = 0]);
  
  /// Creates a new source position with line and column only.
  /// The offset will be set to 0.
  const SourcePosition.lineColumn(this.line, this.column) : offset = 0;
  
  /// Creates a source position from another position.
  SourcePosition.from(SourcePosition other)
      : line = other.line,
        column = other.column,
        offset = other.offset;
        
  @override
  String toString() => 'line $line, column $column, offset $offset';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SourcePosition &&
        other.line == line &&
        other.column == column &&
        other.offset == offset;
  }
  
  @override
  int get hashCode => Object.hash(line, column, offset);
}
