import 'package:freezed_annotation/freezed_annotation.dart';

// Re-enable these lines to make the code generation work
part 'documentation.freezed.dart';
part 'documentation.g.dart';

/// Format of documentation content
enum DocumentationFormat {
  markdown,
  asciidoc,
}

/// The Documentation class represents all documentation associated with a workspace.
@freezed
class Documentation with _$Documentation {
  const Documentation._();
  
  /// Creates a new documentation container with the given properties.
  const factory Documentation({
    /// Sections of documentation
    @Default([]) List<DocumentationSection> sections,
    
    /// Architecture decision records
    @Default([]) List<Decision> decisions,
    
    /// Images referenced in the documentation
    @Default([]) List<Image> images,
  }) = _Documentation;

  /// Creates a documentation object from a JSON object.
  factory Documentation.fromJson(Map<String, dynamic> json) => _$DocumentationFromJson(json);
}

/// A section of documentation content.
@freezed
class DocumentationSection with _$DocumentationSection {
  const DocumentationSection._();
  
  /// Creates a new documentation section with the given properties.
  const factory DocumentationSection({
    /// Title of the section
    required String title,
    
    /// Content of the section (Markdown or AsciiDoc)
    required String content,
    
    /// Format of the content
    @Default(DocumentationFormat.markdown) DocumentationFormat format,
    
    /// Order/position of the section
    required int order,
    
    /// Optional filename where this section originated
    String? filename,
    
    /// Optional element this section relates to
    String? elementId,
  }) = _DocumentationSection;

  /// Creates a documentation section from a JSON object.
  factory DocumentationSection.fromJson(Map<String, dynamic> json) => _$DocumentationSectionFromJson(json);
}

/// An architecture decision record.
@freezed
class Decision with _$Decision {
  const Decision._();
  
  /// Creates a new decision record with the given properties.
  const factory Decision({
    /// Unique identifier for this decision
    required String id,
    
    /// Date the decision was made
    required DateTime date,
    
    /// Status of the decision
    required String status,
    
    /// Title of the decision
    required String title,
    
    /// Content of the decision record (Markdown or AsciiDoc)
    required String content,
    
    /// Format of the content
    @Default(DocumentationFormat.markdown) DocumentationFormat format,
    
    /// Optional element this decision relates to
    String? elementId,
    
    /// Optional list of links to other decisions
    @Default([]) List<String> links,
  }) = _Decision;

  /// Creates a decision from a JSON object.
  factory Decision.fromJson(Map<String, dynamic> json) => _$DecisionFromJson(json);
}

/// An image referenced in documentation.
@freezed
class Image with _$Image {
  const Image._();
  
  /// Creates a new image with the given properties.
  const factory Image({
    /// Name of the image
    required String name,
    
    /// Base64 encoded content
    required String content,
    
    /// MIME type (e.g., "image/png")
    required String type,
  }) = _Image;

  /// Creates an image from a JSON object.
  factory Image.fromJson(Map<String, dynamic> json) => _$ImageFromJson(json);
}