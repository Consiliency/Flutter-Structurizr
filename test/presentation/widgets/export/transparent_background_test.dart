import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Transparent background image exists and is accessible', () {
    // Check if the transparent background image exists
    final file = File('/home/jenner/Code/dart-structurizr/assets/images/transparent_background.png');
    expect(file.existsSync(), isTrue, reason: 'Transparent background image file should exist');
    
    // Check that the file has some content (non-zero size)
    final fileStats = file.statSync();
    expect(fileStats.size, greaterThan(0), reason: 'Transparent background image should not be empty');
  });
  
  testWidgets('Transparent background image can be loaded by DecorationImage', (WidgetTester tester) async {
    // Create a widget that uses the transparent background image
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/transparent_background.png'),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    // Verify that the decorated box is present
    expect(find.byType(DecoratedBox), findsOneWidget);
    
    // We can't directly verify that the image loaded correctly in a widget test,
    // but this at least verifies that the asset path is valid and the widget builds
  });
}