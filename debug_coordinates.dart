#!/usr/bin/env dart

/// Automated coordinate system debugging script
/// This script uses Puppeteer to systematically test mouse clicks at various positions
/// and zoom levels to identify coordinate transformation issues.

import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Starting automated coordinate debugging...');
  
  // Step 1: Launch the Flutter app in web mode for Puppeteer access
  print('📱 Launching Flutter app in web mode...');
  final webProcess = await Process.start(
    'flutter', 
    ['run', '-d', 'web-server', '--web-port=8080'],
    workingDirectory: '/home/jenner/Code/dart-structurizr',
  );
  
  // Give the app time to start
  await Future.delayed(Duration(seconds: 10));
  
  // Step 2: Create coordinate test plan
  final testPlan = createCoordinateTestPlan();
  
  print('🎯 Created test plan with ${testPlan.length} test cases');
  
  // Step 3: Execute automated testing
  for (int i = 0; i < testPlan.length; i++) {
    final test = testPlan[i];
    print('\n📍 Test ${i + 1}/${testPlan.length}: ${test.description}');
    
    await executeCoordinateTest(test);
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  print('\n✅ Coordinate debugging complete!');
  webProcess.kill();
}

class CoordinateTest {
  final String description;
  final double x;
  final double y;
  final String expectedElement;
  final double? zoomLevel;
  final bool shouldZoomFirst;
  
  CoordinateTest({
    required this.description,
    required this.x,
    required this.y,
    required this.expectedElement,
    this.zoomLevel,
    this.shouldZoomFirst = false,
  });
}

List<CoordinateTest> createCoordinateTestPlan() {
  return [
    // Test 1: Basic element clicks at 1.0 zoom
    CoordinateTest(
      description: 'Click person1 at 1.0 zoom (expected at ~346,66)',
      x: 346, y: 66,
      expectedElement: 'person1',
    ),
    CoordinateTest(
      description: 'Click system1 at 1.0 zoom (expected at ~778,474)',
      x: 778, y: 474,
      expectedElement: 'system1',
    ),
    
    // Test 2: Element clicks after zoom out
    CoordinateTest(
      description: 'Zoom to 0.7 then click person1',
      x: 346, y: 66,
      expectedElement: 'person1',
      zoomLevel: 0.7,
      shouldZoomFirst: true,
    ),
    CoordinateTest(
      description: 'Zoom to 0.7 then click system1',
      x: 778, y: 474,
      expectedElement: 'system1',
      zoomLevel: 0.7,
      shouldZoomFirst: true,
    ),
    
    // Test 3: Element clicks after zoom in
    CoordinateTest(
      description: 'Zoom to 1.5 then click person1',
      x: 346, y: 66,
      expectedElement: 'person1',
      zoomLevel: 1.5,
      shouldZoomFirst: true,
    ),
    
    // Test 4: Grid pattern test at various zoom levels
    CoordinateTest(
      description: 'Grid test: top-left at 0.5 zoom',
      x: 100, y: 100,
      expectedElement: 'none',
      zoomLevel: 0.5,
      shouldZoomFirst: true,
    ),
    CoordinateTest(
      description: 'Grid test: center at 0.5 zoom',
      x: 400, y: 300,
      expectedElement: 'none',
      zoomLevel: 0.5,
      shouldZoomFirst: true,
    ),
    CoordinateTest(
      description: 'Grid test: bottom-right at 0.5 zoom',
      x: 700, y: 500,
      expectedElement: 'none',
      zoomLevel: 0.5,
      shouldZoomFirst: true,
    ),
  ];
}

Future<void> executeCoordinateTest(CoordinateTest test) async {
  try {
    print('  🎯 Testing click at (${test.x}, ${test.y})');
    
    if (test.shouldZoomFirst && test.zoomLevel != null) {
      await simulateZoom(test.zoomLevel!);
      await Future.delayed(Duration(milliseconds: 300));
    }
    
    await simulateClick(test.x, test.y);
    await Future.delayed(Duration(milliseconds: 200));
    
    // Log results from Flutter debug output
    print('  📊 Expected: ${test.expectedElement}');
    
  } catch (e) {
    print('  ❌ Test failed: $e');
  }
}

Future<void> simulateClick(double x, double y) async {
  // This would use Puppeteer MCP to simulate clicks
  print('  🖱️  Simulating click at ($x, $y)');
  
  // The actual implementation would use the Puppeteer MCP tool
  // For now, we'll create the plan and implement with MCP tools
}

Future<void> simulateZoom(double zoomLevel) async {
  // This would use Puppeteer MCP to simulate zoom
  print('  🔍 Simulating zoom to $zoomLevel');
  
  // The actual implementation would use the Puppeteer MCP tool
}