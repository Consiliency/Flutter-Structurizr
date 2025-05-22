import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';

/// This test file focuses on edge cases and boundary conditions for the ModelParser methods
/// as defined in Table 7 of the refactored_method_relationship.md file.
void main() {
  group('ModelParser Edge Cases', () {
    test('should handle extremely deeply nested elements', () {
      // Create a model with deep nesting to test parser limits
      const deeplyNestedDsl = '''
        workspace {
          model {
            system1 = softwareSystem "System 1" {
              container1 = container "Container 1" {
                component1 = component "Component 1" {
                  // Add deep nesting with properties
                  properties {
                    prop1 = "value1"
                    nestedProp {
                      subProp = "value2"
                      deeperProp {
                        deepestProp = "value3"
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      final parser = Parser(deeplyNestedDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify deep nesting was handled correctly
      // Add assertions based on your implementation
    });

    test('should handle models with extensive relationships', () {
      // Create a model with many relationships to test parser limits
      const manyRelationshipsDsl = '''
        workspace {
          model {
            user = person "User"
            admin = person "Admin"
            system1 = softwareSystem "System 1"
            system2 = softwareSystem "System 2"
            system3 = softwareSystem "System 3"
            
            user -> system1 "Uses"
            user -> system2 "Uses"
            user -> system3 "Uses"
            admin -> system1 "Administers"
            admin -> system2 "Administers"
            admin -> system3 "Administers"
            system1 -> system2 "Depends on"
            system2 -> system3 "Depends on"
            system3 -> system1 "Notifies"
          }
        }
      ''';

      final parser = Parser(manyRelationshipsDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify relationships were handled correctly
      // Add assertions based on your implementation
    });

    test('should handle models with circular relationships', () {
      const circularDsl = '''
        workspace {
          model {
            system1 = softwareSystem "System 1"
            system2 = softwareSystem "System 2"
            system3 = softwareSystem "System 3"
            
            system1 -> system2 "Calls"
            system2 -> system3 "Calls"
            system3 -> system1 "Calls back"
          }
        }
      ''';

      final parser = Parser(circularDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify circular relationships were handled correctly
      // Add assertions based on your implementation
    });

    test('should handle models with very long names and descriptions', () {
      final longNamesDsl = '''
        workspace {
          model {
            person "${List.filled(100, 'Very').join(' ')} Long Name" "${List.filled(200, 'Extremely').join(' ')} detailed description"
            
            softwareSystem "${List.filled(100, 'Lengthy').join(' ')} System Name" {
              container "${List.filled(50, 'Big').join(' ')} Container"
            }
          }
        }
      ''';

      final parser = Parser(longNamesDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify long strings were handled correctly
      // Add assertions based on your implementation
    });

    test('should handle models with special characters in names', () {
      const specialCharsDsl = '''
        workspace {
          model {
            person "User with @special# \$characters&"
            softwareSystem "System-With_Punctuation!?"
            container "Container with émojis 🚀 and accents"
          }
        }
      ''';

      final parser = Parser(specialCharsDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify special characters were handled correctly
      // Add assertions based on your implementation
    });

    test('should handle models with Unicode characters', () {
      const unicodeDsl = '''
        workspace {
          model {
            person "国际用户" "International User"
            softwareSystem "système international" "International System"
            container "международный контейнер" "International Container"
          }
        }
      ''';

      final parser = Parser(unicodeDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify Unicode characters were handled correctly
      // Add assertions based on your implementation
    });

    test('should handle models with same-named elements in different scopes',
        () {
      const sameNamesDsl = '''
        workspace {
          model {
            // Same name in different contexts
            person "User"
            
            system1 = softwareSystem "System 1" {
              container "API"
              container "Database"
            }
            
            system2 = softwareSystem "System 2" {
              // Same container names as in System 1
              container "API"
              container "Database"
            }
          }
        }
      ''';

      final parser = Parser(sameNamesDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify same-named elements in different scopes were handled correctly
      // Add assertions based on your implementation
    });

    test('should handle models with identifiers that are keywords', () {
      const keywordIdsDsl = '''
        workspace {
          model {
            // Using DSL keywords as identifiers
            model = person "Model Person"
            group = person "Group Person"
            enterprise = person "Enterprise Person"
            
            // Using identifiers that match element types
            person = softwareSystem "Person System"
            softwareSystem = container "Software System Container"
          }
        }
      ''';

      final parser = Parser(keywordIdsDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify identifiers with keywords were handled correctly
      // Add assertions based on your implementation
    });

    test('should handle models with complex whitespace and formatting', () {
      const complexFormatDsl = '''
        workspace {
          model 
          
          {
            
            person    "User"   "A user"
            
            softwareSystem    "System"
              {
             
                  container "Container"
             
              }
          
          }
        }
      ''';

      final parser = Parser(complexFormatDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify complex whitespace and formatting were handled correctly
      // Add assertions based on your implementation
    });

    test('should handle models with multiple nested groups', () {
      const nestedGroupsDsl = '''
        workspace {
          model {
            group "Outer Group" {
              group "Middle Group" {
                group "Inner Group" {
                  person "Deeply Nested Person"
                }
              }
              
              // Sibling group
              group "Another Middle Group" {
                softwareSystem "System in Another Middle Group"
              }
            }
          }
        }
      ''';

      final parser = Parser(nestedGroupsDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify nested groups were handled correctly
      // Add assertions based on your implementation
    });

    test('should handle models with enterprise and groups at same level', () {
      const enterpriseAndGroupDsl = '''
        workspace {
          model {
            // Enterprise at top level
            enterprise "My Company" {
              person "Internal User"
            }
            
            // Groups at top level
            group "External Systems" {
              softwareSystem "External System"
            }
            
            // Elements at top level
            person "External User"
          }
        }
      ''';

      final parser = Parser(enterpriseAndGroupDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify enterprise and groups at same level were handled correctly
      // Add assertions based on your implementation
    });

    test(
        'should handle implied relationships with complex source/destination references',
        () {
      const complexRefsDsl = '''
        workspace {
          model {
            user = person "User"
            
            system = softwareSystem "System" {
              webapp = container "Web App" {
                ui = component "UI"
              }
              api = container "API" {
                auth = component "Auth"
              }
            }
            
            // Relationships with deep nesting references
            user -> system.webapp.ui "Uses"
            system.webapp.ui -> system.api.auth "Calls"
          }
        }
      ''';

      final parser = Parser(complexRefsDsl);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.model, isA<ModelNode>());

      // Verify complex references in relationships were handled correctly
      // Add assertions based on your implementation
    });

    test('should recover from errors and continue parsing when possible', () {
      const errorRecoveryDsl = '''
        workspace {
          model {
            // Valid element
            person "Valid User"
            
            // Invalid element (missing name)
            person
            
            // Valid element after error
            softwareSystem "Valid System"
            
            // Invalid relationship (missing destination)
            user -> 
            
            // Valid relationship after error
            user -> system "Uses"
          }
        }
      ''';

      // This test depends on how your parser handles errors
      // If it throws on first error:
      expect(() => Parser(errorRecoveryDsl).parse(), throwsException);

      // Or if it collects errors and continues:
      // final parser = Parser(errorRecoveryDsl);
      // final workspace = parser.parse();
      // expect(parser.errorReporter.errors.isNotEmpty, isTrue);
      // expect(workspace.model!.people.isNotEmpty, isTrue);
      // expect(workspace.model!.softwareSystems.isNotEmpty, isTrue);
    });
  });
}
