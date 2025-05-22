import 'package:flutter_structurizr/domain/parser/ast/nodes/relationship_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/relationship_parser.dart';
import 'package:test/test.dart';

void main() {
  group('RelationshipParser Implementation', () {
    late RelationshipParser parser;
    late ErrorReporter errorReporter;

    setUp(() {
      errorReporter = ErrorReporter('test');
      parser = RelationshipParser(errorReporter: errorReporter);
    });

    // Utility function to convert strings to tokens
    List<Token> tokensFromString(String source) {
      final lexer = Lexer(source);
      return lexer.scanTokens();
    }

    group('parse method', () {
      test('should return an empty list for empty tokens', () {
        final tokens = <Token>[];
        final result = parser.parse(tokens);
        expect(result, isEmpty);
      });

      test('should parse explicit relationship with arrow', () {
        final tokens = tokensFromString('source -> destination "Description"');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, 'Description');
        expect(result.first.technology, isNull);
      });

      test('should parse explicit relationship with arrow and technology', () {
        final tokens = tokensFromString(
            'source -> destination "Description" "Technology"');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, 'Description');
        expect(result.first.technology, 'Technology');
      });

      test('should parse implicit relationship with uses keyword', () {
        final tokens =
            tokensFromString('source uses destination "Description"');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, 'Description');
        expect(result.first.technology, isNull);
      });

      test(
          'should parse implicit relationship with uses keyword and technology',
          () {
        final tokens = tokensFromString(
            'source uses destination "Description" "Technology"');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, 'Description');
        expect(result.first.technology, 'Technology');
      });

      test(
          'should handle different relationship verbs for implicit relationships',
          () {
        final verbs = [
          'uses',
          'delivers',
          'influences',
          'syncs',
          'reads',
          'writes'
        ];

        for (final verb in verbs) {
          final tokens = tokensFromString('source $verb destination');
          final result = parser.parse(tokens);

          expect(result, hasLength(1), reason: 'Failed for verb: $verb');
          expect(result.first.sourceId, 'source');
          expect(result.first.destinationId, 'destination');
          expect(result.first.description,
              verb.substring(0, 1).toUpperCase() + verb.substring(1));
        }
      });

      test('should not parse invalid relationship syntax', () {
        final tokens = tokensFromString('invalid relationship syntax');
        final result = parser.parse(tokens);

        expect(result, isEmpty);
        expect(errorReporter.hasErrors(), isTrue);
      });
    });

    group('_isExplicitRelationship method', () {
      test('should identify arrow syntax', () {
        final tokens = tokensFromString('source -> destination');
        // We need to test the private method using reflection or create a test subclass
        // For now, we'll test implicitly via the parse method
        final result = parser.parse(tokens);
        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
      });

      test('should handle arrow with spaces around it', () {
        final tokens = tokensFromString('source -> destination');
        final result = parser.parse(tokens);
        expect(result, hasLength(1));
      });

      test('should not identify if arrow is missing', () {
        final tokens = tokensFromString('source destination');
        final result = parser.parse(tokens);
        expect(result, isEmpty);
      });
    });

    group('_isImplicitRelationship method', () {
      test('should identify uses relationship keyword', () {
        final tokens = tokensFromString('source uses destination');
        final result = parser.parse(tokens);
        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, 'Uses');
      });

      test('should identify other relationship keywords', () {
        final verbs = ['delivers', 'influences', 'syncs', 'reads', 'writes'];

        for (final verb in verbs) {
          final tokens = tokensFromString('source $verb destination');
          final result = parser.parse(tokens);
          expect(result, hasLength(1), reason: 'Failed for verb: $verb');
        }
      });

      test('should not identify if relationship keyword is missing', () {
        final tokens = tokensFromString('source destination');
        final result = parser.parse(tokens);
        expect(result, isEmpty);
      });
    });

    group('_parseExplicit method', () {
      test('should extract source and destination correctly', () {
        final tokens = tokensFromString('source -> destination');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
      });

      test('should handle multi-word identifiers', () {
        final tokens = tokensFromString('source system -> destination system');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source system');
        expect(result.first.destinationId, 'destination system');
      });

      test('should extract description correctly', () {
        final tokens =
            tokensFromString('source -> destination "This is a description"');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, 'This is a description');
      });

      test('should extract technology correctly', () {
        final tokens =
            tokensFromString('source -> destination "Description" "HTTPS"');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, 'Description');
        expect(result.first.technology, 'HTTPS');
      });

      test('should handle missing description', () {
        final tokens = tokensFromString('source -> destination');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, isNull);
      });

      test('should report error for invalid arrow position', () {
        final tokens = tokensFromString('-> destination');
        final result = parser.parse(tokens);

        expect(result, isEmpty);
        expect(errorReporter.hasErrors(), isTrue);
      });
    });

    group('_parseImplicit method', () {
      test('should extract source, verb, and destination correctly', () {
        final tokens = tokensFromString('source uses destination');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, 'Uses');
      });

      test('should handle multi-word identifiers', () {
        final tokens =
            tokensFromString('source system uses destination system');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source system');
        expect(result.first.destinationId, 'destination system');
      });

      test('should extract description correctly', () {
        final tokens =
            tokensFromString('source uses destination "Custom description"');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, 'Custom description');
      });

      test('should extract technology correctly', () {
        final tokens = tokensFromString(
            'source uses destination "Description" "REST API"');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, 'Description');
        expect(result.first.technology, 'REST API');
      });

      test('should use verb as description if no description provided', () {
        final tokens = tokensFromString('source uses destination');
        final result = parser.parse(tokens);

        expect(result, hasLength(1));
        expect(result.first.sourceId, 'source');
        expect(result.first.destinationId, 'destination');
        expect(result.first.description, 'Uses');
      });

      test('should report error for invalid verb position', () {
        final tokens = tokensFromString('uses destination');
        final result = parser.parse(tokens);

        expect(result, isEmpty);
        expect(errorReporter.hasErrors(), isTrue);
      });
    });

    group('Extension methods', () {
      test('String.capitalize should work correctly', () {
        expect('test'.capitalize(), 'Test');
        expect(''.capitalize(), '');
        expect('T'.capitalize(), 'T');
        expect('already Capitalized'.capitalize(), 'Already Capitalized');
      });

      test('RelationshipNode.setSource should set a new source ID', () {
        final node = RelationshipNode(
            sourceId: 'original', destinationId: 'destination');

        final updatedNode = node.setSource('newSource');

        expect(updatedNode.sourceId, 'newSource');
        expect(updatedNode.destinationId, 'destination');
        // Original node should be unchanged (immutability check)
        expect(node.sourceId, 'original');
      });

      test('RelationshipNode.setDestination should set a new destination ID',
          () {
        final node =
            RelationshipNode(sourceId: 'source', destinationId: 'original');

        final updatedNode = node.setDestination('newDestination');

        expect(updatedNode.sourceId, 'source');
        expect(updatedNode.destinationId, 'newDestination');
        // Original node should be unchanged (immutability check)
        expect(node.destinationId, 'original');
      });
    });
  });
}
