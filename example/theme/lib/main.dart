import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_structurizr/themes/github-dark.dart';

void main() {
  runApp(const ThemeExampleApp());
}

class ThemeExampleApp extends StatefulWidget {
  const ThemeExampleApp({Key? key}) : super(key: key);

  @override
  State<ThemeExampleApp> createState() => _ThemeExampleAppState();
}

class _ThemeExampleAppState extends State<ThemeExampleApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Theme Example',
      theme: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GitHub Syntax Highlighting'),
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                });
              },
              tooltip: 'Toggle dark mode',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Syntax Highlighting Demo',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Using ${isDarkMode ? 'GitHub Dark' : 'GitHub'} theme',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.only(bottom: 24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: HighlightView(
                            _dartCode,
                            language: 'dart',
                            theme: isDarkMode ? githubDarkTheme : githubTheme,
                            padding: const EdgeInsets.all(16),
                            textStyle: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: HighlightView(
                            _jsonCode,
                            language: 'json',
                            theme: isDarkMode ? githubDarkTheme : githubTheme,
                            padding: const EdgeInsets.all(16),
                            textStyle: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _dartCode = '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '\$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
''';

const _jsonCode = '''
{
  "workspace": {
    "id": "structurizr-demo",
    "name": "Structurizr Demo",
    "description": "This is a demo workspace.",
    "model": {
      "people": [
        {
          "id": "user",
          "name": "User",
          "description": "A user of the system."
        }
      ],
      "softwareSystems": [
        {
          "id": "softwareSystem",
          "name": "Software System",
          "description": "This is a software system.",
          "containers": [
            {
              "id": "webApplication",
              "name": "Web Application",
              "description": "Provides all functionality to users via a web interface.",
              "technology": "Flutter Web"
            },
            {
              "id": "apiApplication",
              "name": "API Application",
              "description": "Provides API functionality to the web application.",
              "technology": "Dart, Shelf"
            },
            {
              "id": "database",
              "name": "Database",
              "description": "Stores user data and other system information.",
              "technology": "PostgreSQL"
            }
          ]
        }
      ],
      "relationships": [
        {
          "id": "1",
          "sourceId": "user",
          "destinationId": "webApplication",
          "description": "Uses"
        },
        {
          "id": "2",
          "sourceId": "webApplication",
          "destinationId": "apiApplication",
          "description": "Makes API calls to"
        },
        {
          "id": "3",
          "sourceId": "apiApplication",
          "destinationId": "database",
          "description": "Reads from and writes to"
        }
      ]
    },
    "views": {
      "systemContextViews": [
        {
          "key": "systemContext",
          "description": "The system context diagram for the software system.",
          "softwareSystemId": "softwareSystem"
        }
      ],
      "containerViews": [
        {
          "key": "containers",
          "description": "The container diagram for the software system.",
          "softwareSystemId": "softwareSystem"
        }
      ]
    }
  }
}
''';