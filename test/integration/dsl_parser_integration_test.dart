import 'package:flutter_structurizr/application/dsl/workspace_mapper.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DSL Parser Integration', () {
    test('parses a simple workspace with model elements', () {
      // Arrange
      const source = '''
        workspace "Banking System" "This is a model of my banking system." {
          model {
            customer = person "Customer" "A customer of the bank."
            internetBankingSystem = softwareSystem "Internet Banking System" "Allows customers to view information about their bank accounts and make payments."
            
            customer -> internetBankingSystem "Uses"
          }
        }
      ''';

      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);
      final parser = Parser(source);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      final workspace = mapper.mapWorkspace(ast);

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(workspace, isNotNull);
      final nonNullWorkspace = workspace!;
      expect(nonNullWorkspace.name, equals('Banking System'));
      expect(nonNullWorkspace.description,
          equals('This is a model of my banking system.'));

      // Check model elements
      expect(nonNullWorkspace.model.elements.length, equals(2));
      // Count by type instead of using whereType to avoid conflicts
      final personCount = nonNullWorkspace.model.people.length;
      final systemCount = nonNullWorkspace.model.softwareSystems.length;

      expect(personCount, equals(1));
      expect(systemCount, equals(1));

      final person = nonNullWorkspace.model.people.first;
      expect(person.name, equals('Customer'));
      expect(person.description, equals('A customer of the bank.'));

      final system = nonNullWorkspace.model.softwareSystems.first;
      expect(system.name, equals('Internet Banking System'));
      expect(
          system.description,
          equals(
              'Allows customers to view information about their bank accounts and make payments.'));

      // Check relationships
      expect(nonNullWorkspace.model.relationships.length, equals(1));
      final relationship = nonNullWorkspace.model.relationships.first;
      expect(relationship.sourceId, equals(person.id));
      expect(relationship.destinationId, equals(system.id));
      expect(relationship.description, equals('Uses'));
    });

    test('parses a workspace with container and component elements', () {
      // Arrange
      const source = '''
        workspace "Banking System" {
          model {
            customer = person "Customer"
            internetBankingSystem = softwareSystem "Internet Banking System" {
              webApplication = container "Web Application" "Provides internet banking functionality to customers via their web browser." "Java and Spring MVC" {
                signinController = component "Sign In Controller" "Allows users to sign in to the Internet Banking System." "Spring MVC Controller"
                accountsSummaryController = component "Accounts Summary Controller" "Provides customers with a summary of their bank accounts." "Spring MVC Controller"
              }
              database = container "Database" "Stores user registration information, hashed authentication credentials, access logs, etc." "Oracle Database Schema"
            }
            
            customer -> webApplication "Uses" "HTTPS"
            webApplication -> database "Reads from and writes to" "JDBC"
            signinController -> database "Reads from" "JDBC"
          }
        }
      ''';

      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);
      final parser = Parser(source);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      final workspace = mapper.mapWorkspace(ast);

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(workspace, isNotNull);
      final nonNullWorkspace = workspace!;
      expect(nonNullWorkspace.name, equals('Banking System'));

      // Check model elements
      // Count by type instead of using whereType to avoid conflicts
      final personCount = nonNullWorkspace.model.people.length;
      final systemCount = nonNullWorkspace.model.softwareSystems.length;

      expect(personCount, equals(1));
      expect(systemCount, equals(1));
      // Count containers and components by traversing the structure
      int containerCount = 0;
      int componentCount = 0;

      for (final system in nonNullWorkspace.model.softwareSystems) {
        containerCount += system.containers.length;

        for (final container in system.containers) {
          componentCount += container.components.length;
        }
      }

      expect(containerCount, equals(2));
      expect(componentCount, equals(2));

      // Check parent-child relationships
      final system = nonNullWorkspace.model.softwareSystems.first;

      // Get containers from the system
      expect(system.containers.length, equals(2));
      final webApp = system.containers[0];
      final database = system.containers[1];

      expect(webApp.parentId, equals(system.id));
      expect(database.parentId, equals(system.id));

      // Get components from the web app container
      expect(webApp.components.length, equals(2));
      final signinController = webApp.components[0];
      final accountsController = webApp.components[1];

      expect(signinController.parentId, equals(webApp.id));
      expect(accountsController.parentId, equals(webApp.id));

      // Check relationships
      expect(nonNullWorkspace.model.relationships.length, equals(3));
    });

    test('parses a workspace with views', () {
      // Arrange
      const source = '''
        workspace "Banking System" {
          model {
            customer = person "Customer"
            internetBankingSystem = softwareSystem "Internet Banking System"
            mainframeBankingSystem = softwareSystem "Mainframe Banking System"
            
            customer -> internetBankingSystem "Uses"
            internetBankingSystem -> mainframeBankingSystem "Gets account information from"
          }
          
          views {
            systemlandscape "SystemLandscape" {
              include *
              autoLayout
            }
            
            systemContext internetBankingSystem "SystemContext" {
              include *
              animation {
                customer
                internetBankingSystem
                mainframeBankingSystem
              }
            }
          }
        }
      ''';

      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);
      final parser = Parser(source);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      final workspace = mapper.mapWorkspace(ast);

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(workspace, isNotNull);
      final nonNullWorkspace = workspace!;
      expect(nonNullWorkspace.name, equals('Banking System'));

      // Check model elements
      expect(nonNullWorkspace.model.people.length, equals(1));
      expect(nonNullWorkspace.model.softwareSystems.length, equals(2));

      // Check views
      expect(nonNullWorkspace.views, isNotNull);
      expect(nonNullWorkspace.views.systemLandscapeViews.length, equals(1));
      expect(nonNullWorkspace.views.systemContextViews.length, equals(1));

      final landscapeView = nonNullWorkspace.views.systemLandscapeViews.first;
      expect(landscapeView.key, equals('SystemLandscape'));

      final contextView = nonNullWorkspace.views.systemContextViews.first;
      expect(contextView.key, equals('SystemContext'));
      expect(contextView.softwareSystemId, equals('internetBankingSystem'));

      // Check animations
      expect(contextView.animations.length, equals(1));
      expect(contextView.animations.first.elements.length, equals(3));
    });

    test('reports semantic errors', () {
      // Arrange
      const source = '''
        workspace "Banking System" {
          model {
            customer = person "Customer"
            
            // This relationship uses an undefined destination
            customer -> nonExistentSystem "Uses"
          }
        }
      ''';

      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);
      final parser = Parser(source);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      mapper.mapWorkspace(ast);

      // Assert
      expect(errorReporter.hasErrors, isTrue);
      expect(errorReporter.errors.first.message, contains('nonExistentSystem'));
    });

    test('handles syntax errors during parsing', () {
      // Arrange
      const source = '''
        workspace "Banking System" {
          model {
            customer = person "Customer" "A customer of the bank."
            
            // Missing closing brace
            internetBankingSystem = softwareSystem "Internet Banking System" {
              webApplication = container "Web Application"
            // Closing brace missing here
            
            customer -> internetBankingSystem "Uses"
          }
        }
      ''';

      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);
      final parser = Parser(source);

      // Act
      parser.parse();

      // Assert
      expect(errorReporter.hasErrors, isTrue);
      // Should report unclosed block
      expect(
          errorReporter.errors.any((e) =>
              e.message.contains('block') || e.message.contains('brace')),
          isTrue);
    });

    test('handles lexical errors during tokenization', () {
      // Arrange
      const source = '''
        workspace "Banking System" {
          model {
            // Invalid character sequence
            customer = person "Customer" "@#\$%"
          }
        }
      ''';

      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);

      // Act
      // Just get all tokens
      final tokens = lexer.scanTokens();

      // Assert
      expect(errorReporter.hasErrors, isTrue);
      // Should report unexpected character
      expect(
          errorReporter.errors
              .any((e) => e.message.contains('Unexpected character')),
          isTrue);
    });

    test('full C4 model with all element types', () {
      // Arrange
      const source = '''
        workspace "Big Bank plc" "This is an example workspace for Big Bank plc" {
          
          !identifiers hierarchical
          
          model {
              customer = person "Customer" "A customer of the bank."
              
              enterprise "Big Bank plc" {
                  supportStaff = person "Support Staff" "Customer service staff within the bank."
                  backoffice = person "Back Office Staff" "Administration and support staff within the bank."
                  
                  mainframe = softwareSystem "Mainframe Banking System" "Stores all of the core banking information about customers, accounts, transactions, etc."
                  
                  internetBankingSystem = softwareSystem "Internet Banking System" "Allows customers to view information about their bank accounts and make payments." {
                      webApplication = container "Web Application" "Provides all of the Internet banking functionality to customers via their web browser." "Java and Spring MVC" {
                          signinController = component "Sign In Controller" "Allows users to sign in to the Internet Banking System." "Spring MVC Controller"
                          accountsSummaryController = component "Accounts Summary Controller" "Provides customers with a summary of their bank accounts." "Spring MVC Controller"
                          resetPasswordController = component "Reset Password Controller" "Allows users to reset their passwords with a single use URL." "Spring MVC Controller"
                          securityComponent = component "Security Component" "Provides functionality related to signing in, changing passwords, etc." "Spring Bean"
                          mainframeFacade = component "Mainframe Facade" "A facade onto the mainframe banking system." "Spring Bean"
                          emailComponent = component "E-mail Component" "Sends e-mails to users." "Spring Bean"
                      }
                      
                      database = container "Database" "Stores user registration information, hashed authentication credentials, access logs, etc." "MySQL" {
                          databaseSchema = component "Database Schema" "Stores user registration information, hashed authentication credentials, access logs, etc." "MySQL Schema"
                      }
                      
                      mobileApp = container "Mobile App" "Provides a limited subset of the Internet banking functionality to customers via their mobile device." "Xamarin" {
                          signinScreen = component "Sign In Screen" "Allows users to sign in to the Internet Banking System." "Xamarin Screen"
                          accountsScreen = component "Accounts Screen" "Provides customers with a summary of their bank accounts." "Xamarin Screen"
                          resetPasswordScreen = component "Reset Password Screen" "Allows users to reset their passwords with a single use URL." "Xamarin Screen"
                      }
                  }
              }
              
              # relationships between people and software systems
              customer -> internetBankingSystem "Views account balances, and makes payments using"
              internetBankingSystem -> mainframe "Gets account information from, and makes payments using"
              supportStaff -> mainframe "Uses"
              backoffice -> mainframe "Uses"
                    
              # relationships to/from containers
              customer -> webApplication "Visits bigbank.com/ib using" "HTTPS"
              customer -> mobileApp "Downloads and installs"
              
              mobileApp -> webApplication "Makes API calls to" "JSON/HTTPS"
              webApplication -> database "Reads from and writes to" "JDBC"
              
              # relationships to/from components
              webApplication -> signinController "Delegates to"
              webApplication -> accountsSummaryController "Delegates to"
              webApplication -> resetPasswordController "Delegates to"
              
              signinController -> securityComponent "Uses"
              accountsSummaryController -> mainframeFacade "Uses"
              resetPasswordController -> securityComponent "Uses"
              resetPasswordController -> emailComponent "Uses"
              securityComponent -> database "Reads from and writes to"
              mainframeFacade -> mainframe "Makes API calls to" "XML/HTTPS"
              emailComponent -> customer "Sends e-mail to"
              
              mobileApp -> signinScreen "Shows"
              mobileApp -> accountsScreen "Shows"
              mobileApp -> resetPasswordScreen "Shows"
              
              signinScreen -> webApplication "Makes API calls to" "JSON/HTTPS"
              accountsScreen -> webApplication "Makes API calls to" "JSON/HTTPS"
              resetPasswordScreen -> webApplication "Makes API calls to" "JSON/HTTPS"
              
              database -> databaseSchema "Contains"
          }
          
          views {
              systemlandscape "SystemLandscape" {
                  include *
                  autoLayout
              }
              
              systemContext internetBankingSystem "SystemContext" {
                  include *
                  animation {
                      customer
                      internetBankingSystem
                      mainframe
                  }
                  autoLayout
                  description "The system context diagram for the Internet Banking System."
                  properties {
                      structurizr.groups false
                  }
              }
              
              container internetBankingSystem "Containers" {
                  include *
                  animation {
                      customer
                      webApplication
                      mobileApp
                      database
                      mainframe
                  }
                  autoLayout
                  description "The container diagram for the Internet Banking System."
              }
              
              component webApplication "Components" {
                  include *
                  animation {
                      webApplication
                      signinController
                      accountsSummaryController
                      resetPasswordController
                      securityComponent
                      mainframeFacade
                      emailComponent
                      database
                      mainframe
                      customer
                  }
                  autoLayout
                  description "The component diagram for the Web Application."
              }
              
              styles {
                  element "Person" {
                      color #ffffff
                      fontSize 22
                      shape Person
                  }
                  element "Customer" {
                      background #08427b
                  }
                  element "Bank Staff" {
                      background #999999
                  }
                  element "Software System" {
                      background #1168bd
                      color #ffffff
                  }
                  element "Existing System" {
                      background #999999
                      color #ffffff
                  }
                  element "Container" {
                      background #438dd5
                      color #ffffff
                  }
                  element "Web Browser" {
                      shape WebBrowser
                  }
                  element "Mobile App" {
                      shape MobileDeviceLandscape
                  }
                  element "Database" {
                      shape Cylinder
                  }
                  element "Component" {
                      background #85bbf0
                      color #000000
                  }
                  element "Failover" {
                      opacity 25
                  }
              }
          }
        }
      ''';

      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);
      final parser = Parser(source);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      final workspace = mapper.mapWorkspace(ast);

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(workspace, isNotNull);
      final nonNullWorkspace = workspace!;
      expect(nonNullWorkspace.name, equals('Big Bank plc'));

      // Check model elements
      final elements = nonNullWorkspace.model.elements;
      expect(elements.whereType<Person>().length, equals(3));
      expect(elements.whereType<SoftwareSystem>().length, equals(2));
      expect(elements.whereType<Container>().length, equals(3));
      expect(elements.whereType<Component>().length, equals(10));

      // Check relationships
      expect(nonNullWorkspace.model.relationships.length,
          greaterThanOrEqualTo(20));

      // Check views
      expect(nonNullWorkspace.views.systemLandscapeViews.length, equals(1));
      expect(nonNullWorkspace.views.systemContextViews.length, equals(1));
      expect(nonNullWorkspace.views.containerViews.length, equals(1));
      expect(nonNullWorkspace.views.componentViews.length, equals(1));

      // Check styles
      expect(nonNullWorkspace.views.styles?.elements.length,
          greaterThanOrEqualTo(10));
    });

    test('parses styles, themes, branding and terminology', () {
      // Arrange
      const source = '''
        workspace "Styled System" "A system with custom styles and branding" {
          model {
            user = person "User" "A user of the system"
            system = softwareSystem "System" "A software system"

            user -> system "Uses"
          }

          views {
            systemContext system "SystemContext" {
              include *
              autoLayout
            }
          }

          styles {
            element "Person" {
              shape Person
              background #1168bd
              color #ffffff
              fontSize 22
              border Dashed
              opacity 90
            }

            element "Software System" {
              shape RoundedBox
              background #438dd5
              icon "https://example.com/icons/system.png"
            }

            relationship "Relationship" {
              thickness 2
              color #ff0000
              style Dashed
              routing Orthogonal
              fontSize 14
              width 200
              position 70
              opacity 50
            }
          }

          themes https://structurizr.com/themes/default

          branding {
            logo "https://example.com/logo.png"
            font "Open Sans"
          }

          terminology {
            person "Actor"
            softwareSystem "Application"
            container "Service"
            component "Module"
            deploymentNode "Server"
            relationship "Connection"
            enterprise "Organization"
          }
        }
      ''';

      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source);
      final parser = Parser(source);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      final workspace = mapper.mapWorkspace(ast);

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(workspace, isNotNull);
      final nonNullWorkspace = workspace!;

      // Check styles
      expect(nonNullWorkspace.styles, isNotNull);
      final styles = nonNullWorkspace.styles;
      expect(styles.elements.length, equals(2));
      expect(styles.relationships.length, equals(1));
      expect(styles.themes.length, equals(1));

      final personStyle =
          nonNullWorkspace.styles.elements.firstWhere((e) => e.tag == 'Person');
      expect(personStyle.shape, equals(Shape.person));
      expect(personStyle.fontSize, equals(22));
      expect(personStyle.border, equals(Border.dashed));
      expect(personStyle.opacity, equals(90));

      final relationshipStyle = nonNullWorkspace.styles.relationships.first;
      expect(relationshipStyle.tag, equals('Relationship'));
      expect(relationshipStyle.thickness, equals(2));
      expect(relationshipStyle.style, equals(LineStyle.dashed));
      expect(relationshipStyle.routing, equals(StyleRouting.orthogonal));

      // Check themes
      expect(nonNullWorkspace.styles.themes.first,
          equals('https://structurizr.com/themes/default'));

      // Check branding
      expect(nonNullWorkspace.branding, isNotNull);
      final branding = nonNullWorkspace.branding!;
      expect(branding.logo, equals('https://example.com/logo.png'));
      expect(branding.fonts.length, equals(1));
      expect(branding.fonts.first.name, equals('Open Sans'));

      // Check terminology
      expect(nonNullWorkspace.views.configuration, isNotNull);
      expect(nonNullWorkspace.views.configuration?.terminology, isNotNull);

      final terminology = nonNullWorkspace.views.configuration!.terminology!;
      expect(terminology.person, equals('Actor'));
      expect(terminology.softwareSystem, equals('Application'));
      expect(terminology.container, equals('Service'));
      expect(terminology.component, equals('Module'));
      expect(terminology.deploymentNode, equals('Server'));
      expect(terminology.relationship, equals('Connection'));
      expect(terminology.enterprise, equals('Organization'));
    });
  });
}
