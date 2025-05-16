/// Represents a context used in the parsing stack.
class Context {
  /// The name of this context (e.g., "workspace", "model", "element")
  final String name;
  
  /// Additional data associated with this context.
  final Map<String, dynamic> data;
  
  /// Creates a new Context with the given name and optional data.
  Context(this.name, {Map<String, dynamic>? data}) 
      : this.data = data ?? {};
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Context &&
        other.name == name &&
        _mapEquals(other.data, data);
  }
  
  @override
  int get hashCode => name.hashCode ^ data.hashCode;
  
  @override
  String toString() => 'Context($name, $data)';
  
  /// Helper method to compare maps for equality
  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    return a.entries.every((e) => b.containsKey(e.key) && b[e.key] == e.value);
  }
}

/// A stack of parsing contexts.
/// 
/// This class is used to maintain the current parsing context during
/// recursive descent parsing, allowing the parser to know what kind of
/// element it's currently parsing and any associated data.
class ContextStack {
  /// The stack of contexts, with the most recent at the end.
  final List<Context> _stack = [];
  
  /// Creates a new empty context stack.
  ContextStack();
  
  /// Pushes a context onto the stack.
  /// 
  /// [context] must not be null.
  void push(Context context) {
    _stack.add(context);
  }
  
  /// Removes and returns the top context from the stack.
  /// 
  /// Throws a [StateError] if the stack is empty.
  Context pop() {
    if (_stack.isEmpty) {
      throw StateError('Cannot pop from an empty context stack');
    }
    return _stack.removeLast();
  }
  
  /// Returns the top context without removing it.
  /// 
  /// Throws a [StateError] if the stack is empty.
  Context current() {
    if (_stack.isEmpty) {
      throw StateError('Cannot get current context from an empty stack');
    }
    return _stack.last;
  }
  
  /// Alias for [current].
  Context peek() => current();
  
  /// Removes all contexts from the stack.
  void clear() {
    _stack.clear();
  }
  
  /// Returns the number of contexts in the stack.
  int size() => _stack.length;
  
  /// Returns true if the stack has no contexts.
  bool isEmpty() => _stack.isEmpty;
  
  /// Returns true if the stack has at least one context.
  bool isNotEmpty() => _stack.isNotEmpty;
  
  /// Pops contexts from the stack until [predicate] returns true for the current context.
  /// Returns the context that satisfied the predicate, or null if stack becomes empty.
  Context? popUntil(bool Function(Context) predicate) {
    while (isNotEmpty()) {
      final current = peek();
      if (predicate(current)) {
        return current;
      }
      pop();
    }
    return null;
  }
  
  @override
  String toString() {
    return 'ContextStack(${_stack.join(' -> ')})';
  }
}