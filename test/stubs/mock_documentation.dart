import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/model/model.dart';

/// A mock implementation of the Documentation class for testing.
/// This class provides the necessary functionality to pass to DocumentationNavigator
/// and MarkdownRenderer during tests, without requiring the freezed implementation.
class MockDocumentation implements Documentation {
  @override
  final List<DocumentationSection> sections;
  
  @override
  final List<Decision> decisions;
  
  @override
  final List<Image> images;

  const MockDocumentation({
    this.sections = const [],
    this.decisions = const [],
    this.images = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'sections': sections.map((x) => x.toJson()).toList(),
      'decisions': decisions.map((x) => x.toJson()).toList(),
      'images': images.map((x) => x.toJson()).toList(),
    };
  }

  /// Factory to create a MockDocumentation from a real Documentation
  factory MockDocumentation.fromDocumentation(Documentation doc) {
    return MockDocumentation(
      sections: doc.sections,
      decisions: doc.decisions,
      images: doc.images,
    );
  }
}

/// A mock implementation of the DocumentationConverter for testing.
/// This handles the conversion between JSON and MockDocumentation objects.
class MockDocumentationConverter implements DocumentationConverter {
  const MockDocumentationConverter();

  @override
  MockDocumentation fromJson(Map<String, dynamic> json) {
    return MockDocumentation(
      sections: json['sections'] != null 
          ? List<DocumentationSection>.from(json['sections'].map((x) => DocumentationSection.fromJson(x)))
          : [],
      decisions: json['decisions'] != null
          ? List<Decision>.from(json['decisions'].map((x) => Decision.fromJson(x)))
          : [],
      images: json['images'] != null
          ? List<Image>.from(json['images'].map((x) => Image.fromJson(x)))
          : [],
    );
  }

  @override
  Map<String, dynamic> toJson(Documentation documentation) => documentation.toJson();
}

/// A copy-with interface that mirrors the expected Freezed interface for testing
class MockDocumentationCopyWith<$Res> {
  final MockDocumentation value;
  final $Res Function(MockDocumentation) then;
  
  MockDocumentationCopyWith(this.value, this.then);
  
  $Res call({
    List<DocumentationSection>? sections,
    List<Decision>? decisions,
    List<Image>? images,
  }) {
    return then(MockDocumentation(
      sections: sections ?? value.sections,
      decisions: decisions ?? value.decisions, 
      images: images ?? value.images,
    ));
  }
}

/// An extension on MockDocumentation to provide copyWith functionality
extension MockDocumentationExtension on MockDocumentation {
  MockDocumentationCopyWith<MockDocumentation> get copyWith {
    return MockDocumentationCopyWith<MockDocumentation>(
      this,
      (MockDocumentation value) => value,
    );
  }
}

/// A helper class for testing documentation-related widgets
class TestDocumentationFactory {
  /// Creates a test workspace with documentation
  static Workspace createWorkspaceWithDocumentation({
    List<DocumentationSection> sections = const [],
    List<Decision> decisions = const [],
    List<Image> images = const [],
  }) {
    // For tests, we directly create a workspace without going through the freezed path
    // that would cause the copyWith issue
    final docMock = MockDocumentation(
      sections: sections,
      decisions: decisions,
      images: images,
    );
    
    // Create the workspace for testing
    return Workspace(
      id: 1,
      name: 'Test Workspace',
      model: Model(),
      documentation: docMock,
    );
  }
}