import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/views_parser.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';

void main() {
  late ViewsParser viewsParser;
  late ErrorReporter errorReporter;

  setUp(() {
    errorReporter = ErrorReporter();
    viewsParser = ViewsParser(errorReporter);
  });

  group('ViewsParser.parse', () {
    test('should parse an empty views block', () {
      // Arrange
      final tokens = [
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        Token(TokenType.rightBrace, '}', SourcePosition(7, 1, 0, 7)),
        Token(TokenType.eof, '', SourcePosition(8, 0, 0, 8)),
      ];

      // Act
      final viewsNode = viewsParser.parse(tokens);

      // Assert
      expect(viewsNode, isA<ViewsNode>());
      expect(viewsNode.systemContextViews, isEmpty);
      expect(viewsNode.containerViews, isEmpty);
      expect(viewsNode.componentViews, isEmpty);
      expect(viewsNode.dynamicViews, isEmpty);
      expect(viewsNode.deploymentViews, isEmpty);
      expect(viewsNode.filteredViews, isEmpty);
      expect(viewsNode.customViews, isEmpty);
      expect(viewsNode.imageViews, isEmpty);
    });

    test('should parse a views block with a system context view', () {
      // Arrange
      final tokens = [
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        
        Token(TokenType.systemContext, 'systemContext', SourcePosition(10, 13, 1, 2)),
        Token(TokenType.identifier, 'system', SourcePosition(24, 6, 1, 16)),
        Token(TokenType.string, '"SystemContext"', SourcePosition(31, 15, 1, 23)),
        Token(TokenType.leftBrace, '{', SourcePosition(47, 1, 1, 39)),
        Token(TokenType.include, 'include', SourcePosition(51, 7, 2, 4)),
        Token(TokenType.wildcard, '*', SourcePosition(59, 1, 2, 12)),
        Token(TokenType.autoLayout, 'autoLayout', SourcePosition(63, 10, 3, 4)),
        Token(TokenType.rightBrace, '}', SourcePosition(75, 1, 4, 2)),
        
        Token(TokenType.rightBrace, '}', SourcePosition(77, 1, 5, 0)),
        Token(TokenType.eof, '', SourcePosition(78, 0, 5, 1)),
      ];

      // Act
      final viewsNode = viewsParser.parse(tokens);

      // Assert
      expect(viewsNode, isA<ViewsNode>());
      expect(viewsNode.systemContextViews, hasLength(1));
      expect(viewsNode.systemContextViews[0].key, equals('system'));
      expect(viewsNode.systemContextViews[0].title, equals('SystemContext'));
      expect(viewsNode.systemContextViews[0].includes, hasLength(1));
      expect(viewsNode.systemContextViews[0].includes[0].expression, equals('*'));
      expect(viewsNode.systemContextViews[0].autoLayout, isNotNull);
    });

    test('should parse a views block with multiple view types', () {
      // Arrange
      final tokens = [
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        
        // System Context View
        Token(TokenType.systemContext, 'systemContext', SourcePosition(10, 13, 1, 2)),
        Token(TokenType.identifier, 'system', SourcePosition(24, 6, 1, 16)),
        Token(TokenType.string, '"SystemContext"', SourcePosition(31, 15, 1, 23)),
        Token(TokenType.leftBrace, '{', SourcePosition(47, 1, 1, 39)),
        Token(TokenType.include, 'include', SourcePosition(51, 7, 2, 4)),
        Token(TokenType.wildcard, '*', SourcePosition(59, 1, 2, 12)),
        Token(TokenType.rightBrace, '}', SourcePosition(61, 1, 3, 2)),
        
        // Container View
        Token(TokenType.containerView, 'containerView', SourcePosition(65, 13, 4, 2)),
        Token(TokenType.identifier, 'system', SourcePosition(79, 6, 4, 16)),
        Token(TokenType.string, '"Container View"', SourcePosition(86, 16, 4, 23)),
        Token(TokenType.leftBrace, '{', SourcePosition(103, 1, 4, 40)),
        Token(TokenType.include, 'include', SourcePosition(107, 7, 5, 4)),
        Token(TokenType.wildcard, '*', SourcePosition(115, 1, 5, 12)),
        Token(TokenType.exclude, 'exclude', SourcePosition(119, 7, 6, 4)),
        Token(TokenType.identifier, 'database', SourcePosition(127, 8, 6, 12)),
        Token(TokenType.rightBrace, '}', SourcePosition(136, 1, 7, 2)),
        
        Token(TokenType.rightBrace, '}', SourcePosition(138, 1, 8, 0)),
        Token(TokenType.eof, '', SourcePosition(139, 0, 8, 1)),
      ];

      // Act
      final viewsNode = viewsParser.parse(tokens);

      // Assert
      expect(viewsNode, isA<ViewsNode>());
      
      // Check system context view
      expect(viewsNode.systemContextViews, hasLength(1));
      expect(viewsNode.systemContextViews[0].key, equals('system'));
      expect(viewsNode.systemContextViews[0].title, equals('SystemContext'));
      
      // Check container view
      expect(viewsNode.containerViews, hasLength(1));
      expect(viewsNode.containerViews[0].key, equals('system'));
      expect(viewsNode.containerViews[0].title, equals('Container View'));
      expect(viewsNode.containerViews[0].includes, hasLength(1));
      expect(viewsNode.containerViews[0].includes[0].expression, equals('*'));
      expect(viewsNode.containerViews[0].excludes, hasLength(1));
      expect(viewsNode.containerViews[0].excludes[0].expression, equals('database'));
    });

    test('should handle errors in views block', () {
      // Arrange
      final tokens = [
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        
        // Invalid token where a view type is expected
        Token(TokenType.identifier, 'invalidViewType', SourcePosition(10, 15, 1, 2)),
        
        Token(TokenType.rightBrace, '}', SourcePosition(26, 1, 2, 0)),
        Token(TokenType.eof, '', SourcePosition(27, 0, 2, 1)),
      ];

      // Act
      final viewsNode = viewsParser.parse(tokens);

      // Assert
      expect(viewsNode, isA<ViewsNode>());
      expect(errorReporter.hasErrors, isTrue);
    });

    test('should handle missing braces in views block', () {
      // Arrange
      final tokens = [
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        // Missing opening brace
        Token(TokenType.systemContext, 'systemContext', SourcePosition(6, 13, 0, 6)),
        Token(TokenType.identifier, 'system', SourcePosition(20, 6, 0, 20)),
        Token(TokenType.string, '"SystemContext"', SourcePosition(27, 15, 0, 27)),
        Token(TokenType.leftBrace, '{', SourcePosition(43, 1, 0, 43)),
        Token(TokenType.rightBrace, '}', SourcePosition(44, 1, 0, 44)),
        Token(TokenType.eof, '', SourcePosition(45, 0, 0, 45)),
      ];

      // Act
      final viewsNode = viewsParser.parse(tokens);

      // Assert
      expect(viewsNode, isA<ViewsNode>());
      expect(errorReporter.hasErrors, isTrue);
    });
  });

  group('ViewsParser._parseViewBlock', () {
    test('should parse a system context view block', () {
      // Arrange
      final tokens = [
        Token(TokenType.systemContext, 'systemContext', SourcePosition(0, 13, 0, 0)),
        Token(TokenType.identifier, 'system', SourcePosition(14, 6, 0, 14)),
        Token(TokenType.string, '"SystemContext"', SourcePosition(21, 15, 0, 21)),
        Token(TokenType.leftBrace, '{', SourcePosition(37, 1, 0, 37)),
        Token(TokenType.include, 'include', SourcePosition(41, 7, 1, 4)),
        Token(TokenType.wildcard, '*', SourcePosition(49, 1, 1, 12)),
        Token(TokenType.rightBrace, '}', SourcePosition(51, 1, 2, 0)),
        Token(TokenType.eof, '', SourcePosition(52, 0, 2, 1)),
      ];

      // Act
      // We're testing a private method, so we'll use the parse method instead
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(53, 1, 3, 0)),
      ]);

      // Assert
      expect(viewsNode.systemContextViews, hasLength(1));
      final viewNode = viewsNode.systemContextViews[0];
      expect(viewNode.key, equals('system'));
      expect(viewNode.systemId, equals('system'));
      expect(viewNode.title, equals('SystemContext'));
      expect(viewNode.includes, hasLength(1));
      expect(viewNode.includes[0].expression, equals('*'));
    });

    test('should parse a container view block', () {
      // Arrange
      final tokens = [
        Token(TokenType.containerView, 'containerView', SourcePosition(0, 13, 0, 0)),
        Token(TokenType.identifier, 'system', SourcePosition(14, 6, 0, 14)),
        Token(TokenType.string, '"Containers"', SourcePosition(21, 12, 0, 21)),
        Token(TokenType.leftBrace, '{', SourcePosition(34, 1, 0, 34)),
        Token(TokenType.include, 'include', SourcePosition(38, 7, 1, 4)),
        Token(TokenType.wildcard, '*', SourcePosition(46, 1, 1, 12)),
        Token(TokenType.rightBrace, '}', SourcePosition(48, 1, 2, 0)),
        Token(TokenType.eof, '', SourcePosition(49, 0, 2, 1)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(50, 1, 3, 0)),
      ]);

      // Assert
      expect(viewsNode.containerViews, hasLength(1));
      final viewNode = viewsNode.containerViews[0];
      expect(viewNode.key, equals('system'));
      expect(viewNode.systemId, equals('system'));
      expect(viewNode.title, equals('Containers'));
      expect(viewNode.includes, hasLength(1));
      expect(viewNode.includes[0].expression, equals('*'));
    });
    
    test('should parse a dynamic view block', () {
      // Arrange
      final tokens = [
        Token(TokenType.dynamicView, 'dynamic', SourcePosition(0, 7, 0, 0)),
        Token(TokenType.identifier, 'system', SourcePosition(8, 6, 0, 8)),
        Token(TokenType.string, '"Dynamic View"', SourcePosition(15, 14, 0, 15)),
        Token(TokenType.leftBrace, '{', SourcePosition(30, 1, 0, 30)),
        Token(TokenType.rightBrace, '}', SourcePosition(32, 1, 1, 0)),
        Token(TokenType.eof, '', SourcePosition(33, 0, 1, 1)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(34, 1, 2, 0)),
      ]);

      // Assert
      expect(viewsNode.dynamicViews, hasLength(1));
      final viewNode = viewsNode.dynamicViews[0];
      expect(viewNode.key, equals('system'));
      expect(viewNode.scope, equals('system'));
      expect(viewNode.title, equals('Dynamic View'));
    });

    test('should parse a filtered view block', () {
      // Arrange
      final tokens = [
        Token(TokenType.filteredView, 'filtered', SourcePosition(0, 8, 0, 0)),
        Token(TokenType.string, '"UserView"', SourcePosition(9, 10, 0, 9)),
        Token(TokenType.leftBrace, '{', SourcePosition(20, 1, 0, 20)),
        Token(TokenType.baseOn, 'baseOn', SourcePosition(22, 6, 1, 2)),
        Token(TokenType.string, '"SystemContext"', SourcePosition(29, 15, 1, 9)),
        Token(TokenType.include, 'include', SourcePosition(45, 7, 2, 2)),
        Token(TokenType.identifier, 'user', SourcePosition(53, 4, 2, 10)),
        Token(TokenType.rightBrace, '}', SourcePosition(58, 1, 3, 0)),
        Token(TokenType.eof, '', SourcePosition(59, 0, 3, 1)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(60, 1, 4, 0)),
      ]);

      // Assert
      expect(viewsNode.filteredViews, hasLength(1));
      final viewNode = viewsNode.filteredViews[0];
      expect(viewNode.key, equals('UserView'));
      expect(viewNode.baseViewKey, equals('SystemContext'));
      expect(viewNode.includes, hasLength(1));
      expect(viewNode.includes[0].expression, equals('user'));
    });

    test('should handle missing title in view block', () {
      // Arrange
      final tokens = [
        Token(TokenType.systemContext, 'systemContext', SourcePosition(0, 13, 0, 0)),
        Token(TokenType.identifier, 'system', SourcePosition(14, 6, 0, 14)),
        // Missing title string
        Token(TokenType.leftBrace, '{', SourcePosition(21, 1, 0, 21)),
        Token(TokenType.include, 'include', SourcePosition(23, 7, 1, 2)),
        Token(TokenType.wildcard, '*', SourcePosition(31, 1, 1, 10)),
        Token(TokenType.rightBrace, '}', SourcePosition(33, 1, 2, 0)),
        Token(TokenType.eof, '', SourcePosition(34, 0, 2, 1)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(35, 1, 3, 0)),
      ]);

      // Assert
      expect(errorReporter.hasErrors, isTrue);
    });

    test('should handle invalid view type', () {
      // Arrange
      final tokens = [
        Token(TokenType.identifier, 'invalidViewType', SourcePosition(0, 15, 0, 0)),
        Token(TokenType.string, '"Title"', SourcePosition(16, 7, 0, 16)),
        Token(TokenType.leftBrace, '{', SourcePosition(24, 1, 0, 24)),
        Token(TokenType.rightBrace, '}', SourcePosition(26, 1, 1, 0)),
        Token(TokenType.eof, '', SourcePosition(27, 0, 1, 1)),
      ];

      // Act & Assert
      expect(() => viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(28, 1, 2, 0)),
      ]), returnsNormally);
      expect(errorReporter.hasErrors, isTrue);
    });
  });

  group('ViewsParser._parseViewProperty', () {
    test('should parse a title property', () {
      // Arrange
      final tokens = [
        Token(TokenType.title, 'title', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.string, '"System Context View"', SourcePosition(6, 20, 0, 6)),
        Token(TokenType.eof, '', SourcePosition(27, 0, 0, 27)),
      ];

      // Act
      // Since this is a private method, we'll test it indirectly through a view block
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        Token(TokenType.systemContext, 'systemContext', SourcePosition(8, 13, 1, 0)),
        Token(TokenType.identifier, 'system', SourcePosition(22, 6, 1, 14)),
        Token(TokenType.string, '"Initial Title"', SourcePosition(29, 15, 1, 21)),
        Token(TokenType.leftBrace, '{', SourcePosition(45, 1, 1, 37)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(55, 1, 3, 0)),
        Token(TokenType.rightBrace, '}', SourcePosition(57, 1, 4, 0)),
        Token(TokenType.eof, '', SourcePosition(58, 0, 4, 1)),
      ]);

      // Assert
      expect(viewsNode.systemContextViews, hasLength(1));
      final viewNode = viewsNode.systemContextViews[0];
      // The title property should have overridden the initial title
      expect(viewNode.title, equals('System Context View'));
    });

    test('should parse a description property', () {
      // Arrange
      final tokens = [
        Token(TokenType.description, 'description', SourcePosition(0, 11, 0, 0)),
        Token(TokenType.string, '"This is a description"', SourcePosition(12, 23, 0, 12)),
        Token(TokenType.eof, '', SourcePosition(36, 0, 0, 36)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        Token(TokenType.systemContext, 'systemContext', SourcePosition(8, 13, 1, 0)),
        Token(TokenType.identifier, 'system', SourcePosition(22, 6, 1, 14)),
        Token(TokenType.string, '"Title"', SourcePosition(29, 7, 1, 21)),
        Token(TokenType.leftBrace, '{', SourcePosition(37, 1, 1, 29)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(75, 1, 3, 0)),
        Token(TokenType.rightBrace, '}', SourcePosition(77, 1, 4, 0)),
        Token(TokenType.eof, '', SourcePosition(78, 0, 4, 1)),
      ]);

      // Assert
      expect(viewsNode.systemContextViews, hasLength(1));
      final viewNode = viewsNode.systemContextViews[0];
      expect(viewNode.description, equals('This is a description'));
    });

    test('should handle invalid property value', () {
      // Arrange
      final tokens = [
        Token(TokenType.title, 'title', SourcePosition(0, 5, 0, 0)),
        // Missing string token for value
        Token(TokenType.identifier, 'invalidValue', SourcePosition(6, 12, 0, 6)),
        Token(TokenType.eof, '', SourcePosition(19, 0, 0, 19)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        Token(TokenType.systemContext, 'systemContext', SourcePosition(8, 13, 1, 0)),
        Token(TokenType.identifier, 'system', SourcePosition(22, 6, 1, 14)),
        Token(TokenType.string, '"Title"', SourcePosition(29, 7, 1, 21)),
        Token(TokenType.leftBrace, '{', SourcePosition(37, 1, 1, 29)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(58, 1, 3, 0)),
        Token(TokenType.rightBrace, '}', SourcePosition(60, 1, 4, 0)),
        Token(TokenType.eof, '', SourcePosition(61, 0, 4, 1)),
      ]);

      // Assert
      expect(errorReporter.hasErrors, isTrue);
    });
  });

  group('ViewsParser._parseInheritance', () {
    test('should parse baseOn inheritance', () {
      // Arrange
      final tokens = [
        Token(TokenType.baseOn, 'baseOn', SourcePosition(0, 6, 0, 0)),
        Token(TokenType.string, '"BaseView"', SourcePosition(7, 10, 0, 7)),
        Token(TokenType.eof, '', SourcePosition(18, 0, 0, 18)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        Token(TokenType.filteredView, 'filtered', SourcePosition(8, 8, 1, 0)),
        Token(TokenType.string, '"FilteredView"', SourcePosition(17, 13, 1, 9)),
        Token(TokenType.leftBrace, '{', SourcePosition(31, 1, 1, 23)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(51, 1, 3, 0)),
        Token(TokenType.rightBrace, '}', SourcePosition(53, 1, 4, 0)),
        Token(TokenType.eof, '', SourcePosition(54, 0, 4, 1)),
      ]);

      // Assert
      expect(viewsNode.filteredViews, hasLength(1));
      final viewNode = viewsNode.filteredViews[0];
      expect(viewNode.baseViewKey, equals('BaseView'));
    });

    test('should handle missing baseOn value', () {
      // Arrange
      final tokens = [
        Token(TokenType.baseOn, 'baseOn', SourcePosition(0, 6, 0, 0)),
        // Missing string token
        Token(TokenType.rightBrace, '}', SourcePosition(7, 1, 0, 7)),
        Token(TokenType.eof, '', SourcePosition(8, 0, 0, 8)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        Token(TokenType.filteredView, 'filtered', SourcePosition(8, 8, 1, 0)),
        Token(TokenType.string, '"FilteredView"', SourcePosition(17, 13, 1, 9)),
        Token(TokenType.leftBrace, '{', SourcePosition(31, 1, 1, 23)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(39, 1, 3, 0)),
        Token(TokenType.eof, '', SourcePosition(40, 0, 3, 1)),
      ]);

      // Assert
      expect(errorReporter.hasErrors, isTrue);
    });
  });

  group('ViewsParser._parseIncludeExclude', () {
    test('should parse include statement', () {
      // Arrange
      final tokens = [
        Token(TokenType.include, 'include', SourcePosition(0, 7, 0, 0)),
        Token(TokenType.wildcard, '*', SourcePosition(8, 1, 0, 8)),
        Token(TokenType.eof, '', SourcePosition(10, 0, 0, 10)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        Token(TokenType.systemContext, 'systemContext', SourcePosition(8, 13, 1, 0)),
        Token(TokenType.identifier, 'system', SourcePosition(22, 6, 1, 14)),
        Token(TokenType.string, '"Title"', SourcePosition(29, 7, 1, 21)),
        Token(TokenType.leftBrace, '{', SourcePosition(37, 1, 1, 29)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(49, 1, 3, 0)),
        Token(TokenType.rightBrace, '}', SourcePosition(51, 1, 4, 0)),
        Token(TokenType.eof, '', SourcePosition(52, 0, 4, 1)),
      ]);

      // Assert
      expect(viewsNode.systemContextViews, hasLength(1));
      final viewNode = viewsNode.systemContextViews[0];
      expect(viewNode.includes, hasLength(1));
      expect(viewNode.includes[0].expression, equals('*'));
    });

    test('should parse include with identifier', () {
      // Arrange
      final tokens = [
        Token(TokenType.include, 'include', SourcePosition(0, 7, 0, 0)),
        Token(TokenType.identifier, 'user', SourcePosition(8, 4, 0, 8)),
        Token(TokenType.eof, '', SourcePosition(13, 0, 0, 13)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        Token(TokenType.systemContext, 'systemContext', SourcePosition(8, 13, 1, 0)),
        Token(TokenType.identifier, 'system', SourcePosition(22, 6, 1, 14)),
        Token(TokenType.string, '"Title"', SourcePosition(29, 7, 1, 21)),
        Token(TokenType.leftBrace, '{', SourcePosition(37, 1, 1, 29)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(52, 1, 3, 0)),
        Token(TokenType.rightBrace, '}', SourcePosition(54, 1, 4, 0)),
        Token(TokenType.eof, '', SourcePosition(55, 0, 4, 1)),
      ]);

      // Assert
      expect(viewsNode.systemContextViews, hasLength(1));
      final viewNode = viewsNode.systemContextViews[0];
      expect(viewNode.includes, hasLength(1));
      expect(viewNode.includes[0].expression, equals('user'));
    });

    test('should parse exclude statement', () {
      // Arrange
      final tokens = [
        Token(TokenType.exclude, 'exclude', SourcePosition(0, 7, 0, 0)),
        Token(TokenType.identifier, 'database', SourcePosition(8, 8, 0, 8)),
        Token(TokenType.eof, '', SourcePosition(17, 0, 0, 17)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        Token(TokenType.systemContext, 'systemContext', SourcePosition(8, 13, 1, 0)),
        Token(TokenType.identifier, 'system', SourcePosition(22, 6, 1, 14)),
        Token(TokenType.string, '"Title"', SourcePosition(29, 7, 1, 21)),
        Token(TokenType.leftBrace, '{', SourcePosition(37, 1, 1, 29)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(56, 1, 3, 0)),
        Token(TokenType.rightBrace, '}', SourcePosition(58, 1, 4, 0)),
        Token(TokenType.eof, '', SourcePosition(59, 0, 4, 1)),
      ]);

      // Assert
      expect(viewsNode.systemContextViews, hasLength(1));
      final viewNode = viewsNode.systemContextViews[0];
      expect(viewNode.excludes, hasLength(1));
      expect(viewNode.excludes[0].expression, equals('database'));
    });

    test('should handle missing include/exclude expression', () {
      // Arrange
      final tokens = [
        Token(TokenType.include, 'include', SourcePosition(0, 7, 0, 0)),
        // Missing wildcard or identifier
        Token(TokenType.rightBrace, '}', SourcePosition(8, 1, 0, 8)),
        Token(TokenType.eof, '', SourcePosition(9, 0, 0, 9)),
      ];

      // Act
      final viewsNode = viewsParser.parse([
        Token(TokenType.views, 'views', SourcePosition(0, 5, 0, 0)),
        Token(TokenType.leftBrace, '{', SourcePosition(6, 1, 0, 6)),
        Token(TokenType.systemContext, 'systemContext', SourcePosition(8, 13, 1, 0)),
        Token(TokenType.identifier, 'system', SourcePosition(22, 6, 1, 14)),
        Token(TokenType.string, '"Title"', SourcePosition(29, 7, 1, 21)),
        Token(TokenType.leftBrace, '{', SourcePosition(37, 1, 1, 29)),
        ...tokens,
        Token(TokenType.rightBrace, '}', SourcePosition(47, 1, 3, 0)),
        Token(TokenType.eof, '', SourcePosition(48, 0, 3, 1)),
      ]);

      // Assert
      expect(errorReporter.hasErrors, isTrue);
    });
  });

  group('ViewsNode extensions', () {
    test('should add a system context view to a ViewsNode', () {
      // Arrange
      final viewsNode = ViewsNode();
      final systemContextView = SystemContextViewNode(
        key: 'system',
        systemId: 'system',
        title: 'System Context',
      );

      // Act
      final updatedNode = viewsNode.addSystemContextView(systemContextView);

      // Assert
      expect(updatedNode.systemContextViews, hasLength(1));
      expect(updatedNode.systemContextViews[0], equals(systemContextView));
    });

    test('should add a container view to a ViewsNode', () {
      // Arrange
      final viewsNode = ViewsNode();
      final containerView = ContainerViewNode(
        key: 'system',
        systemId: 'system',
        title: 'Containers',
      );

      // Act
      final updatedNode = viewsNode.addContainerView(containerView);

      // Assert
      expect(updatedNode.containerViews, hasLength(1));
      expect(updatedNode.containerViews[0], equals(containerView));
    });

    test('should add a filtered view to a ViewsNode', () {
      // Arrange
      final viewsNode = ViewsNode();
      final filteredView = FilteredViewNode(
        key: 'filtered',
        baseViewKey: 'system',
        title: 'Filtered View',
      );

      // Act
      final updatedNode = viewsNode.addFilteredView(filteredView);

      // Assert
      expect(updatedNode.filteredViews, hasLength(1));
      expect(updatedNode.filteredViews[0], equals(filteredView));
    });
  });

  // Note: ViewNode.setProperty is not directly testable as it's implemented
  // implicitly through the view's constructor. We've already tested this
  // functionality in the _parseViewProperty tests.
}