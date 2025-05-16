import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast.dart';
import 'package:flutter_structurizr/domain/parser/include_parser.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_nodes.dart';
import 'package:flutter_structurizr/domain/parser/context_stack.dart';

void main() {
  group('Include directive tests', () {
    late Directory tempDir;
    
    setUp(() {
      // Create a temporary directory for test files
      tempDir = Directory.systemTemp.createTempSync('structurizr_test_');
    });
    
    tearDown(() {
      // Clean up the temporary directory
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    
    test('Parser detects include directives', () {
      // Create a DSL file with an include directive
      final mainFile = File(path.join(tempDir.path, 'main.dsl'));
      mainFile.writeAsStringSync('''
        !include included.dsl
        
        workspace "Main Workspace" {
          model {
            person "User"
          }
        }
      ''');
      
      // Create the included file
      final includedFile = File(path.join(tempDir.path, 'included.dsl'));
      includedFile.writeAsStringSync('''
        // This is an included file
        // It's just a comment for testing purposes
      ''');
      
      // Parse the main file
      final parser = Parser.fromFile(mainFile.path);
      final workspace = parser.parse();
      
      // Assert that the include directive was detected
      expect(workspace.directives, isNotNull);
      expect(workspace.directives!.length, equals(1));
      expect(workspace.directives![0].type, equals('include'));
      expect(workspace.directives![0].value, equals('included.dsl'));
    });
    
    test('Parser correctly processes nested include directives', () {
      // Create main file
      final mainFile = File(path.join(tempDir.path, 'main.dsl'));
      mainFile.writeAsStringSync('''
        !include level1.dsl
        
        workspace "Main Workspace" {
          model {
            person "User"
          }
        }
      ''');
      
      // Create first level include
      final level1File = File(path.join(tempDir.path, 'level1.dsl'));
      level1File.writeAsStringSync('''
        // Level 1 include
        !include level2.dsl
      ''');
      
      // Create second level include
      final level2File = File(path.join(tempDir.path, 'level2.dsl'));
      level2File.writeAsStringSync('''
        // Level 2 include
        // Just a comment for testing
      ''');
      
      // Parse the main file
      final parser = Parser.fromFile(mainFile.path);
      final workspace = parser.parse();
      
      // Assert that both include directives were processed
      expect(workspace.directives, isNotNull);
      expect(workspace.directives!.length, equals(2));
      
      // First directive should be from main.dsl
      expect(workspace.directives![0].type, equals('include'));
      expect(workspace.directives![0].value, equals('level1.dsl'));
      
      // Second directive should be from level1.dsl
      expect(workspace.directives![1].type, equals('include'));
      expect(workspace.directives![1].value, equals('level2.dsl'));
    });
    
    test('Parser handles model elements in included files', () {
      // Create main file
      final mainFile = File(path.join(tempDir.path, 'main.dsl'));
      mainFile.writeAsStringSync('''
        !include systems.dsl
        
        workspace "Banking System" {
          model {
            user = person "Customer"
            
            // The systems are defined in the included file
            user -> internetBanking "Uses"
          }
        }
      ''');
      
      // Create systems file with software systems
      final systemsFile = File(path.join(tempDir.path, 'systems.dsl'));
      systemsFile.writeAsStringSync('''
        // Define the banking systems
        internetBanking = softwareSystem "Internet Banking System" {
          webapp = container "Web Application"
        }
      ''');
      
      // Parse the main file
      // Note: A full merge of the model elements is not implemented in this test
      // but we're verifying the directives are correctly processed
      final parser = Parser.fromFile(mainFile.path);
      final workspace = parser.parse();
      
      // Assert that the include directive was processed
      expect(workspace.directives, isNotNull);
      expect(workspace.directives!.length, equals(1));
      expect(workspace.directives![0].value, equals('systems.dsl'));
      
      // The actual merging of model elements would be handled by the workspace builder
      // and is not tested here as it requires additional implementation
    });
    
    test('Parser handles missing included files gracefully', () {
      // Create a DSL file with an include directive to a non-existent file
      final mainFile = File(path.join(tempDir.path, 'main.dsl'));
      mainFile.writeAsStringSync('''
        !include non_existent.dsl
        
        workspace "Main Workspace" {
          model {
            person "User"
          }
        }
      ''');
      
      // Parse the main file
      final parser = Parser.fromFile(mainFile.path);
      final workspace = parser.parse();
      
      // The parser should still work and create a valid workspace
      expect(workspace.name, equals('Main Workspace'));
      expect(workspace.model, isNotNull);
      expect(workspace.model!.people.length, equals(1));
      
      // The directive should be recorded but not processed successfully
      expect(workspace.directives, isNotNull);
      expect(workspace.directives!.length, equals(1));
      expect(workspace.directives![0].value, equals('non_existent.dsl'));
      
      // Check that error reporter has error message for missing file
      expect(parser.errorReporter.hasErrors, isTrue);
    });
    
    test('Parser handles multiple include directives in a single file', () {
      // Create main file with multiple includes
      final mainFile = File(path.join(tempDir.path, 'main.dsl'));
      mainFile.writeAsStringSync('''
        !include systems.dsl
        !include people.dsl
        
        workspace "Multi-Include Test" {
          model {
            // Elements defined in included files
          }
        }
      ''');
      
      // Create included files
      final systemsFile = File(path.join(tempDir.path, 'systems.dsl'));
      systemsFile.writeAsStringSync('''
        // Systems definitions
        system1 = softwareSystem "System One"
      ''');
      
      final peopleFile = File(path.join(tempDir.path, 'people.dsl'));
      peopleFile.writeAsStringSync('''
        // People definitions
        user1 = person "User One"
      ''');
      
      // Parse the main file
      final parser = Parser.fromFile(mainFile.path);
      final workspace = parser.parse();
      
      // Assert that both include directives were processed
      expect(workspace.directives, isNotNull);
      expect(workspace.directives!.length, equals(2));
      
      // Verify the directives in the correct order
      expect(workspace.directives![0].value, equals('systems.dsl'));
      expect(workspace.directives![1].value, equals('people.dsl'));
    });
    
    test('Parser processes include directives inside model blocks', () {
      // Create main file with includes inside model block
      final mainFile = File(path.join(tempDir.path, 'main.dsl'));
      mainFile.writeAsStringSync('''
        workspace "Nested Include Test" {
          model {
            !include model_elements.dsl
            
            // Additional model elements
            person "Direct Person"
          }
        }
      ''');
      
      // Create included file with model elements
      final elementsFile = File(path.join(tempDir.path, 'model_elements.dsl'));
      elementsFile.writeAsStringSync('''
        // Model elements
        softwareSystem "Included System"
      ''');
      
      // Parse the main file
      final parser = Parser.fromFile(mainFile.path);
      final workspace = parser.parse();
      
      // Assert that the include directive was processed
      expect(workspace.directives, isNotNull);
      expect(workspace.directives!.length, equals(1));
      expect(workspace.directives![0].value, equals('model_elements.dsl'));
      
      // The actual merging of model elements would be handled by the workspace builder
      // and is not tested here
    });
    
    test('Parser processes include directives at different nesting levels', () {
      // Create main file with includes at different levels
      final mainFile = File(path.join(tempDir.path, 'main.dsl'));
      mainFile.writeAsStringSync('''
        !include top_level.dsl
        
        workspace "Multi-Level Test" {
          !include workspace_level.dsl
          
          model {
            !include model_level.dsl
            
            softwareSystem "System" {
              !include system_level.dsl
            }
          }
        }
      ''');
      
      // Create included files
      File(path.join(tempDir.path, 'top_level.dsl')).writeAsStringSync('// Top level include');
      File(path.join(tempDir.path, 'workspace_level.dsl')).writeAsStringSync('// Workspace level include');
      File(path.join(tempDir.path, 'model_level.dsl')).writeAsStringSync('// Model level include');
      File(path.join(tempDir.path, 'system_level.dsl')).writeAsStringSync('// System level include');
      
      // Parse the main file
      final parser = Parser.fromFile(mainFile.path);
      final workspace = parser.parse();
      
      // Assert that all include directives were processed
      expect(workspace.directives, isNotNull);
      expect(workspace.directives!.length, equals(4));
      
      // Verify the directive values
      final directiveValues = workspace.directives!.map((d) => d.value).toList();
      expect(directiveValues, contains('top_level.dsl'));
      expect(directiveValues, contains('workspace_level.dsl'));
      expect(directiveValues, contains('model_level.dsl'));
      expect(directiveValues, contains('system_level.dsl'));
    });
    
    test('Parser processes include directives in views section', () {
      // Create main file with includes in views
      final mainFile = File(path.join(tempDir.path, 'main.dsl'));
      mainFile.writeAsStringSync('''
        workspace "Views Include Test" {
          model {
            system = softwareSystem "System"
          }
          
          views {
            !include views_include.dsl
            
            systemContext system "SystemContext" {
              include *
              autoLayout
            }
          }
        }
      ''');
      
      // Create included file with view definitions
      final viewsFile = File(path.join(tempDir.path, 'views_include.dsl'));
      viewsFile.writeAsStringSync('''
        // Views definitions
        styles {
          element "Software System" {
            background #1168bd
            color #ffffff
          }
        }
      ''');
      
      // Parse the main file
      final parser = Parser.fromFile(mainFile.path);
      final workspace = parser.parse();
      
      // Assert that the include directive was processed
      expect(workspace.directives, isNotNull);
      expect(workspace.directives!.length, equals(1));
      expect(workspace.directives![0].value, equals('views_include.dsl'));
    });
    
    test('Parser handles complex include with circular references', () {
      // Create main file with complex include structure
      final mainFile = File(path.join(tempDir.path, 'main.dsl'));
      mainFile.writeAsStringSync('''
        !include circular1.dsl
        
        workspace "Circular Test" {
          model {
            person "User"
          }
        }
      ''');
      
      // Create circular reference files
      File(path.join(tempDir.path, 'circular1.dsl')).writeAsStringSync('!include circular2.dsl');
      File(path.join(tempDir.path, 'circular2.dsl')).writeAsStringSync('!include circular3.dsl');
      File(path.join(tempDir.path, 'circular3.dsl')).writeAsStringSync('!include circular1.dsl');
      
      // Parse the main file - should detect circular references but not crash
      final parser = Parser.fromFile(mainFile.path);
      final workspace = parser.parse();
      
      // Should still create a valid workspace
      expect(workspace.name, equals('Circular Test'));
      
      // Should report circular reference errors
      expect(parser.errorReporter.hasErrors, isTrue);
      expect(
        parser.errorReporter.errors.any((error) => 
          error.message.contains('Circular')),
        isTrue,
      );
    });
    
    test('Parser correctly identifies include type', () {
      // Create test files
      final mainFile = File(path.join(tempDir.path, 'main.dsl'));
      mainFile.writeAsStringSync('''
        workspace "Include Type Test" {
          model {
            user = person "User"
            system = softwareSystem "System"
          }
          
          views {
            systemContext system "SystemContext" {
              include user
              autoLayout
            }
          }
        }
      ''');
      
      // Parse the file
      final parser = Parser.fromFile(mainFile.path);
      final workspace = parser.parse();
      
      // Get the system context view
      final systemContextView = workspace.views?.systemContextViews.first;
      expect(systemContextView, isNotNull);
      
      // Check the include type is correct (should be view type)
      final includeNode = systemContextView!.includes.first;
      expect(includeNode.type, equals(IncludeType.view));
      expect(includeNode.expression, equals('user'));
    });
    
    test('Context stack is properly maintained during include parsing', () {
      // This is a placeholder for when ContextStack is fully integrated
      // Create a context stack
      final contextStack = ContextStack();
      
      // The context stack would be used by the parser, pushed and popped
      // as the parser navigates through the include directives
      contextStack.push(Context('workspace'));
      contextStack.push(Context('model'));
      contextStack.push(Context('include'));
      
      // Verify the stack state
      expect(contextStack.size(), equals(3));
      expect(contextStack.current().name, equals('include'));
      
      // Pop back to the model context
      contextStack.pop();
      expect(contextStack.current().name, equals('model'));
      
      // The real implementation would navigate the contexts as it parses
    });
    
    test('IncludeNode.setType method works correctly', () {
      // Create an include node
      final includeNode = IncludeNode(expression: 'test.dsl');
      
      // Initially the type should be null
      expect(includeNode.type, isNull);
      
      // Set to file type
      includeNode.setType(IncludeType.file);
      expect(includeNode.type, equals(IncludeType.file));
      
      // Change to view type
      includeNode.setType(IncludeType.view);
      expect(includeNode.type, equals(IncludeType.view));
    });
    
    test('Parser handles include directives with spaces and special characters', () {
      // Create a DSL file with include paths containing spaces and special chars
      final mainFile = File(path.join(tempDir.path, 'main.dsl'));
      mainFile.writeAsStringSync('''
        !include "path with spaces.dsl"
        !include 'single_quoted.dsl'
        !include path-with-dashes.dsl
        !include path_with_underscores.dsl
        
        workspace "Special Chars Test" {
          model {}
        }
      ''');
      
      // Create the included files
      File(path.join(tempDir.path, 'path with spaces.dsl')).writeAsStringSync('// File with spaces in name');
      File(path.join(tempDir.path, 'single_quoted.dsl')).writeAsStringSync('// Single quoted file');
      File(path.join(tempDir.path, 'path-with-dashes.dsl')).writeAsStringSync('// File with dashes in name');
      File(path.join(tempDir.path, 'path_with_underscores.dsl')).writeAsStringSync('// File with underscores in name');
      
      // Parse the main file
      final parser = Parser.fromFile(mainFile.path);
      final workspace = parser.parse();
      
      // Assert that all include directives were processed
      expect(workspace.directives, isNotNull);
      expect(workspace.directives!.length, equals(4));
      
      // Verify the directives have correct paths
      final directiveValues = workspace.directives!.map((d) => d.value).toList();
      expect(directiveValues, contains('path with spaces.dsl'));
      expect(directiveValues, contains('single_quoted.dsl'));
      expect(directiveValues, contains('path-with-dashes.dsl'));
      expect(directiveValues, contains('path_with_underscores.dsl'));
    });
  });
}