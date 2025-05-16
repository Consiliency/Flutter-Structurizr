import 'dart:io';
import 'package:path/path.dart' as path;
import 'error_reporter.dart';

/// Handles loading DSL files from the file system, including nested inclusions.
class FileLoader {
  /// The base directory for resolving relative paths.
  final String baseDirectory;
  
  /// The error reporter for reporting file loading errors.
  final ErrorReporter errorReporter;
  
  /// A set of file paths that have been included to detect circular inclusions.
  final Set<String> _includedFiles = {};
  
  /// Creates a new file loader with the given base directory and error reporter.
  /// The base directory should be the directory containing the root DSL file.
  FileLoader({
    required this.baseDirectory,
    required this.errorReporter,
  });
  
  /// Loads a DSL file from the given path.
  /// 
  /// The [filePath] can be absolute or relative to the base directory.
  /// If [isRootFile] is true, this is the initial file being loaded and sets the base directory.
  /// 
  /// Returns the contents of the file as a string, or null if the file could not be loaded.
  String? loadFile(String filePath, {bool isRootFile = false}) {
    // Normalize and resolve the path
    String normalizedPath;
    if (path.isAbsolute(filePath)) {
      normalizedPath = filePath;
    } else {
      normalizedPath = path.normalize(path.join(baseDirectory, filePath));
    }
    
    // Check for circular inclusion
    if (_includedFiles.contains(normalizedPath)) {
      errorReporter.reportStandardError(
        'Circular file inclusion detected: $filePath',
        0,
      );
      return null;
    }
    
    // Add to included files set
    _includedFiles.add(normalizedPath);
    
    try {
      // Try to read the file
      final file = File(normalizedPath);
      if (!file.existsSync()) {
        errorReporter.reportStandardError(
          'File not found: $filePath',
          0,
        );
        return null;
      }
      
      return file.readAsStringSync();
    } catch (e) {
      errorReporter.reportStandardError(
        'Error loading file $filePath: $e',
        0,
      );
      return null;
    }
  }
  
  /// Resolves a relative file path against the base directory.
  String resolveFilePath(String filePath) {
    if (path.isAbsolute(filePath)) {
      return filePath;
    }
    return path.normalize(path.join(baseDirectory, filePath));
  }
}