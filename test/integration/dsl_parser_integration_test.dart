import 'package:flutter_structurizr/application/dsl/workspace_mapper.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/parser/error_reporter.dart';
import 'package:flutter_structurizr/domain/parser/lexer/lexer.dart';
import 'package:flutter_structurizr/domain/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DSL Parser Integration', () {
    test('parses a simple workspace with model elements', () {
      // Arrange
      final source = '''
        workspace "Banking System" "This is a model of my banking system." {
          model {
            customer = person "Customer" "A customer of the bank."
            internetBankingSystem = softwareSystem "Internet Banking System" "Allows customers to view information about their bank accounts and make payments."
            
            customer -> internetBankingSystem "Uses"
          }
        }
      ''';
      
      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source, errorReporter);
      final parser = Parser(lexer, errorReporter);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      final workspace = mapper.mapWorkspace(ast);

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(workspace, isNotNull);
      expect(workspace.name, equals('Banking System'));
      expect(workspace.description, equals('This is a model of my banking system.'));
      
      // Check model elements
      expect(workspace.model.elements.length, equals(2));
      expect(workspace.model.elements.whereType<Person>().length, equals(1));
      expect(workspace.model.elements.whereType<SoftwareSystem>().length, equals(1));
      
      final person = workspace.model.elements.whereType<Person>().first;
      expect(person.name, equals('Customer'));
      expect(person.description, equals('A customer of the bank.'));
      expect(person.identifier, equals('customer'));
      
      final system = workspace.model.elements.whereType<SoftwareSystem>().first;
      expect(system.name, equals('Internet Banking System'));
      expect(system.description, equals('Allows customers to view information about their bank accounts and make payments.'));
      expect(system.identifier, equals('internetBankingSystem'));
      
      // Check relationships
      expect(workspace.model.relationships.length, equals(1));
      final relationship = workspace.model.relationships.first;
      expect(relationship.source, equals(person));
      expect(relationship.destination, equals(system));
      expect(relationship.description, equals('Uses'));
    });

    test('parses a workspace with container and component elements', () {
      // Arrange
      final source = '''
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
      final lexer = Lexer(source, errorReporter);
      final parser = Parser(lexer, errorReporter);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      final workspace = mapper.mapWorkspace(ast);

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(workspace, isNotNull);
      expect(workspace.name, equals('Banking System'));
      
      // Check model elements
      expect(workspace.model.elements.whereType<Person>().length, equals(1));
      expect(workspace.model.elements.whereType<SoftwareSystem>().length, equals(1));
      expect(workspace.model.elements.whereType<Container>().length, equals(2));
      expect(workspace.model.elements.whereType<Component>().length, equals(2));
      
      // Check parent-child relationships
      final system = workspace.model.elements
          .whereType<SoftwareSystem>()
          .firstWhere((e) => e.identifier == 'internetBankingSystem');
          
      final webApp = workspace.model.elements
          .whereType<Container>()
          .firstWhere((e) => e.identifier == 'webApplication');
      expect(webApp.parent, equals(system));
      
      final database = workspace.model.elements
          .whereType<Container>()
          .firstWhere((e) => e.identifier == 'database');
      expect(database.parent, equals(system));
      
      final signinController = workspace.model.elements
          .whereType<Component>()
          .firstWhere((e) => e.identifier == 'signinController');
      expect(signinController.parent, equals(webApp));
      
      final accountsController = workspace.model.elements
          .whereType<Component>()
          .firstWhere((e) => e.identifier == 'accountsSummaryController');
      expect(accountsController.parent, equals(webApp));
      
      // Check relationships
      expect(workspace.model.relationships.length, equals(3));
    });

    test('parses a workspace with views', () {
      // Arrange
      final source = '''
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
      final lexer = Lexer(source, errorReporter);
      final parser = Parser(lexer, errorReporter);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      final workspace = mapper.mapWorkspace(ast);

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(workspace, isNotNull);
      expect(workspace.name, equals('Banking System'));
      
      // Check model elements
      expect(workspace.model.elements.whereType<Person>().length, equals(1));
      expect(workspace.model.elements.whereType<SoftwareSystem>().length, equals(2));
      
      // Check views
      expect(workspace.views, isNotNull);
      expect(workspace.views.systemLandscapeViews.length, equals(1));
      expect(workspace.views.systemContextViews.length, equals(1));
      
      final landscapeView = workspace.views.systemLandscapeViews.first;
      expect(landscapeView.key, equals('SystemLandscape'));
      
      final contextView = workspace.views.systemContextViews.first;
      expect(contextView.key, equals('SystemContext'));
      expect(contextView.softwareSystemId, equals('internetBankingSystem'));
      
      // Check animations
      expect(contextView.animations.length, equals(1));
      expect(contextView.animations.first.elements.length, equals(3));
    });

    test('reports semantic errors', () {
      // Arrange
      final source = '''
        workspace "Banking System" {
          model {
            customer = person "Customer"
            
            // This relationship uses an undefined destination
            customer -> nonExistentSystem "Uses"
          }
        }
      ''';
      
      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source, errorReporter);
      final parser = Parser(lexer, errorReporter);
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
      final source = '''
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
      final lexer = Lexer(source, errorReporter);
      final parser = Parser(lexer, errorReporter);

      // Act
      parser.parse();

      // Assert
      expect(errorReporter.hasErrors, isTrue);
      // Should report unclosed block
      expect(errorReporter.errors.any((e) => 
        e.message.contains('block') || e.message.contains('brace')), isTrue);
    });

    test('handles lexical errors during tokenization', () {
      // Arrange
      final source = '''
        workspace "Banking System" {
          model {
            // Invalid character sequence
            customer = person "Customer" @#$%
          }
        }
      ''';
      
      final errorReporter = ErrorReporter(source);
      final lexer = Lexer(source, errorReporter);

      // Act
      while (lexer.nextToken().type != TokenType.EOF) {
        // Just consume all tokens
      }

      // Assert
      expect(errorReporter.hasErrors, isTrue);
      // Should report unexpected character
      expect(errorReporter.errors.any((e) => 
        e.message.contains('Unexpected character')), isTrue);
    });

    test('full C4 model with all element types', () {
      // Arrange
      final source = '''
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
      final lexer = Lexer(source, errorReporter);
      final parser = Parser(lexer, errorReporter);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      final workspace = mapper.mapWorkspace(ast);

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(workspace, isNotNull);
      expect(workspace.name, equals('Big Bank plc'));
      
      // Check model elements
      final elements = workspace.model.elements;
      expect(elements.whereType<Person>().length, equals(3));
      expect(elements.whereType<SoftwareSystem>().length, equals(2));
      expect(elements.whereType<Container>().length, equals(3));
      expect(elements.whereType<Component>().length, equals(10));
      
      // Check relationships
      expect(workspace.model.relationships.length, greaterThanOrEqualTo(20));
      
      // Check views
      expect(workspace.views.systemLandscapeViews.length, equals(1));
      expect(workspace.views.systemContextViews.length, equals(1));
      expect(workspace.views.containerViews.length, equals(1));
      expect(workspace.views.componentViews.length, equals(1));
      
      // Check styles
      expect(workspace.views.styles.elements.length, greaterThanOrEqualTo(10));
    });

    test('parses styles, themes, branding and terminology', () {
      // Arrange
      final source = '''
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
      final lexer = Lexer(source, errorReporter);
      final parser = Parser(lexer, errorReporter);
      final mapper = WorkspaceMapper(source, errorReporter);

      // Act
      final ast = parser.parse();
      final workspace = mapper.mapWorkspace(ast);

      // Assert
      expect(errorReporter.hasErrors, isFalse);
      expect(workspace, isNotNull);

      // Check styles
      expect(workspace.styles, isNotNull);
      expect(workspace.styles.elements.length, equals(2));
      expect(workspace.styles.relationships.length, equals(1));
      expect(workspace.styles.themes.length, equals(1));

      final personStyle = workspace.styles.elements.firstWhere((e) => e.tag == 'Person');
      expect(personStyle.shape, equals(Shape.person));
      expect(personStyle.fontSize, equals(22));
      expect(personStyle.border, equals(Border.dashed));
      expect(personStyle.opacity, equals(90));

      final relationshipStyle = workspace.styles.relationships.first;
      expect(relationshipStyle.tag, equals('Relationship'));
      expect(relationshipStyle.thickness, equals(2));
      expect(relationshipStyle.style, equals(LineStyle.dashed));
      expect(relationshipStyle.routing, equals(Routing.orthogonal));

      // Check themes
      expect(workspace.styles.themes.first, equals('https://structurizr.com/themes/default'));

      // Check branding
      expect(workspace.branding, isNotNull);
      expect(workspace.branding.logo, equals('https://example.com/logo.png'));
      expect(workspace.branding.fonts.length, equals(1));
      expect(workspace.branding.fonts.first.name, equals('Open Sans'));

      // Check terminology
      expect(workspace.views.configuration, isNotNull);
      expect(workspace.views.configuration?.terminology, isNotNull);

      final terminology = workspace.views.configuration!.terminology!;
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