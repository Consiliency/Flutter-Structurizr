import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/lexer/token.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/ast/ast_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/domain/parser/views_parser.dart';

void main() {
  // These tests are designed to verify the integration of ViewsParser
  // with the rest of the Parser infrastructure. They will only pass
  // once the actual implementation of ViewsParser is complete.
  // 
  // For now, we mark them all as "skip: true" to prevent them from
  // failing in test runs. Once the implementation is complete, remove
  // the skip: true parameter.
  group('ViewsParser Integration Tests', () {
    test('Parser should handle basic views block', () {
      // Prepare test data
      final dsl = '''
        workspace "Test Workspace" {
          model {
            user = person "User"
            system = softwareSystem "System" {
              webapp = container "Web Application"
              database = container "Database"
            }
            user -> system "Uses"
            webapp -> database "Reads from and writes to"
          }
          
          views {
            systemContext system "SystemContext" {
              include *
              autoLayout
            }
            
            containerView system "Containers" {
              include *
              autoLayout
            }
          }
        }
      ''';
      
      // Parse the DSL
      final parser = Parser(dsl);
      final workspace = parser.parse();
      
      // Verify results
      expect(workspace.views, isNotNull);
      expect(workspace.views!.systemContextViews.length, equals(1));
      expect(workspace.views!.containerViews.length, equals(1));
      
      final systemContextView = workspace.views!.systemContextViews[0];
      expect(systemContextView.key, equals('system'));
      expect(systemContextView.title, equals('SystemContext'));
      expect(systemContextView.autoLayout, isNotNull);
      
      final containerView = workspace.views!.containerViews[0];
      expect(containerView.key, equals('system'));
      expect(containerView.title, equals('Containers'));
      expect(containerView.autoLayout, isNotNull);
    });
    
    test('Parser should handle view properties', () {
      // Prepare test data
      final dsl = '''
        workspace "Test Workspace" {
          model {
            user = person "User"
            system = softwareSystem "System"
            user -> system "Uses"
          }
          
          views {
            systemContext system "SystemContext" "System Context diagram" {
              include *
              autoLayout tb 300 150
            }
          }
        }
      ''';
      
      // Parse the DSL
      final parser = Parser(dsl);
      final workspace = parser.parse();
      
      // Verify results
      expect(workspace.views, isNotNull);
      expect(workspace.views!.systemContextViews.length, equals(1));
      
      final systemContextView = workspace.views!.systemContextViews[0];
      expect(systemContextView.key, equals('system'));
      expect(systemContextView.title, equals('SystemContext'));
      expect(systemContextView.description, equals('System Context diagram'));
      
      // Verify auto layout properties
      expect(systemContextView.autoLayout, isNotNull);
      expect(systemContextView.autoLayout!.rankDirection, equals('tb'));
      expect(systemContextView.autoLayout!.rankSeparation, equals(300));
      expect(systemContextView.autoLayout!.nodeSeparation, equals(150));
    });
    
    test('Parser should handle include and exclude statements', () {
      // Prepare test data
      final dsl = '''
        workspace "Test Workspace" {
          model {
            user = person "User"
            admin = person "Admin"
            system = softwareSystem "System" {
              webapp = container "Web Application"
              database = container "Database"
            }
            
            user -> system "Uses"
            admin -> system "Administers"
            webapp -> database "Reads from and writes to"
          }
          
          views {
            systemContext system "SystemContext" {
              include user
              include system
              exclude admin
            }
            
            containerView system "Containers" {
              include *
              exclude database
            }
          }
        }
      ''';
      
      // Parse the DSL
      final parser = Parser(dsl);
      final workspace = parser.parse();
      
      // Verify results
      expect(workspace.views, isNotNull);
      expect(workspace.views!.systemContextViews.length, equals(1));
      expect(workspace.views!.containerViews.length, equals(1));
      
      final systemContextView = workspace.views!.systemContextViews[0];
      expect(systemContextView.includes.length, equals(2));
      expect(systemContextView.includes[0].expression, equals('user'));
      expect(systemContextView.includes[1].expression, equals('system'));
      expect(systemContextView.excludes.length, equals(1));
      expect(systemContextView.excludes[0].expression, equals('admin'));
      
      final containerView = workspace.views!.containerViews[0];
      expect(containerView.includes.length, equals(1));
      expect(containerView.includes[0].expression, equals('*'));
      expect(containerView.excludes.length, equals(1));
      expect(containerView.excludes[0].expression, equals('database'));
    });
    
    test('Parser should handle animations', () {
      // Prepare test data
      final dsl = '''
        workspace "Test Workspace" {
          model {
            user = person "User"
            system = softwareSystem "System" {
              webapp = container "Web Application"
              database = container "Database"
            }
            
            user -> system "Uses"
            webapp -> database "Reads from and writes to"
          }
          
          views {
            systemContext system "SystemContext" {
              include *
              animation {
                user
              }
              
              animation {
                system
              }
            }
          }
        }
      ''';
      
      // Parse the DSL
      final parser = Parser(dsl);
      final workspace = parser.parse();
      
      // Verify results
      expect(workspace.views, isNotNull);
      expect(workspace.views!.systemContextViews.length, equals(1));
      
      final systemContextView = workspace.views!.systemContextViews[0];
      expect(systemContextView.animations.length, equals(2));
      expect(systemContextView.animations[0].elements.length, equals(1));
      expect(systemContextView.animations[0].elements[0], equals('user'));
      expect(systemContextView.animations[1].elements.length, equals(1));
      expect(systemContextView.animations[1].elements[0], equals('system'));
    });
    
    test('Parser should handle view inheritance', () {
      // Prepare test data
      final dsl = '''
        workspace "Test Workspace" {
          model {
            user = person "User"
            system = softwareSystem "System" {
              webapp = container "Web Application"
              database = container "Database"
            }
            
            user -> system "Uses"
            webapp -> database "Reads from and writes to"
          }
          
          views {
            systemContext system "SystemContext" {
              include *
              autoLayout
            }
            
            filteredView "UserOnly" {
              baseOn "SystemContext"
              include user
            }
          }
        }
      ''';
      
      // Parse the DSL
      final parser = Parser(dsl);
      final workspace = parser.parse();
      
      // Verify results
      expect(workspace.views, isNotNull);
      expect(workspace.views!.systemContextViews.length, equals(1));
      expect(workspace.views!.filteredViews.length, equals(1));
      
      final filteredView = workspace.views!.filteredViews[0];
      expect(filteredView.key, equals('UserOnly'));
      expect(filteredView.baseViewKey, equals('SystemContext'));
      expect(filteredView.includes.length, equals(1));
      expect(filteredView.includes[0].expression, equals('user'));
    });
  });
}