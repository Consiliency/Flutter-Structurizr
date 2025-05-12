import 'package:flutter/material.dart' hide Element, Container, View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:flutter_structurizr/presentation/widgets/view_selector.dart';

void main() {
  group('ViewSelector Widget Tests', () {
    // Create a test workspace with various view types
    final workspace = Workspace(
      name: 'Test Workspace',
      description: 'Workspace for testing',
      model: Model(
        people: [],
        softwareSystems: [],
      ),
      views: Views(
        systemContextViews: [
          SystemContextView(
            key: 'system-1',
            name: 'System Context 1',
            description: 'System context view for testing',
            softwareSystemId: 'system-1',
          ),
        ],
        containerViews: [
          ContainerView(
            key: 'container-1',
            name: 'Container View 1',
            description: 'Container view for testing',
            softwareSystemId: 'system-1',
          ),
          ContainerView(
            key: 'container-2',
            name: 'Container View 2',
            description: 'Another container view',
            softwareSystemId: 'system-1',
          ),
        ],
        componentViews: [
          ComponentView(
            key: 'component-1',
            name: 'Component View 1',
            description: 'Component view for testing',
            containerId: 'container-1',
          ),
        ],
      ),
    );

    testWidgets('ViewSelector renders in compact mode', (WidgetTester tester) async {
      // Build the widget in compact mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: ViewSelector(
                workspace: workspace,
                showThumbnails: false,
                compact: true,
              ),
            ),
          ),
        ),
      );

      // Verify dropdown is shown
      expect(find.text('Select View'), findsOneWidget);
      
      // Tap the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      
      // Verify view options are shown
      expect(find.text('System Context 1'), findsOneWidget);
      expect(find.text('Container View 1'), findsOneWidget);
      expect(find.text('Container View 2'), findsOneWidget);
      expect(find.text('Component View 1'), findsOneWidget);
    });
    
    testWidgets('ViewSelector renders in flat mode', (WidgetTester tester) async {
      // Build the widget in flat mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ViewSelector(
                workspace: workspace,
                showThumbnails: false,
                groupByType: false,
              ),
            ),
          ),
        ),
      );

      // Verify title is shown
      expect(find.text('Select View'), findsOneWidget);
      
      // Verify view items are shown
      expect(find.text('System Context 1'), findsOneWidget);
      expect(find.text('Container View 1'), findsOneWidget);
      expect(find.text('Container View 2'), findsOneWidget);
      expect(find.text('Component View 1'), findsOneWidget);
    });
    
    testWidgets('ViewSelector renders in grouped mode', (WidgetTester tester) async {
      // Build the widget in grouped mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ViewSelector(
                workspace: workspace,
                showThumbnails: false,
                groupByType: true,
              ),
            ),
          ),
        ),
      );

      // Verify title is shown
      expect(find.text('Views'), findsOneWidget);
      
      // Verify group headers are shown
      expect(find.text('System Context Views (1)'), findsOneWidget);
      expect(find.text('Container Views (2)'), findsOneWidget);
      expect(find.text('Component Views (1)'), findsOneWidget);
    });
    
    testWidgets('ViewSelector fires selection callback', (WidgetTester tester) async {
      // Track selected view key
      String? selectedViewKey;
      
      // Build the widget with selection callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ViewSelector(
                workspace: workspace,
                showThumbnails: false,
                groupByType: false,
                onViewSelected: (viewKey) {
                  selectedViewKey = viewKey;
                },
              ),
            ),
          ),
        ),
      );

      // Find and tap on a view
      final containerViewTile = find.text('Container View 1');
      expect(containerViewTile, findsOneWidget);
      await tester.tap(containerViewTile);
      await tester.pump();
      
      // Verify callback was called with correct view key
      expect(selectedViewKey, equals('container-1'));
    });
    
    testWidgets('ViewSelector shows empty state when no views available', (WidgetTester tester) async {
      // Create an empty workspace
      final emptyWorkspace = Workspace(
        name: 'Empty Workspace',
        description: 'Empty workspace for testing',
        model: Model(
          people: [],
          softwareSystems: [],
        ),
        views: Views(),
      );
      
      // Build the widget with empty workspace
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: ViewSelector(
                workspace: emptyWorkspace,
                showThumbnails: false,
                groupByType: true,
              ),
            ),
          ),
        ),
      );

      // Verify empty state is shown
      expect(find.text('No views available'), findsOneWidget);
    });
  });
}