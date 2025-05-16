import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/infrastructure/persistence/file_system_helper.dart';
import 'package:path/path.dart' as path;

void main() {
  // Temporary directories for tests
  late Directory tempDir;
  
  setUp(() async {
    // Create temporary directory for tests
    tempDir = await Directory.systemTemp.createTemp('flutter_structurizr_test_');
  });
  
  tearDown(() async {
    // Clean up temporary directory
    await tempDir.delete(recursive: true);
  });
  
  group('FileSystemHelper', () {
    test('should ensure directory exists', () async {
      // Define test directory
      final testDirPath = path.join(tempDir.path, 'test_dir');
      
      // Verify directory doesn't exist yet
      expect(await Directory(testDirPath).exists(), isFalse);
      
      // Ensure directory exists
      await FileSystemHelper.ensureDirectoryExists(testDirPath);
      
      // Verify directory exists now
      expect(await Directory(testDirPath).exists(), isTrue);
      
      // Call again to verify it handles existing directories
      await FileSystemHelper.ensureDirectoryExists(testDirPath);
      expect(await Directory(testDirPath).exists(), isTrue);
    });
    
    test('should generate timestamped filenames', () {
      // Generate timestamped filename
      final filename = FileSystemHelper.generateTimestampedFilename('test', 'json');
      
      // Verify format (test-YYYY-MM-DD_HH-MM-SS.json)
      expect(filename, matches(r'test-\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}.*\.json'));
    });
    
    test('should copy files with progress reporting', () async {
      // Create source file
      final sourceFile = File(path.join(tempDir.path, 'source.txt'));
      await sourceFile.writeAsString('Hello, World!');
      
      // Define destination file
      final destFile = File(path.join(tempDir.path, 'dest.txt'));
      
      // Verify destination doesn't exist yet
      expect(await destFile.exists(), isFalse);
      
      // Track progress
      final progress = <double>[];
      
      // Copy file with progress reporting
      await FileSystemHelper.copyFileWithProgress(
        sourceFile,
        destFile,
        onProgress: (p) => progress.add(p),
      );
      
      // Verify destination exists
      expect(await destFile.exists(), isTrue);
      
      // Verify content was copied
      expect(await destFile.readAsString(), 'Hello, World!');
      
      // Verify progress reporting
      expect(progress, isNotEmpty);
      expect(progress.first, 0.0); // Starting progress
      expect(progress.last, 1.0);  // Final progress
    });
    
    test('should delete file if exists', () async {
      // Create test file
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('Test content');
      
      // Verify file exists
      expect(await testFile.exists(), isTrue);
      
      // Delete file
      await FileSystemHelper.deleteFileIfExists(testFile.path);
      
      // Verify file doesn't exist
      expect(await testFile.exists(), isFalse);
      
      // Call again to verify it handles non-existent files
      await FileSystemHelper.deleteFileIfExists(testFile.path);
      expect(await testFile.exists(), isFalse);
    });
    
    test('should get files with extension', () async {
      // Create test files with different extensions
      final txtFile1 = File(path.join(tempDir.path, 'test1.txt'));
      final txtFile2 = File(path.join(tempDir.path, 'test2.txt'));
      final jsonFile = File(path.join(tempDir.path, 'test.json'));
      
      await txtFile1.writeAsString('Text file 1');
      await txtFile2.writeAsString('Text file 2');
      await jsonFile.writeAsString('{"test": true}');
      
      // Get files with .txt extension
      final txtFiles = await FileSystemHelper.getFilesWithExtension(
        tempDir.path,
        '.txt',
      );
      
      // Verify results
      expect(txtFiles.length, 2);
      expect(txtFiles.any((f) => path.basename(f.path) == 'test1.txt'), isTrue);
      expect(txtFiles.any((f) => path.basename(f.path) == 'test2.txt'), isTrue);
      
      // Get files with .json extension
      final jsonFiles = await FileSystemHelper.getFilesWithExtension(
        tempDir.path,
        '.json',
      );
      
      // Verify results
      expect(jsonFiles.length, 1);
      expect(jsonFiles.first.path, endsWith('test.json'));
    });
    
    test('should get file extension', () {
      // Test various paths
      expect(FileSystemHelper.getFileExtension('test.txt'), 'txt');
      expect(FileSystemHelper.getFileExtension('/path/to/file.json'), 'json');
      expect(FileSystemHelper.getFileExtension('file.with.multiple.dots.md'), 'md');
      expect(FileSystemHelper.getFileExtension('no-extension'), 'no-extension');
    });
    
    test('should get file base name', () {
      // Test with platform-specific separator
      final separator = Platform.pathSeparator;
      
      expect(
        FileSystemHelper.getFileBaseName('file.txt'),
        equals('file')
      );
      
      expect(
        FileSystemHelper.getFileBaseName('path${separator}to${separator}file.json'),
        equals('file')
      );
      
      expect(
        FileSystemHelper.getFileBaseName('file.with.multiple.dots.md'),
        equals('file.with.multiple.dots')
      );
    });
  });
}