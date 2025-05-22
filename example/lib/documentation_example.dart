import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/documentation_navigator.dart';

/// An example application demonstrating the Documentation components of Flutter Structurizr.
void main() {
  runApp(const DocumentationExampleApp());
}

class DocumentationExampleApp extends StatelessWidget {
  const DocumentationExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structurizr Documentation Example',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const DocumentationExampleScreen(),
    );
  }
}

class DocumentationExampleScreen extends StatelessWidget {
  const DocumentationExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Create a sample workspace with documentation
    final workspace = _createSampleWorkspace();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Structurizr Documentation'),
      ),
      body: DocumentationNavigator(
        workspace: workspace,
        isDarkMode: isDarkMode,
        onDiagramSelected: (viewKey) {
          // In a real app, this would show the diagram
          _showDiagramDialog(context, viewKey);
        },
      ),
    );
  }

  /// Creates a sample workspace with documentation for demonstration.
  Workspace _createSampleWorkspace() {
    final model = Model(
      enterpriseName: 'Example Enterprise',
      softwareSystems: [
        SoftwareSystem.create(
          name: 'Banking System',
          description: 'Handles all banking operations',
        ),
      ],
    );

    final documentation = Documentation(
      sections: [
        const DocumentationSection(
          title: 'Introduction',
          content: '''
# Introduction

Welcome to the Banking System documentation. This documentation provides an overview of the system architecture and design decisions.

## Purpose

The Banking System handles all core banking operations, including:

- Account management
- Transactions
- Customer information
- Reporting

## Technology Stack

The system is built using the following technologies:

```dart
// Example code snippet
class BankingSystem {
  final Database database;
  final AuthService auth;
  
  Future<Account> getAccount(String accountId) async {
    // Implementation
  }
}
```

## System Context

The following diagram shows the system context:

![System Context](embed:SystemContext)
''',
          order: 1,
        ),
        const DocumentationSection(
          title: 'Architecture',
          content: '''
# Architecture

## Overview

The Banking System uses a microservices architecture with the following components:

1. Account Service
2. Transaction Service
3. Customer Service
4. Reporting Service

## Deployment

The system is deployed in a cloud environment using Kubernetes.

![Deployment](embed:Deployment)

## Security

The system implements multiple security layers:

- OAuth 2.0 authentication
- HTTPS encryption
- Data encryption at rest
- Role-based access control
''',
          order: 2,
        ),
        const DocumentationSection(
          title: 'API Documentation',
          content: '''
# API Documentation

## REST API

The system exposes a REST API for integration with other systems.

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| /accounts | GET | List all accounts |
| /accounts/{id} | GET | Get account details |
| /transactions | POST | Create a new transaction |
| /customers | GET | List all customers |

## Example Request

```json
{
  "accountId": "1234567890",
  "amount": 500.00,
  "currency": "USD",
  "description": "Deposit"
}
```
''',
          order: 3,
          elementId: 'api-gateway',
        ),
      ],
      decisions: [
        Decision(
          id: 'ADR-001',
          date: DateTime(2023, 1, 15),
          status: 'Accepted',
          title: 'Use Microservices Architecture',
          content: '''
# Use Microservices Architecture

## Context

We need to decide on the architectural approach for the Banking System.

## Decision

We will use a microservices architecture for the Banking System.

## Consequences

* Improved scalability
* Better fault isolation
* Independent deployment of services
* Increased operational complexity
* Need for service discovery and orchestration
''',
        ),
        Decision(
          id: 'ADR-002',
          date: DateTime(2023, 2, 20),
          status: 'Proposed',
          title: 'Database per Service',
          content: '''
# Database per Service

## Context

We need to decide on the database strategy for our microservices.

## Decision

Each microservice will have its own dedicated database.

## Consequences

* Data independence
* Freedom to choose appropriate database technology per service
* Need for eventual consistency patterns
* Complexity in reporting and data aggregation
''',
          links: ['ADR-001'],
        ),
        Decision(
          id: 'ADR-003',
          date: DateTime(2023, 3, 10),
          status: 'Rejected',
          title: 'Use GraphQL for API',
          content: '''
# Use GraphQL for API

## Context

We need to decide on the API technology for the Banking System.

## Decision

We considered using GraphQL for the API layer but decided against it.

## Consequences

* REST API is more familiar to the team
* Better tooling support for REST in our environment
* Simpler security model with REST
* We miss out on some GraphQL benefits like reduced over-fetching
''',
          links: ['ADR-001'],
        ),
      ],
    );

    return Workspace(
      id: 1,
      name: 'Banking System',
      description: 'Core banking system architecture',
      model: model,
      documentation: documentation,
    );
  }

  /// Shows a dialog when a diagram is selected.
  void _showDiagramDialog(BuildContext context, String viewKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagram Selected'),
        content: Text('You selected the diagram with key: $viewKey'),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
