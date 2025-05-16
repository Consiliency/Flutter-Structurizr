import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/context_stack.dart';

void main() {
  group('ContextStack', () {
    late ContextStack contextStack;
    
    setUp(() {
      contextStack = ContextStack();
    });
    
    test('push adds a context to the stack', () {
      final context = Context('test');
      contextStack.push(context);
      
      expect(contextStack.size(), equals(1));
      expect(contextStack.current(), equals(context));
    });
    
    test('pop removes and returns the top context', () {
      final context1 = Context('context1');
      final context2 = Context('context2');
      
      contextStack.push(context1);
      contextStack.push(context2);
      
      expect(contextStack.size(), equals(2));
      
      final poppedContext = contextStack.pop();
      
      expect(poppedContext, equals(context2));
      expect(contextStack.size(), equals(1));
      expect(contextStack.current(), equals(context1));
    });
    
    test('current returns the top context without removing it', () {
      final context1 = Context('context1');
      final context2 = Context('context2');
      
      contextStack.push(context1);
      contextStack.push(context2);
      
      expect(contextStack.current(), equals(context2));
      expect(contextStack.size(), equals(2));
    });
    
    test('clear removes all contexts from the stack', () {
      contextStack.push(Context('context1'));
      contextStack.push(Context('context2'));
      contextStack.push(Context('context3'));
      
      expect(contextStack.size(), equals(3));
      
      contextStack.clear();
      
      expect(contextStack.size(), equals(0));
    });
    
    test('size returns the number of contexts in the stack', () {
      expect(contextStack.size(), equals(0));
      
      contextStack.push(Context('context1'));
      expect(contextStack.size(), equals(1));
      
      contextStack.push(Context('context2'));
      expect(contextStack.size(), equals(2));
      
      contextStack.pop();
      expect(contextStack.size(), equals(1));
      
      contextStack.pop();
      expect(contextStack.size(), equals(0));
    });
    
    test('current throws when stack is empty', () {
      expect(() => contextStack.current(), throwsStateError);
    });
    
    test('pop throws when stack is empty', () {
      expect(() => contextStack.pop(), throwsStateError);
    });
    
    test('push with null context throws ArgumentError', () {
      expect(() => contextStack.push(null), throwsArgumentError);
    });
    
    test('push adds multiple contexts and maintains order', () {
      final contexts = List.generate(5, (index) => Context('context$index'));
      
      for (var context in contexts) {
        contextStack.push(context);
      }
      
      expect(contextStack.size(), equals(5));
      expect(contextStack.current(), equals(contexts.last));
      
      // Pop all contexts and verify the order
      for (var i = contexts.length - 1; i >= 0; i--) {
        final popped = contextStack.pop();
        expect(popped, equals(contexts[i]));
      }
    });
    
    test('clear makes the stack empty', () {
      for (var i = 0; i < 5; i++) {
        contextStack.push(Context('context$i'));
      }
      
      expect(contextStack.size(), greaterThan(0));
      expect(contextStack.isEmpty(), isFalse);
      
      contextStack.clear();
      
      expect(contextStack.size(), equals(0));
      expect(contextStack.isEmpty(), isTrue);
      expect(contextStack.isNotEmpty(), isFalse);
    });
    
    test('isEmpty and isNotEmpty return correct values', () {
      expect(contextStack.isEmpty(), isTrue);
      expect(contextStack.isNotEmpty(), isFalse);
      
      contextStack.push(Context('test'));
      
      expect(contextStack.isEmpty(), isFalse);
      expect(contextStack.isNotEmpty(), isTrue);
    });
    
    test('peek is an alias for current', () {
      final context = Context('test');
      contextStack.push(context);
      
      expect(contextStack.peek(), equals(context));
      expect(contextStack.peek(), equals(contextStack.current()));
      
      expect(() => ContextStack().peek(), throwsStateError);
    });
    
    test('popUntil removes contexts until predicate is satisfied', () {
      contextStack.push(Context('workspace'));
      contextStack.push(Context('model'));
      contextStack.push(Context('system'));
      contextStack.push(Context('container'));
      contextStack.push(Context('component'));
      
      expect(contextStack.size(), equals(5));
      
      // Pop until we reach the "model" context
      final result = contextStack.popUntil((ctx) => ctx.name == 'model');
      
      expect(result?.name, equals('model'));
      expect(contextStack.size(), equals(2)); // workspace and model
      expect(contextStack.current().name, equals('model'));
    });
    
    test('popUntil returns null if predicate never matches', () {
      contextStack.push(Context('workspace'));
      contextStack.push(Context('model'));
      
      final result = contextStack.popUntil((ctx) => ctx.name == 'nonexistent');
      
      expect(result, isNull);
      expect(contextStack.isEmpty(), isTrue);
    });
    
    test('popUntil handles empty stack gracefully', () {
      final result = contextStack.popUntil((ctx) => true);
      
      expect(result, isNull);
      expect(contextStack.isEmpty(), isTrue);
    });

    test('context data is preserved', () {
      final data = {'key': 'value', 'number': 42};
      final context = Context('test', data: data);
      
      contextStack.push(context);
      
      final retrieved = contextStack.current();
      expect(retrieved.data, equals(data));
      expect(retrieved.data['key'], equals('value'));
      expect(retrieved.data['number'], equals(42));
    });
    
    test('context data is independent between contexts', () {
      final data1 = {'key': 'value1'};
      final data2 = {'key': 'value2'};
      
      contextStack.push(Context('ctx1', data: data1));
      contextStack.push(Context('ctx2', data: data2));
      
      expect(contextStack.current().data['key'], equals('value2'));
      
      contextStack.pop();
      expect(contextStack.current().data['key'], equals('value1'));
    });
    
    test('toString provides meaningful representation', () {
      contextStack.push(Context('workspace'));
      contextStack.push(Context('model'));
      
      final string = contextStack.toString();
      
      expect(string, contains('ContextStack'));
      expect(string, contains('workspace'));
      expect(string, contains('model'));
      expect(string, contains('->'));
    });
  });
  
  group('Context', () {
    test('context creation with name only', () {
      final context = Context('test');
      
      expect(context.name, equals('test'));
      expect(context.data, isEmpty);
    });
    
    test('context creation with name and data', () {
      final data = {'key': 'value', 'number': 42};
      final context = Context('test', data: data);
      
      expect(context.name, equals('test'));
      expect(context.data, equals(data));
    });
    
    test('context equality compares name and data', () {
      final context1 = Context('test', data: {'key': 'value'});
      final context2 = Context('test', data: {'key': 'value'});
      final context3 = Context('test', data: {'key': 'other'});
      final context4 = Context('other', data: {'key': 'value'});
      
      expect(context1, equals(context2));
      expect(context1, isNot(equals(context3)));
      expect(context1, isNot(equals(context4)));
    });
    
    test('context hashCode considers both name and data', () {
      final context1 = Context('test', data: {'key': 'value'});
      final context2 = Context('test', data: {'key': 'value'});
      final context3 = Context('test', data: {'key': 'other'});
      final context4 = Context('other', data: {'key': 'value'});
      
      expect(context1.hashCode, equals(context2.hashCode));
      expect(context1.hashCode, isNot(equals(context3.hashCode)));
      expect(context1.hashCode, isNot(equals(context4.hashCode)));
    });
    
    test('context toString provides meaningful representation', () {
      final context = Context('test', data: {'key': 'value'});
      
      final string = context.toString();
      
      expect(string, contains('Context'));
      expect(string, contains('test'));
      expect(string, contains('key'));
      expect(string, contains('value'));
    });
    
    test('_mapEquals correctly compares maps', () {
      final context = Context('test');
      
      // Same maps
      expect(context._mapEquals({'a': 1, 'b': 2}, {'a': 1, 'b': 2}), isTrue);
      
      // Different values
      expect(context._mapEquals({'a': 1, 'b': 2}, {'a': 1, 'b': 3}), isFalse);
      
      // Different keys
      expect(context._mapEquals({'a': 1, 'b': 2}, {'a': 1, 'c': 2}), isFalse);
      
      // Different sizes
      expect(context._mapEquals({'a': 1, 'b': 2}, {'a': 1}), isFalse);
      
      // Empty maps
      expect(context._mapEquals({}, {}), isTrue);
    });
  });
}