import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';

void main() {
  group('Parser', () {
    test('should parse empty workspace', () {
      const source = '''
        workspace "Empty Workspace" {
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.name, equals('Empty Workspace'));
      expect(workspace.model, isNull);
      expect(workspace.views, isNull);
      expect(workspace.styles, isNull);
      expect(workspace.themes, isEmpty);
      expect(workspace.branding, isNull);
      expect(workspace.terminology, isNull);
      expect(workspace.properties, isNull);
      expect(workspace.configuration, isEmpty);
    });

    test('should parse workspace with description', () {
      const source = '''
        workspace "Test Workspace" "This is a test workspace" {
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace, isA<WorkspaceNode>());
      expect(workspace.name, equals('Test Workspace'));
      expect(workspace.description, equals('This is a test workspace'));
    });

    test('should parse workspace with model section', () {
      const source = '''
        workspace "Model Test" {
          model {
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.model, isA<ModelNode>());
      expect(workspace.model!.people, isEmpty);
      expect(workspace.model!.softwareSystems, isEmpty);
      expect(workspace.model!.relationships, isEmpty);
    });

    test('should parse person declarations', () {
      const source = '''
        workspace "Person Test" {
          model {
            person "User" "A user of the system"
            person "Admin" "A system administrator" {
              tags "admin" 
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.model!.people.length, equals(2));

      final user = workspace.model!.people[0];
      expect(user.id, equals('User'));
      expect(user.name, equals('User'));
      expect(user.description, equals('A user of the system'));
      expect(user.tags, isNull);

      final admin = workspace.model!.people[1];
      expect(admin.id, equals('Admin'));
      expect(admin.name, equals('Admin'));
      expect(admin.description, equals('A system administrator'));
      expect(admin.tags, isA<TagsNode>());
      expect(admin.tags.tags, contains('admin'));
    });

    test('should parse person with variable assignment', () {
      const source = '''
        workspace "Variable Test" {
          model {
            user = person "End User" "A regular user of the system"
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.model!.people.length, equals(1));

      final user = workspace.model!.people[0];
      expect(user.id, equals('user'));
      expect(user.name, equals('End User'));
    });

    test('should parse software system declarations', () {
      const source = '''
        workspace "System Test" {
          model {
            softwareSystem "System A" "Description of System A"
            sys = softwareSystem "System B" "Description of System B" {
              tags "web"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.model!.softwareSystems.length, equals(2));

      final systemA = workspace.model!.softwareSystems[0];
      expect(systemA.id, equals('SystemA'));
      expect(systemA.name, equals('System A'));
      expect(systemA.description, equals('Description of System A'));

      final systemB = workspace.model!.softwareSystems[1];
      expect(systemB.id, equals('sys'));
      expect(systemB.name, equals('System B'));
      expect(systemB.tags, isA<TagsNode>());
      expect(systemB.tags.tags, contains('web'));
    });

    test('should parse container declarations', () {
      const source = '''
        workspace "Container Test" {
          model {
            system = softwareSystem "System" {
              webApp = container "Web Application" "Delivers the web UI" "React"
              api = container "API" "Provides data access" "Spring Boot" {
                tags "api"
              }
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      final system = workspace.model!.softwareSystems[0];
      expect(system.containers.length, equals(2));

      final webApp = system.containers[0];
      expect(webApp.id, equals('webApp'));
      expect(webApp.name, equals('Web Application'));
      expect(webApp.description, equals('Delivers the web UI'));
      expect(webApp.technology, equals('React'));

      final api = system.containers[1];
      expect(api.id, equals('api'));
      expect(api.technology, equals('Spring Boot'));
      expect(api.tags, isA<TagsNode>());
      expect(api.tags.tags, contains('api'));
    });

    test('should parse component declarations', () {
      const source = '''
        workspace "Component Test" {
          model {
            system = softwareSystem "System" {
              api = container "API" {
                controller = component "Controller" "Handles HTTP requests" "Spring MVC"
                service = component "Service" "Business logic" "Spring Service" {
                  tags "service"
                }
              }
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      final system = workspace.model!.softwareSystems[0];
      final api = system.containers[0];
      expect(api.components.length, equals(2));

      final controller = api.components[0];
      expect(controller.id, equals('controller'));
      expect(controller.name, equals('Controller'));
      expect(controller.technology, equals('Spring MVC'));

      final service = api.components[1];
      expect(service.id, equals('service'));
      expect(service.tags, isA<TagsNode>());
      expect(service.tags.tags, contains('service'));
    });

    test('should parse deployment environment and nodes', () {
      const source = '''
        workspace "Deployment Test" {
          model {
            system = softwareSystem "System" {
              webapp = container "Web App"
              
              deploymentEnvironment "Production" {
                aws = deploymentNode "AWS" "Amazon Web Services" {
                  ec2 = deploymentNode "EC2" "Virtual machine" "Amazon EC2" {
                    containerInstance webapp
                  }
                }
              }
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      final system = workspace.model!.softwareSystems[0];
      expect(system.deploymentEnvironments.length, equals(1));

      final prod = system.deploymentEnvironments[0];
      expect(prod.name, equals('Production'));

      final aws = prod.deploymentNodes[0];
      expect(aws.id, equals('aws'));
      expect(aws.name, equals('AWS'));

      final ec2 = aws.children[0];
      expect(ec2.id, equals('ec2'));
      expect(ec2.technology, equals('Amazon EC2'));

      final containerInstance = ec2.containerInstances[0];
      expect(containerInstance.containerId, equals('webapp'));
    });

    test('should parse infrastructure nodes', () {
      const source = '''
        workspace "Infrastructure Test" {
          model {
            system = softwareSystem "System" {
              deploymentEnvironment "Production" {
                aws = deploymentNode "AWS" {
                  rds = infrastructureNode "RDS" "Database" "Amazon RDS" {
                    tags "database"
                  }
                }
              }
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      final system = workspace.model!.softwareSystems[0];
      final prod = system.deploymentEnvironments[0];
      final aws = prod.deploymentNodes[0];

      expect(aws.infrastructureNodes.length, equals(1));
      final rds = aws.infrastructureNodes[0];
      expect(rds.id, equals('rds'));
      expect(rds.name, equals('RDS'));
      expect(rds.technology, equals('Amazon RDS'));
      expect(rds.tags, isA<TagsNode>());
      expect(rds.tags.tags, contains('database'));
    });

    test('should parse explicitly defined relationships', () {
      const source = '''
        workspace "Relationship Test" {
          model {
            user = person "User"
            system = softwareSystem "System"
            
            relationship user system "Uses" "HTTP/JSON" {
              tags "important"
              properties {
                "weight" = "5"
              }
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.model!.relationships.length, equals(1));

      final rel = workspace.model!.relationships[0];
      expect(rel.sourceId, equals('user'));
      expect(rel.destinationId, equals('system'));
      expect(rel.description, equals('Uses'));
      expect(rel.technology, equals('HTTP/JSON'));
      expect(rel.tags, isA<TagsNode>());
      expect(rel.tags.tags, contains('important'));
      expect(rel.properties, isA<PropertiesNode>());
      expect(rel.properties.properties.length, equals(1));
      expect(rel.properties.properties[0].name, equals('weight'));
      expect(rel.properties.properties[0].value, equals('5'));
    });

    test('should parse implicit relationships within elements', () {
      const source = '''
        workspace "Implicit Relationship Test" {
          model {
            user = person "User"
            system = softwareSystem "System" {
              user -> this "Uses"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      final system = workspace.model!.softwareSystems[0];
      expect(system.relationships.length, equals(1));

      final rel = system.relationships[0];
      expect(rel.sourceId, equals('user'));
      expect(rel.destinationId, equals('this'));
      expect(rel.description, equals('Uses'));
    });

    test('should parse views section', () {
      const source = '''
        workspace "Views Test" {
          model {
            user = person "User"
            system = softwareSystem "System"
          }
          
          views {
            systemLandscape "landscape" "Enterprise Landscape" {
              include *
              autoLayout
            }
            
            systemContext system "context" "System Context" {
              include *
              autoLayout "tb" 300 100
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.views, isA<ViewsNode>());
      expect(workspace.views!.systemLandscapeViews.length, equals(1));
      expect(workspace.views!.systemContextViews.length, equals(1));

      final landscape = workspace.views!.systemLandscapeViews[0];
      expect(landscape.key, equals('landscape'));
      expect(landscape.title, equals('Enterprise Landscape'));
      expect(landscape.includes.length, equals(1));
      expect(landscape.includes[0].expression, equals('*'));
      expect(landscape.autoLayout, isA<AutoLayoutNode>());

      final context = workspace.views!.systemContextViews[0];
      expect(context.key, equals('context'));
      expect(context.systemId, equals('system'));
      expect(context.autoLayout!.rankDirection, equals('tb'));
      expect(context.autoLayout!.rankSeparation, equals(300));
      expect(context.autoLayout!.nodeSeparation, equals(100));
    });

    test('should parse container and component views', () {
      const source = '''
        workspace "Container Views Test" {
          model {
            system = softwareSystem "System"
            container = container "Container" "Container description"
          }
          
          views {
            containerView system "containers" "Containers" {
              include *
              autoLayout
            }
            
            componentView container "components" "Components" {
              include *
              autoLayout
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.views!.containerViews.length, equals(1));
      expect(workspace.views!.componentViews.length, equals(1));

      final containerView = workspace.views!.containerViews[0];
      expect(containerView.key, equals('containers'));
      expect(containerView.systemId, equals('system'));

      final componentView = workspace.views!.componentViews[0];
      expect(componentView.key, equals('components'));
      expect(componentView.containerId, equals('container'));
    });

    test('should parse dynamic views', () {
      const source = '''
        workspace "Dynamic View Test" {
          model {
            user = person "User"
            system = softwareSystem "System"
          }
          
          views {
            dynamic system "dynamic" "Authentication Flow" {
              include *
              autoLayout
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.views!.dynamicViews.length, equals(1));

      final dynamicView = workspace.views!.dynamicViews[0];
      expect(dynamicView.key, equals('dynamic'));
      expect(dynamicView.scope, equals('system'));
      expect(dynamicView.title, equals('Authentication Flow'));
    });

    test('should parse deployment views', () {
      const source = '''
        workspace "Deployment View Test" {
          model {
            system = softwareSystem "System"
          }
          
          views {
            deployment system "Production" "deployment" "Production Deployment" {
              include *
              autoLayout
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.views!.deploymentViews.length, equals(1));

      final deploymentView = workspace.views!.deploymentViews[0];
      expect(deploymentView.key, equals('deployment'));
      expect(deploymentView.systemId, equals('system'));
      expect(deploymentView.environment, equals('Production'));
      expect(deploymentView.title, equals('Production Deployment'));
    });

    test('should parse filtered views', () {
      const source = '''
        workspace "Filtered View Test" {
          views {
            systemLandscape "landscape" {
              include *
            }
            
            filtered "landscape" "filtered" "Filtered View" {
              include "tag1"
              exclude "tag2"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.views!.filteredViews.length, equals(1));

      final filteredView = workspace.views!.filteredViews[0];
      expect(filteredView.key, equals('filtered'));
      expect(filteredView.baseViewKey, equals('landscape'));
      expect(filteredView.title, equals('Filtered View'));
      expect(filteredView.includes.length, equals(1));
      expect(filteredView.includes[0].expression, equals('tag1'));
      expect(filteredView.excludes.length, equals(1));
      expect(filteredView.excludes[0].expression, equals('tag2'));
    });

    test('should parse styles section', () {
      const source = '''
        workspace "Styles Test" {
          styles {
            element "person" {
              shape "Person"
              background "#08427B"
              color "#FFFFFF"
              fontSize 22
              border "Dashed"
            }
            
            relationship "Relationship" {
              thickness 4
              color "#707070"
              style "Dashed"
              routing "Orthogonal"
              fontSize 20
              width 400
              position 50
              opacity 0.9
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.styles, isA<StylesNode>());
      expect(workspace.styles!.elementStyles.length, equals(1));
      expect(workspace.styles!.relationshipStyles.length, equals(1));

      final elementStyle = workspace.styles!.elementStyles[0];
      expect(elementStyle.tag, equals('person'));
      expect(elementStyle.shape, equals('Person'));
      expect(elementStyle.background, equals('#08427B'));
      expect(elementStyle.color, equals('#FFFFFF'));
      expect(elementStyle.fontSize, equals(22));
      expect(elementStyle.border, equals('Dashed'));

      final relationshipStyle = workspace.styles!.relationshipStyles[0];
      expect(relationshipStyle.tag, equals('Relationship'));
      expect(relationshipStyle.thickness, equals(4));
      expect(relationshipStyle.color, equals('#707070'));
      expect(relationshipStyle.style, equals('Dashed'));
      expect(relationshipStyle.routing, equals('Orthogonal'));
      expect(relationshipStyle.fontSize, equals(20));
      expect(relationshipStyle.width, equals(400));
      expect(relationshipStyle.position, equals('50'));
      expect(relationshipStyle.opacity, equals(0.9));
    });

    test('should parse themes', () {
      const source = '''
        workspace "Themes Test" {
          themes "https://static.structurizr.com/themes/default.json"
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.themes.length, equals(1));
      expect(workspace.themes[0].url,
          equals('https://static.structurizr.com/themes/default.json'));
    });

    test('should parse branding', () {
      const source = '''
        workspace "Branding Test" {
          branding {
            logo "https://example.com/logo.png"
            width 400
            height 100
            font "Open Sans"
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.branding, isA<BrandingNode>());
      expect(workspace.branding!.logo, equals('https://example.com/logo.png'));
      expect(workspace.branding!.width, equals(400));
      expect(workspace.branding!.height, equals(100));
      expect(workspace.branding!.font, equals('Open Sans'));
    });

    test('should parse terminology', () {
      const source = '''
        workspace "Terminology Test" {
          terminology {
            person "Individual"
            softwareSystem "Application"
            container "Service"
            component "Module"
            deploymentNode "Server"
            relationship "Connection"
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.terminology, isA<TerminologyNode>());
      expect(workspace.terminology!.person, equals('Individual'));
      expect(workspace.terminology!.softwareSystem, equals('Application'));
      expect(workspace.terminology!.container, equals('Service'));
      expect(workspace.terminology!.component, equals('Module'));
      expect(workspace.terminology!.deploymentNode, equals('Server'));
      expect(workspace.terminology!.relationship, equals('Connection'));
    });

    test('should parse configuration', () {
      const source = '''
        workspace "Configuration Test" {
          model {
            !identifiers hierarchical
          }
          
          views {
            configuration {
              "branding.logo" "https://example.com/logo.png"
              "styles.opacity" "80"
            }
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      expect(workspace.views!.configuration.length, equals(2));
      expect(workspace.views!.configuration['branding.logo'],
          equals('https://example.com/logo.png'));
      expect(workspace.views!.configuration['styles.opacity'], equals('80'));
    });

    group('Error Handling', () {
      test('should report error for missing workspace braces', () {
        const source = '''
          workspace "Error Test"
        ''';

        final parser = Parser(source);
        final workspace = parser.parse();

        expect(parser.errorReporter.hasErrors, isTrue);
        expect(parser.errorReporter.errors.length, greaterThan(0));
      });

      test('should report error for invalid element type', () {
        const source = '''
          workspace "Error Test" {
            model {
              unknownElement "Test"
            }
          }
        ''';

        final parser = Parser(source);
        final workspace = parser.parse();

        expect(parser.errorReporter.hasErrors, isTrue);
      });

      test('should report error for missing required elements', () {
        const source = '''
          workspace {
          }
        ''';

        final parser = Parser(source);
        final workspace = parser.parse();

        expect(parser.errorReporter.hasErrors, isTrue);
      });

      test('should recover from syntax errors', () {
        const source = '''
          workspace "Recovery Test" {
            model {
              // This is an error, but parsing should continue
              person
              
              // This should still be parsed
              user = person "User"
            }
          }
        ''';

        final parser = Parser(source);
        final workspace = parser.parse();

        expect(parser.errorReporter.hasErrors, isTrue);
        expect(workspace.model!.people.length, equals(1));
        expect(workspace.model!.people[0].id, equals('user'));
      });
    });

    test('should parse complex model with all elements', () {
      const source = '''
        workspace "Complete Example" "Comprehensive example with all elements" {
          model {
            user = person "User" "A user of the system" {
              tags "user"
              properties {
                "userType" = "external"
              }
            }
            
            admin = person "Admin" "System administrator"
            
            system = softwareSystem "System" "Main system" {
              tags "system"
              
              webapp = container "Web Application" "Frontend" "React" {
                ui = component "UI" "User interface" "React Components"
                api = component "API Client" "API access" "Axios"
              }
              
              api = container "API" "Backend API" "Spring Boot" {
                controllers = component "Controllers" "REST endpoints" "Spring MVC"
                services = component "Services" "Business logic" "Spring Services"
                repos = component "Repositories" "Data access" "Spring Data"
              }
              
              db = container "Database" "Stores data" "PostgreSQL"
              
              # Relationships between containers
              webapp -> api "Makes API calls to" "JSON/HTTPS"
              api -> db "Reads from and writes to" "JDBC"
              
              deploymentEnvironment "Production" {
                aws = deploymentNode "AWS" "Amazon Web Services" {
                  webapp_ec2 = deploymentNode "Web EC2" "Web Server" "Amazon EC2" {
                    containerInstance webapp
                  }
                  
                  api_ec2 = deploymentNode "API EC2" "API Server" "Amazon EC2" {
                    containerInstance api
                  }
                  
                  rds = infrastructureNode "RDS" "Database" "Amazon RDS PostgreSQL" {
                    tags "database"
                  }
                }
              }
            }
            
            # External system
            payment = softwareSystem "Payment System" "External payment processor" {
              tags "external"
            }
            
            # Define relationships
            user -> system "Uses"
            admin -> system "Administers"
            system -> payment "Sends payment requests to" "HTTPS"
          }
          
          views {
            systemLandscape "landscape" "Enterprise Landscape" {
              include *
              autoLayout
            }
            
            systemContext system "context" "System Context" {
              include *
              autoLayout
            }
            
            containerView system "containers" "Container View" {
              include *
              autoLayout
            }
            
            componentView api "api_components" "API Components" {
              include *
              autoLayout
            }
            
            dynamicView system "auth" "Authentication Flow" {
              user -> webapp "Logs in"
              webapp -> api "Validates credentials"
              api -> db "Queries user"
              autoLayout
            }
            
            deploymentView system "Production" "deployment" "Production Deployment" {
              include *
              autoLayout
            }
            
            # Define a filtered view
            filtered "context" "external_systems" "External Systems" {
              include "external"
            }
            
            styles {
              element "person" {
                shape "Person"
                background "#08427B"
                color "#FFFFFF"
              }
              
              element "external" {
                background "#999999"
              }
              
              element "database" {
                shape "Cylinder"
              }
              
              relationship "Relationship" {
                thickness 2
                color "#000000"
              }
            }
            
            themes "https://static.structurizr.com/themes/default.json"
          }
          
          branding {
            logo "https://example.com/logo.png"
          }
          
          terminology {
            person "User"
            softwareSystem "System"
            container "Service"
            component "Module"
          }
        }
      ''';

      final parser = Parser(source);
      final workspace = parser.parse();

      // Basic validations for complex model
      expect(workspace.name, equals('Complete Example'));
      expect(workspace.model!.people.length, equals(2));
      expect(workspace.model!.softwareSystems.length, equals(2));
      expect(workspace.model!.relationships.length, equals(3));

      final system =
          workspace.model!.softwareSystems.firstWhere((s) => s.id == 'system');
      expect(system.containers.length, equals(3));
      expect(system.deploymentEnvironments.length, equals(1));

      expect(workspace.views!.systemLandscapeViews.length, equals(1));
      expect(workspace.views!.systemContextViews.length, equals(1));
      expect(workspace.views!.containerViews.length, equals(1));
      expect(workspace.views!.componentViews.length, equals(1));
      expect(workspace.views!.dynamicViews.length, equals(1));
      expect(workspace.views!.deploymentViews.length, equals(1));
      expect(workspace.views!.filteredViews.length, equals(1));

      expect(workspace.styles!.elementStyles.length, equals(3));
      expect(workspace.styles!.relationshipStyles.length, equals(1));

      expect(workspace.themes.length, equals(1));
      expect(workspace.branding!.logo, equals('https://example.com/logo.png'));
      expect(workspace.terminology!.person, equals('User'));
    });
  });
}
