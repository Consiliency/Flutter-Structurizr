import 'package:flutter_structurizr/application/dsl/workspace_mapper.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/component.dart';
import 'package:flutter_structurizr/domain/model/container.dart';
import 'package:flutter_structurizr/domain/model/deployment_node.dart';
import 'package:flutter_structurizr/domain/model/infrastructure_node.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceMapper Reference Resolution', () {
    late ErrorReporter errorReporter;
    late WorkspaceMapper mapper;
    late Parser parser;

    setUp(() {
      const source = '';
      errorReporter = ErrorReporter(source);
      mapper = WorkspaceMapper(source, errorReporter);
    });

    test('resolves simple element references in relationships', () {
      // This test checks that basic references between elements work
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A user of the system"
            system = softwareSystem "System" "A system"
            
            relationship user system "Uses"
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);
      expect(workspace!.model.relationships, hasLength(1));

      final relationship = workspace.model.relationships.first;
      final sourceElement =
          workspace.model.getElementById(relationship.sourceId);
      final destinationElement =
          workspace.model.getElementById(relationship.destinationId);
      expect(sourceElement?.name, equals('User'));
      expect(destinationElement?.name, equals('System'));
    });

    test('resolves implicit relationships within elements', () {
      // This test checks the "this" keyword and relationships defined within elements
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A user of the system"
            system = softwareSystem "System" "A system" {
              user -> this "Uses"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);
      expect(workspace!.model.relationships, hasLength(1));

      final relationship = workspace.model.relationships.first;
      final sourceElement =
          workspace.model.getElementById(relationship.sourceId);
      final destinationElement =
          workspace.model.getElementById(relationship.destinationId);
      expect(sourceElement?.name, equals('User'));
      expect(destinationElement?.name, equals('System'));
    });

    test('resolves nested hierarchical relationships', () {
      // Test references between hierarchical elements
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A user of the system"
            system = softwareSystem "System" "A system" {
              webapp = container "Web Application" "A web application" {
                controller = component "Controller" "Handles HTTP requests"
              }
              
              database = container "Database" "Stores data"
              
              controller -> database "Reads from and writes to"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);

      // Find the controller and database elements
      final controller = workspace!.model.elements
          .whereType<Component>()
          .firstWhere((e) => e.name == 'Controller');

      final database = workspace.model.elements
          .whereType<Container>()
          .firstWhere((e) => e.name == 'Database');

      // Check if the relationship exists
      final relationship =
          workspace.model.findRelationshipBetween(controller.id, database.id);
      expect(relationship, isNotNull);

      expect(relationship!, isNotNull);
      expect(relationship.description, equals('Reads from and writes to'));
    });

    test('resolves parent-child relationships', () {
      // Test references between parents and children
      const source = '''
        workspace "Test Workspace" {
          model {
            system = softwareSystem "System" "A system" {
              webapp = container "Web Application" "A web application"
              database = container "Database" "Stores data"
              
              webapp -> database "Uses"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);

      // Find the webapp and database elements
      final webapp = workspace!.model.elements
          .whereType<Container>()
          .firstWhere((e) => e.name == 'Web Application');

      final database = workspace.model.elements
          .whereType<Container>()
          .firstWhere((e) => e.name == 'Database');

      // Check if the relationship exists
      final relationship =
          workspace.model.findRelationshipBetween(webapp.id, database.id);
      expect(relationship, isNotNull);

      expect(relationship!, isNotNull);
      expect(relationship.description, equals('Uses'));
    });

    test('resolves references to external elements', () {
      // Test references to elements defined outside the current block
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A user of the system"
            
            system = softwareSystem "System" "A system" {
              webapp = container "Web Application" "A web application"
              
              user -> webapp "Uses"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);

      // Find the user and webapp elements
      final user = workspace!.model.elements
          .whereType<Person>()
          .firstWhere((e) => e.name == 'User');

      final webapp = workspace.model.elements
          .whereType<Container>()
          .firstWhere((e) => e.name == 'Web Application');

      // Check if the relationship exists
      final relationship =
          workspace.model.findRelationshipBetween(user.id, webapp.id);
      expect(relationship, isNotNull);

      expect(relationship!, isNotNull);
      expect(relationship.description, equals('Uses'));
    });

    test('resolves references in deployment views', () {
      // Test references in deployment views and infrastructure
      const source = '''
        workspace "Test Workspace" {
          model {
            system = softwareSystem "System" "A system" {
              webapp = container "Web Application" "A web application"
              
              deploymentEnvironment "Production" {
                deploymentNode "AWS" {
                  webServer = deploymentNode "Web Server" {
                    containerInstance webapp
                  }
                  
                  database = infrastructureNode "Database" "Stores data"
                  
                  webServer -> database "Connects to"
                }
              }
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);

      // Find the system element to check its deployment environments
      final system = workspace!.model.elements
          .whereType<SoftwareSystem>()
          .firstWhere((e) => e.name == 'System');

      expect(system.deploymentEnvironments, hasLength(1));

      final environment = system.deploymentEnvironments.first;
      expect(environment.name, equals('Production'));

      // Find the deployment node by name
      DeploymentNode? webServer = null;
      for (final node in environment.deploymentNodes) {
        if (node.name == 'Web Server') {
          webServer = node;
          break;
        }
      }

      expect(webServer, isNotNull);
      expect(webServer!.containerInstances, hasLength(1));

      final containerInstance = webServer.containerInstances.first;
      expect(containerInstance.containerId, isNotNull);

      // Find infrastructure node by name
      InfrastructureNode? database = null;
      for (final node in environment.deploymentNodes) {
        for (final infra in node.infrastructureNodes) {
          if (infra.name == 'Database') {
            database = infra;
            break;
          }
        }
        if (database != null) break;
      }

      expect(database, isNotNull);

      // Verify relationship exists
      final relationship =
          workspace.model.findRelationshipBetween(webServer.id, database!.id);

      expect(relationship, isNotNull);
      expect(relationship!.description, equals('Connects to'));
    });

    test('resolves references in views', () {
      // Test references in view definitions
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A user of the system"
            system = softwareSystem "System" "A system"
          }
          
          views {
            systemContext system "SystemContext" "System Context View" {
              include user
              exclude *
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);
      expect(workspace!.views.systemContextViews, hasLength(1));

      final view = workspace.views.systemContextViews.first;
      expect(view.softwareSystemId, isNotNull);

      // Find the system element
      final system = workspace.model.elements
          .whereType<SoftwareSystem>()
          .firstWhere((e) => e.name == 'System');

      expect(view.softwareSystemId, equals(system.id));

      // Check include element reference
      expect(view.includeTags, isNotEmpty);
      expect(view.includeTags.any((tag) => tag == 'user'), isTrue);
    });

    test('reports error for undefined references', () {
      // Test error reporting for undefined references
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A user of the system"
            
            relationship user undefined "Uses"
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final mapper = WorkspaceMapper(source, parser.errorReporter);
      mapper.mapWorkspace(ast);

      expect(mapper.errorReporter.hasErrors, isTrue);
      expect(mapper.errorReporter.hasErrors, isTrue);
      expect(
          mapper.errorReporter.errors.any((e) =>
              e.message.toLowerCase().contains('destination') ||
              e.message.toLowerCase().contains('element reference not found') ||
              e.message.toLowerCase().contains('undefined')),
          isTrue);
    });

    test('handles circular references gracefully', () {
      // Test handling of circular references between elements
      const source = '''
        workspace "Test Workspace" {
          model {
            system1 = softwareSystem "System 1" "A system"
            system2 = softwareSystem "System 2" "Another system"
            
            system1 -> system2 "Uses"
            system2 -> system1 "Provides data to"
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);
      expect(workspace!.model.relationships, hasLength(2));

      final system1 = workspace.model.elements
          .whereType<SoftwareSystem>()
          .firstWhere((e) => e.name == 'System 1');

      final system2 = workspace.model.elements
          .whereType<SoftwareSystem>()
          .firstWhere((e) => e.name == 'System 2');

      // Verify both relationships exist
      final relationship1 =
          workspace.model.findRelationshipBetween(system1.id, system2.id);

      final relationship2 =
          workspace.model.findRelationshipBetween(system2.id, system1.id);

      expect(relationship1, isNotNull);
      expect(relationship2, isNotNull);
      expect(relationship1!.description, equals('Uses'));
      expect(relationship2!.description, equals('Provides data to'));
    });

    test('resolves scope in dynamic views', () {
      // Test dynamic view scope resolution
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A user of the system"
            system = softwareSystem "System" "A system" 
          }
          
          views {
            dynamic system "DynamicView" "Dynamic View" {
              user -> system "Uses"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);
      expect(workspace!.views.dynamicViews, hasLength(1));

      final view = workspace.views.dynamicViews.first;
      expect(view.elementId, isNotNull);

      // Find the system element
      final system = workspace.model.elements
          .whereType<SoftwareSystem>()
          .firstWhere((e) => e.name == 'System');

      expect(view.elementId, equals(system.id));
    });

    test('resolves references with special characters', () {
      // Test handling of special characters in identifiers
      const source = '''
        workspace "Test Workspace" {
          model {
            special_id = person "Special User" "User with special characters in ID"
            system-with-dashes = softwareSystem "System with dashes" "System description"
            
            relationship special_id system-with-dashes "Uses"
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);
      expect(workspace!.model.relationships, hasLength(1));

      final specialUser = workspace.model.elements
          .whereType<Person>()
          .firstWhere((e) => e.name == 'Special User');

      final systemWithDashes = workspace.model.elements
          .whereType<SoftwareSystem>()
          .firstWhere((e) => e.name == 'System with dashes');

      final relationship = workspace.model
          .findRelationshipBetween(specialUser.id, systemWithDashes.id);

      expect(relationship, isNotNull);
      expect(relationship!.description, equals('Uses'));
    });

    test('resolves filtered view base references', () {
      // Test filtered view references to base views
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A user of the system"
            system = softwareSystem "System" "A system"
            
            relationship user system "Uses"
          }
          
          views {
            systemContext system "SystemContext" {
              include *
            }
            
            filtered "SystemContext" "FilteredView" {
              include "user"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);
      expect(workspace!.views.systemContextViews, hasLength(1));
      expect(workspace.views.filteredViews, hasLength(1));

      final filteredView = workspace.views.filteredViews.first;
      expect(filteredView.baseViewKey, equals('SystemContext'));
    });

    test('handles complex reference chains', () {
      // Test chains of references through multiple levels
      const source = '''
        workspace "Test Workspace" {
          model {
            enterprise "Example Corp" {
              user = person "User" "A user of the system"

              internal = softwareSystem "Internal System" {
                web = container "Web Application" {
                  spa = component "SPA" "Single page application"
                  api = component "API" "Application API"
                  spa -> api "Makes API calls to"
                }

                core = container "Core System" {
                  service = component "Service" "Business logic"
                  repo = component "Repository" "Data access"
                  service -> repo "Uses"
                }

                api -> service "Forwards requests to"
              }

              user -> spa "Uses"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);
      expect(workspace!.model.enterpriseName, equals('Example Corp'));

      // Find all elements
      final user = workspace.model.findPersonByName('User');
      final spa = workspace.model.findComponentByName('SPA');
      final api = workspace.model.findComponentByName('API');
      final service = workspace.model.findComponentByName('Service');
      final repo = workspace.model.findComponentByName('Repository');

      expect(user, isNotNull);
      expect(spa, isNotNull);
      expect(api, isNotNull);
      expect(service, isNotNull);
      expect(repo, isNotNull);

      // Check all relationships are correctly resolved
      final userToSpa =
          workspace.model.findRelationshipBetween(user!.id, spa!.id);
      final spaToApi = workspace.model.findRelationshipBetween(spa.id, api!.id);
      final apiToService =
          workspace.model.findRelationshipBetween(api.id, service!.id);
      final serviceToRepo =
          workspace.model.findRelationshipBetween(service.id, repo!.id);

      expect(userToSpa, isNotNull);
      expect(spaToApi, isNotNull);
      expect(apiToService, isNotNull);
      expect(serviceToRepo, isNotNull);
    });

    test('resolves recursive "this" and "parent" references', () {
      // Test handling of "this" and "parent" references in deeply nested structures
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A user of the system"
            system = softwareSystem "System" "A system" {
              api = container "API" {
                controller = component "Controller" {
                  service = component "Service" {
                    repository = component "Repository" {
                      -> this "Self-reference"
                      -> parent "Uses parent service"
                      -> controller "Uses controller"
                      -> api "Uses API container"
                      -> system "Uses system"
                      -> user "Uses user"
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);

      // Find all elements
      final user = workspace!.model.findPersonByName('User');
      final system = workspace.model.findSoftwareSystemByName('System');
      final api = workspace.model.findContainerByName('API');
      final controller = workspace.model.findComponentByName('Controller');
      final service = workspace.model.findComponentByName('Service');
      final repository = workspace.model.findComponentByName('Repository');

      expect(user, isNotNull);
      expect(system, isNotNull);
      expect(api, isNotNull);
      expect(controller, isNotNull);
      expect(service, isNotNull);
      expect(repository, isNotNull);

      // Check all relationships are correctly resolved
      final selfReference = workspace.model
          .findRelationshipBetween(repository!.id, repository.id);
      final parentReference =
          workspace.model.findRelationshipBetween(repository.id, service!.id);
      final controllerReference = workspace.model
          .findRelationshipBetween(repository.id, controller!.id);
      final apiReference =
          workspace.model.findRelationshipBetween(repository.id, api!.id);
      final systemReference =
          workspace.model.findRelationshipBetween(repository.id, system!.id);
      final userReference =
          workspace.model.findRelationshipBetween(repository.id, user!.id);

      expect(selfReference, isNotNull);
      expect(parentReference, isNotNull);
      expect(controllerReference, isNotNull);
      expect(apiReference, isNotNull);
      expect(systemReference, isNotNull);
      expect(userReference, isNotNull);

      expect(selfReference!.description, equals('Self-reference'));
      expect(parentReference!.description, equals('Uses parent service'));
      expect(controllerReference!.description, equals('Uses controller'));
      expect(apiReference!.description, equals('Uses API container'));
      expect(systemReference!.description, equals('Uses system'));
      expect(userReference!.description, equals('Uses user'));
    });

    test('resolves references with similar names', () {
      // Test correct resolution of elements with similar names
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A regular user"
            userAdmin = person "User Administrator" "Manages users"
            admin = person "Administrator" "System administrator"

            user -> userAdmin "Reports to"
            userAdmin -> admin "Reports to"
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);
      expect(workspace!.model.people, hasLength(3));

      // Find people by their names
      final user = workspace.model.findPersonByName('User');
      final userAdmin = workspace.model.findPersonByName('User Administrator');
      final admin = workspace.model.findPersonByName('Administrator');

      expect(user, isNotNull);
      expect(userAdmin, isNotNull);
      expect(admin, isNotNull);

      // Check relationships
      final userToAdmin =
          workspace.model.findRelationshipBetween(user!.id, userAdmin!.id);
      final adminToSysAdmin =
          workspace.model.findRelationshipBetween(userAdmin.id, admin!.id);

      expect(userToAdmin, isNotNull);
      expect(adminToSysAdmin, isNotNull);
      expect(userToAdmin!.description, equals('Reports to'));
      expect(adminToSysAdmin!.description, equals('Reports to'));
    });

    test('resolves references in complex deployment hierarchies', () {
      // Test references in multi-level deployment hierarchies
      const source = '''
        workspace "Test Workspace" {
          model {
            system = softwareSystem "System" {
              webapp = container "Web Application"
              service = container "Service"
              database = container "Database"
            }

            deploymentEnvironment "Production" {
              region = deploymentNode "Cloud Region" {
                zone = deploymentNode "Availability Zone" {
                  webCluster = deploymentNode "Web Cluster" {
                    webNode = deploymentNode "Web Node" {
                      webappInstance = containerInstance webapp
                    }
                  }

                  serviceCluster = deploymentNode "Service Cluster" {
                    serviceNode = deploymentNode "Service Node" {
                      serviceInstance = containerInstance service
                    }
                  }

                  dbCluster = deploymentNode "DB Cluster" {
                    dbNode = deploymentNode "DB Node" {
                      dbInstance = containerInstance database
                    }
                  }
                }
              }

              webappInstance -> serviceInstance "Uses"
              serviceInstance -> dbInstance "Stores data in"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);

      // Check deployment environment
      expect(workspace!.model.deploymentEnvironments.length, equals(1));
      final env = workspace.model.deploymentEnvironments.first;
      expect(env.name, equals('Production'));

      // Find container instances
      final webInstance = env.findContainerInstanceForContainer('webapp');
      final serviceInstance = env.findContainerInstanceForContainer('service');
      final dbInstance = env.findContainerInstanceForContainer('database');

      expect(webInstance, isNotNull);
      expect(serviceInstance, isNotNull);
      expect(dbInstance, isNotNull);

      // Check relationships
      final webToService =
          env.findRelationshipBetween(webInstance!.id, serviceInstance!.id);
      final serviceToDb =
          env.findRelationshipBetween(serviceInstance.id, dbInstance!.id);

      expect(webToService, isNotNull);
      expect(serviceToDb, isNotNull);
      expect(webToService!.description, equals('Uses'));
      expect(serviceToDb!.description, equals('Stores data in'));
    });

    test('gracefully handles bidirectional relationships', () {
      // Test handling of bidirectional relationship notation
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User"
            system = softwareSystem "System"

            user <-> system "Interacts with"
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);

      // Find elements
      final user = workspace!.model.findPersonByName('User');
      final system = workspace.model.findSoftwareSystemByName('System');

      expect(user, isNotNull);
      expect(system, isNotNull);

      // Check bidirectional relationships
      final userToSystem =
          workspace.model.findRelationshipBetween(user!.id, system!.id);
      final systemToUser =
          workspace.model.findRelationshipBetween(system.id, user.id);

      expect(userToSystem, isNotNull);
      expect(systemToUser, isNotNull);
      expect(userToSystem!.description, equals('Interacts with'));
      expect(systemToUser!.description, equals('Interacts with'));
    });

    test('resolves case-insensitive element references', () {
      // Test resolving references when case doesn't match exactly
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User"
            system = softwareSystem "API System"

            relationship user SYSTEM "Uses"
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);

      // Find elements
      final user = workspace!.model.findPersonByName('User');
      final system = workspace.model.findSoftwareSystemByName('API System');

      expect(user, isNotNull);
      expect(system, isNotNull);

      // Check relationship despite case mismatch
      final relationship =
          workspace.model.findRelationshipBetween(user!.id, system!.id);

      expect(relationship, isNotNull);
      expect(relationship!.description, equals('Uses'));
    });

    test('resolves element references in view filters', () {
      // Test resolution of element references in view filters and configurations
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User"
            admin = person "Administrator"
            system = softwareSystem "System" {
              webapp = container "Web App"
              api = container "API"
              database = container "Database"
            }

            user -> webapp "Uses"
            admin -> api "Manages"
            webapp -> api "Calls"
            api -> database "Reads/writes"
          }

          views {
            systemContext system "SystemContext" {
              include user
              include admin
              exclude *
            }

            container system "ContainerView" {
              include *
              exclude database
            }

            styles {
              element "Person" {
                shape Person
                background #08427B
              }
              element user {
                background #4F9BDA
              }
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);

      // Check views are properly created with referenced elements
      expect(workspace!.views.systemContextViews, hasLength(1));
      expect(workspace.views.containerViews, hasLength(1));

      final systemContextView = workspace.views.systemContextViews.first;
      final containerView = workspace.views.containerViews.first;

      // Check system context view references
      expect(systemContextView.softwareSystemId, isNotNull);
      final system = workspace.model.findSoftwareSystemByName('System');
      expect(systemContextView.softwareSystemId, equals(system!.id));

      // Check include references
      expect(systemContextView.includeTags, hasLength(2));
      expect(systemContextView.includeTags.contains('user'), isTrue);
      expect(systemContextView.includeTags.contains('admin'), isTrue);

      // Check container view
      expect(containerView.softwareSystemId, equals(system.id));

      // Check styles
      expect(workspace.styles, isNotNull);
    });

    test('handles multiple deployments with same container reference', () {
      // Test referring to the same container in multiple deployment instances
      const source = '''
        workspace "Test Workspace" {
          model {
            system = softwareSystem "System" {
              webapp = container "Web Application"
            }

            deploymentEnvironment "Development" {
              devServer = deploymentNode "Dev Server" {
                webappDevInstance = containerInstance webapp
              }
            }

            deploymentEnvironment "Production" {
              prodServer1 = deploymentNode "Prod Server 1" {
                webappProd1 = containerInstance webapp
              }

              prodServer2 = deploymentNode "Prod Server 2" {
                webappProd2 = containerInstance webapp
              }

              loadBalancer = infrastructureNode "Load Balancer" {
                -> webappProd1 "Routes to"
                -> webappProd2 "Routes to"
              }
            }
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);

      // Check deployment environments
      expect(workspace!.model.deploymentEnvironments, hasLength(2));

      final devEnv = workspace.model.deploymentEnvironments
          .firstWhere((e) => e.name == 'Development');

      final prodEnv = workspace.model.deploymentEnvironments
          .firstWhere((e) => e.name == 'Production');

      expect(devEnv, isNotNull);
      expect(prodEnv, isNotNull);

      // Check container instances in dev
      expect(devEnv.deploymentNodes, isNotEmpty);
      final devServer = devEnv.deploymentNodes.first;
      expect(devServer.name, equals('Dev Server'));
      expect(devServer.containerInstances, hasLength(1));

      // Try to find load balancer in production environment
      InfrastructureNode? loadBalancer;
      for (final node in prodEnv.deploymentNodes) {
        for (final infraNode in node.infrastructureNodes) {
          if (infraNode.name == 'Load Balancer') {
            loadBalancer = infraNode;
            break;
          }
        }
        if (loadBalancer != null) break;
      }

      expect(loadBalancer, isNotNull);

      // Check relationships from load balancer
      if (loadBalancer != null) {
        expect(loadBalancer.relationships.length, equals(2));
      }
    });

    test('handles reference resolution errors gracefully', () {
      // Test how the mapper handles and reports invalid references
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User"
            system = softwareSystem "System"

            // Invalid references
            relationship user nonexistentSystem "Tries to use"
            system -> nonexistentUser "Sends notifications to"
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final errorReporter = ErrorReporter(source);
      final mapper = WorkspaceMapper(source, errorReporter);
      mapper.mapWorkspace(ast);

      // Check that errors are reported for unresolved references
      expect(errorReporter.hasErrors, isTrue);

      // Should have at least 2 errors for the two invalid references
      expect(errorReporter.errors.length, greaterThanOrEqualTo(2));

      // Check error messages contain the unresolved reference names
      expect(errorReporter.errors.any((e) => e.message.contains('nonexistent')),
          isTrue);
    });

    test(
        'creates ModeledRelationships with access to source and destination elements',
        () {
      // Test that ModeledRelationship provides direct access to source and destination elements
      const source = '''
        workspace "Test Workspace" {
          model {
            user = person "User" "A user of the system"
            system = softwareSystem "System" "A software system"
            
            user -> system "Uses"
          }
        }
      ''';

      final parser = Parser(source);
      final ast = parser.parse();
      final workspace =
          WorkspaceMapper(source, parser.errorReporter).mapWorkspace(ast);

      expect(workspace, isNotNull);
      expect(workspace!.model.relationships, hasLength(1));

      // Find the elements by name
      final user = workspace.model.findPersonByName('User');
      final system = workspace.model.findSoftwareSystemByName('System');

      expect(user, isNotNull);
      expect(system, isNotNull);

      // Test relationship resolution
      final relationship =
          workspace.model.findRelationshipBetween(user!.id, system!.id);
      expect(relationship, isNotNull);

      // Verify that relationship is a ModeledRelationship by accessing source/destination
      expect(relationship!, isNotNull);
      expect(relationship.source, equals(user));
      expect(relationship.destination, equals(system));
      expect(relationship.source.name, equals('User'));
      expect(relationship.destination.name, equals('System'));
      expect(relationship.description, equals('Uses'));
    });
  });
}
