# Structurizr Lite Documentation Summary

Structurizr Lite is a free and open-source version of the Structurizr architecture visualization tool, designed for individual use to view, edit, and create software architecture diagrams, documentation, and architecture decision records (ADRs) using the C4 model approach.

## 1. Overview and Key Concepts

Structurizr Lite allows architects and developers to:
- View and edit architecture diagrams based on the C4 model
- View documentation written in Markdown or AsciiDoc
- View architecture decision records (ADRs)
- Define workspaces using either DSL (Domain Specific Language) or JSON format

Key benefits:
- Free and open-source
- Simplified local development workflow
- Integration with cloud service/on-premises installation
- Automatic refresh and sync capabilities
- Docker-based deployment for easy setup

## 2. Installation and Setup

### 2.1 Docker Installation (Recommended)

```bash
# Pull the image
docker pull structurizr/lite

# Start the container (replace PATH with your local directory path)
docker run -it --rm -p 8080:8080 -v PATH:/usr/local/structurizr structurizr/lite
```

Example with a specific path:
```bash
docker run -it --rm -p 8080:8080 -v /Users/simon/structurizr:/usr/local/structurizr structurizr/lite
```

### 2.2 Spring Boot Installation

Requirements:
- Java 17+ (required)
- Graphviz (optional, for automatic layout)

Steps:
1. Download `structurizr-lite.war` from https://github.com/structurizr/lite/releases
2. Start with the command:
```bash
java -Djdk.util.jar.enableMultiRelease=false -jar structurizr-lite.war PATH
```

Where PATH is the directory containing your workspace files.

## 3. Workspace Configuration

Structurizr Lite looks for the following files in your specified directory:
- `workspace.dsl` - DSL format definition (checked first)
- `workspace.json` - JSON format definition (checked second)

If neither file exists, a basic DSL file will be created when Lite starts up.

### 3.1 Basic Workspace Example

Create a `workspace.dsl` file with the following content:

```
workspace {
    model {
        user = person "User"
        softwareSystem = softwareSystem "Software System"

        user -> softwareSystem "Uses"
    }

    views {
        systemContext softwareSystem "Diagram1" {
            include *
            autoLayout
        }

        theme default
    }
}
```

### 3.2 Adding Documentation

1. Create a `docs` subdirectory
2. Add Markdown files like `01-context.md` with content:
```markdown
## Context

Here is a description of my software system...

![](embed:Diagram1)
```

3. Link to the docs in your workspace:
```
workspace {
    model {
        user = person "User"
        softwareSystem = softwareSystem "Software System" {
            !docs docs
        }
        
        user -> softwareSystem "Uses"
    }
    
    views {
        systemContext softwareSystem "Diagram1" {
            include *
            autoLayout
        }
        
        theme default
    }
}
```

## 4. Usage and Features

### 4.1 Accessing the UI

Open your web browser and navigate to `http://localhost:8080` to view the workspace.

### 4.2 Auto-refresh and Auto-save

You can configure auto-refresh and auto-save in a `structurizr.properties` file:

```properties
# Auto-save with 5 second interval (0 to disable)
structurizr.autoSaveInterval=5000

# Auto-refresh for diagram changes (0 to disable)
structurizr.autoRefreshInterval=2000
```

### 4.3 Custom Workspace Path

You can specify a subdirectory for your workspace:

```bash
# Docker
docker run -it --rm -p 8080:8080 -v /Users/simon/structurizr:/usr/local/structurizr -e STRUCTURIZR_WORKSPACE_PATH=software-system-1 structurizr/lite

# Spring Boot
export STRUCTURIZR_WORKSPACE_PATH=software-system-1
java -jar structurizr-lite.war /Users/simon/structurizr
```

### 4.4 Custom Workspace Filename

To use files with names other than `workspace.dsl` or `workspace.json`:

```bash
docker run -it --rm -p 8080:8080 -v /Users/simon/structurizr:/usr/local/structurizr -e STRUCTURIZR_WORKSPACE_FILENAME=system-landscape structurizr/lite
```

### 4.5 Read-only Diagrams

To make diagrams read-only:

```properties
structurizr.editable=false
```

## 5. Auto-Sync with Remote Workspaces

Structurizr Lite includes an auto-sync feature that allows synchronization with remote workspaces in the Structurizr cloud service or on-premises installation.

### 5.1 Configuration

Create a `structurizr.properties` file with the following settings:

```properties
structurizr.remote.workspaceId=ID
structurizr.remote.apiKey=KEY
structurizr.remote.apiSecret=SECRET
```

Optional properties:
- `structurizr.remote.apiUrl`: API URL for on-premises installations
- `structurizr.remote.branch`: Workspace branch
- `structurizr.remote.passphrase`: Client-side encryption passphrase

### 5.2 Sync Workflow

With auto-sync configured:
1. Lite pulls a copy of your remote workspace on startup
2. You edit the workspace locally (usually by modifying the DSL file)
3. When you shut down Lite, it automatically pushes changes to the remote workspace

This enables a local authoring workflow that integrates with centralized workspaces.

## 6. Limitations and Considerations

- **Single-user design**: Structurizr Lite is designed for individual use, not multi-user collaboration
- **Warning**: Having multiple people concurrently access the same Structurizr Lite instance or running multiple instances against the same folder may corrupt workspaces
- **On-premises support**: Auto-sync doesn't support on-premises installations with self-signed certificates
- **Automatic layout**: The automatic layout feature has known limitations in element positioning

## 7. Working with the C4 Model

Structurizr Lite implements the C4 model, which defines several diagram levels:

1. **System Context diagrams**: High-level overview showing a system in its environment
2. **Container diagrams**: Show the high-level technical building blocks of a system
3. **Component diagrams**: Decompose containers into components
4. **Code diagrams**: Show how components are implemented

All these diagrams can be defined in the Structurizr DSL file and viewed in Structurizr Lite.

## 8. Integration with Development Workflow

Recommended workflow:
1. Store DSL files in source control
2. Use Structurizr Lite locally for authoring and testing
3. Use auto-sync to publish to a central Structurizr installation
4. Optionally automate diagram generation as part of CI/CD processes

## 9. Resources

- Docker image: https://hub.docker.com/r/structurizr/lite
- Spring Boot application: https://github.com/structurizr/lite/releases
- GitHub repository: https://github.com/structurizr/lite
- Issue tracker: https://github.com/structurizr/lite/issues

This summary covers the key aspects of Structurizr Lite necessary for implementing similar functionality in a Dart/Flutter port of the Structurizr visualization system.