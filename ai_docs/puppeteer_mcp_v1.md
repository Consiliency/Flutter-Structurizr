# Puppeteer MCP Server Implementation

This document provides a comprehensive overview of the Puppeteer server implementation for the Model Context Protocol (MCP), which enables browser automation for Large Language Models (LLMs). This information is relevant for implementing similar functionality in Dart applications, particularly for the dart-structurizr project.

## Overview

The Puppeteer MCP server provides browser automation capabilities that allow LLMs to interact with web pages, capture screenshots, and execute JavaScript. This enables a wide range of web-based interactions from within the dart-structurizr application.

## Key Features

- **Browser Navigation**: Programmatically navigate to URLs
- **Screenshot Capture**: Take screenshots of entire pages or specific elements
- **Element Interaction**: Click, hover over, and fill form elements
- **JavaScript Execution**: Run custom JavaScript within the browser context
- **Configurable Launch Options**: Customize browser behavior (headless/headed, viewport size, etc.)

## Available Tools

### 1. puppeteer_navigate

Navigates to a specified URL.

**Parameters**:
- `url` (string, required): The URL to navigate to
- `launchOptions` (object, optional): PuppeteerJS LaunchOptions. Example: `{ headless: true, args: ['--no-sandbox'] }`
- `allowDangerous` (boolean, optional): Allow dangerous LaunchOptions that reduce security. Default: false

**Example**:
```json
{
  "url": "https://example.com",
  "launchOptions": {
    "headless": false,
    "defaultViewport": { "width": 1280, "height": 720 }
  }
}
```

### 2. puppeteer_screenshot

Takes a screenshot of the current page or a specific element.

**Parameters**:
- `name` (string, required): Name for the screenshot
- `selector` (string, optional): CSS selector for element to screenshot
- `width` (number, optional): Width in pixels (default: 800)
- `height` (number, optional): Height in pixels (default: 600)

**Returns**:
- Screenshot data accessible at `screenshot://<name>`

### 3. puppeteer_click

Clicks an element on the page.

**Parameters**:
- `selector` (string, required): CSS selector for element to click

### 4. puppeteer_fill

Fills out an input field.

**Parameters**:
- `selector` (string, required): CSS selector for input field
- `value` (string, required): Value to fill

### 5. puppeteer_select

Selects an option from a dropdown menu.

**Parameters**:
- `selector` (string, required): CSS selector for element to select
- `value` (string, required): Value to select

### 6. puppeteer_hover

Hovers over an element on the page.

**Parameters**:
- `selector` (string, required): CSS selector for element to hover

### 7. puppeteer_evaluate

Executes JavaScript in the browser console.

**Parameters**:
- `script` (string, required): JavaScript code to execute

**Returns**:
- The result of the JavaScript evaluation

## Resource Management

The Puppeteer server manages two types of resources:

1. **Screenshots**: Accessible via `screenshot://<name>`
2. **Console Logs**: Accessible via `console://logs`

These resources are exposed to the host application and can be retrieved and displayed as needed.

## Implementation Architecture

The Puppeteer MCP server is typically implemented with the following components:

1. **Tool Definitions**: Each tool has a name, description, and JSON schema describing its parameters
2. **Tool Handlers**: Functions that execute the actual operations (navigate, screenshot, etc.)
3. **Resource Handlers**: Logic for storing and retrieving resources (screenshots, logs)
4. **Browser Management**: Logic for launching, configuring, and cleaning up browser instances

## Configuration Options

The server can be configured through several methods:

### Environment Variables

```json
{
  "env": {
    "PUPPETEER_LAUNCH_OPTIONS": "{ \"headless\": false, \"executablePath\": \"C:/Program Files/Google/Chrome/Application/chrome.exe\", \"args\": [] }",
    "ALLOW_DANGEROUS": "true"
  }
}
```

### Tool Parameters

Each tool can receive configuration parameters such as:
- Browser viewport dimensions
- Selectors for specific elements
- JavaScript code to execute

## Considerations for Dart Implementation

When implementing similar functionality in Dart for the dart-structurizr project, consider the following:

1. **Browser Automation Libraries**: 
   - [webkit_inspection_protocol](https://pub.dev/packages/webkit_inspection_protocol)
   - [puppeteer](https://pub.dev/packages/puppeteer)
   - [webdriver](https://pub.dev/packages/webdriver)

2. **JSON-RPC Communication**:
   - Implement the MCP JSON-RPC protocol for communication with LLM hosts
   - Support resource listing and retrieval

3. **Tool Implementation**:
   - Match the functionality of the TypeScript implementation
   - Maintain compatible parameter schemas
   - Support error handling and reporting

4. **Resource Management**:
   - Implement a system for storing and retrieving screenshots
   - Track console logs and make them accessible

5. **Browser Management**:
   - Handle browser lifecycle (launch, configure, cleanup)
   - Support both headless and headed modes
   - Allow custom launch options

## Integration with dart-structurizr

To integrate browser automation into dart-structurizr:

1. **Diagram Interaction**: Allow users to interact with diagrams via browser automation
2. **Screenshot Export**: Capture and export diagram screenshots
3. **Web-based Rendering**: Render diagrams in a browser context for maximum compatibility
4. **Interactive Elements**: Enable clicking and hovering over diagram elements

## Example Code

### TypeScript Example (for reference)

```typescript
async function handleToolCall(name: string, args: Record<string, unknown>): Promise<{ toolResult: CallToolResult }> {
  const page = await ensureBrowser();
  switch (name) {
    case "puppeteer_screenshot": {
      const width = (args.width as number) ?? 800;
      const height = (args.height as number) ?? 600;
      await page.setViewportSize({ width, height });
      const screenshot = await (args.selector 
        ? page.locator(args.selector as string).screenshot() 
        : page.screenshot());
      const base64Screenshot = encodeBase64(screenshot);
      screenshots.set(args.name as string, base64Screenshot);
      server.notification({ method: "notifications/resources/list_changed" });
      return {
        toolResult: {
          content: [
            { type: "text", text: `Screenshot '${args.name}' taken at ${width}x${height}` },
            { type: "image", data: base64Screenshot, mimeType: "image/png" }
          ],
          isError: false,
        },
      };
    }
    // Additional tool cases...
  }
}
```

### Potential Dart Implementation Sketch

```dart
class PuppeteerMcpServer {
  late Browser browser;
  final Map<String, Uint8List> screenshots = {};
  
  Future<Map<String, dynamic>> handleNavigate(Map<String, dynamic> args) async {
    final page = await ensureBrowser();
    await page.goto(args['url']);
    return {
      'content': [
        {'type': 'text', 'text': 'Navigated to ${args['url']}'}
      ],
      'isError': false
    };
  }
  
  Future<Map<String, dynamic>> handleScreenshot(Map<String, dynamic> args) async {
    final page = await ensureBrowser();
    final width = args['width'] ?? 800;
    final height = args['height'] ?? 600;
    await page.setViewport(width: width, height: height);
    
    Uint8List screenshot;
    if (args.containsKey('selector')) {
      final element = await page.querySelector(args['selector']);
      screenshot = await element.screenshot();
    } else {
      screenshot = await page.screenshot();
    }
    
    screenshots[args['name']] = screenshot;
    return {
      'content': [
        {'type': 'text', 'text': 'Screenshot \'${args['name']}\' taken at ${width}x${height}'},
        {'type': 'image', 'data': base64Encode(screenshot), 'mimeType': 'image/png'}
      ],
      'isError': false
    };
  }
  
  // Additional tool handlers...
  
  Future<Browser> ensureBrowser() async {
    if (browser == null) {
      browser = await puppeteer.launch(
        headless: true,
        args: ['--disable-dev-shm-usage'],
      );
    }
    return browser;
  }
}
```

## Conclusion

Implementing a Puppeteer MCP server in Dart for the dart-structurizr project would enable powerful web-based interactions, screenshot capabilities, and JavaScript execution. This functionality could be leveraged to enhance the rendering, export, and interaction capabilities of the C4 architecture diagrams, providing users with a more flexible and feature-rich experience.

## References

- [Model Context Protocol Documentation](https://modelcontextprotocol.info/)
- [Puppeteer Official Documentation](https://pptr.dev/)
- [MCP NPM Package](https://www.npmjs.com/package/@modelcontextprotocol/server-puppeteer)
- [Dart Puppeteer Package](https://pub.dev/packages/puppeteer)