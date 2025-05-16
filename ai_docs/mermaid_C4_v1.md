# Mermaid C4 Diagram Implementation

## Overview
Mermaid's C4 diagram implementation is an experimental feature that provides a simplified approach for creating C4 architecture diagrams. It follows a syntax compatible with PlantUML while using Mermaid's rendering engine.

## Status
- Currently marked as **experimental**
- Syntax may change in future releases
- Core C4 concepts are supported, but with some limitations

## Supported Diagram Types
1. System Context diagrams
2. Container diagrams
3. Component diagrams
4. Dynamic diagrams
5. Deployment diagrams

## Key Features

### Syntax Structure
```mermaid
C4Context
    Person(personAlias, "Label")
    System(systemAlias, "Label", "Optional Description")
    
    Rel(personAlias, systemAlias, "Uses")
    
    UpdateRelStyle(personAlias, systemAlias, $textColor="red", $lineColor="red")
```

### Element Types
- **Person**: External or internal users of the system
- **System**: External software systems interacting with the target system
- **Container**: Applications or data stores in the system
- **Component**: Internal components of containers
- **Boundary**: Groups elements together (System, Enterprise, Container)

### Relationship Definition
- Simple relationship syntax using `Rel()` function
- Direction can be controlled by element placement in the code
- Style customization available with `UpdateRelStyle()`

## Limitations
- No support for sprites/icons
- No support for tags
- No support for links
- No legend support
- No layout direction commands
- Fixed styling with consistent CSS colors
- More limited styling options compared to PlantUML

## Implementation Examples

### Basic System Context Example
```mermaid
C4Context
  title System Context diagram for Internet Banking System
  
  Enterprise_Boundary(b0, "BankBoundary") {
    Person(customerA, "Banking Customer A", "A customer of the bank, with personal bank accounts.")
    Person(customerB, "Banking Customer B")
    Person_Ext(customerC, "Banking Customer C", "desc")

    Person(customerD, "Banking Customer D", "A customer of the bank, <br/> with personal bank accounts.")

    System(SystemAA, "Internet Banking System", "Allows customers to view information about their bank accounts, and make payments.")
  }
  
  System_Ext(SystemE, "E-mail system", "The internal Microsoft Exchange e-mail system.")
  SystemDb(SystemF, "Mainframe Banking System", "Stores all of the core banking information about customers, accounts, transactions, etc.")

  Rel(customerA, SystemAA, "Uses")
  Rel(SystemAA, SystemE, "Sends e-mails", "SMTP")
  Rel(SystemAA, SystemF, "Uses")
  
  UpdateRelStyle(customerA, SystemAA, $textColor="red", $lineColor="red", $offsetX="5")
```

### Container Example
```mermaid
C4Container
    title Container diagram for Internet Banking System
    
    Person(customer, "Personal Banking Customer", "A customer of the bank, with personal bank accounts")
    
    Container_Boundary(c1, "Internet Banking") {
        Container(web_app, "Web Application", "Java, Spring MVC", "Delivers the static content and the Internet banking SPA")
        Container(spa, "Single-Page App", "JavaScript, Angular", "Provides all the Internet banking functionality to customers")
        Container(mobile_app, "Mobile App", "C#, Xamarin", "Provides a limited subset of the Internet banking functionality to customers")
        ContainerDb(database, "Database", "SQL Database", "Stores user registration information, hashed auth credentials, access logs, etc.")
        Container(backend_api, "API Application", "Java, Docker Container", "Provides Internet banking functionality via API")
    }
    
    System_Ext(email_system, "E-Mail System", "The internal Microsoft Exchange system")
    System_Ext(banking_system, "Mainframe Banking System", "Stores all of the core banking information about customers, accounts, transactions, etc.")

    Rel(customer, web_app, "Uses", "HTTPS")
    Rel(customer, spa, "Uses", "HTTPS")
    Rel(customer, mobile_app, "Uses")
    
    Rel(web_app, spa, "Delivers")
    Rel(spa, backend_api, "Uses", "async, JSON/HTTPS")
    Rel(mobile_app, backend_api, "Uses", "async, JSON/HTTPS")
    Rel_Back(database, backend_api, "Reads from and writes to", "sync, JDBC")
    
    Rel(email_system, customer, "Sends e-mails to")
    Rel(backend_api, email_system, "Sends e-mails using", "sync, SMTP")
    Rel(backend_api, banking_system, "Uses", "sync/async, XML/HTTPS")
```

## Practical Considerations
- Element positioning is determined by statement order
- Adjust layout by changing the sequence of element declarations
- Use descriptive aliases to make relationship definitions clearer
- Style updates can be applied after defining elements and relationships

## Resources
- Official documentation: [Mermaid C4 Diagrams](https://mermaid.js.org/syntax/c4.html)
- C4 Model reference: [C4 Model by Simon Brown](https://c4model.com/)