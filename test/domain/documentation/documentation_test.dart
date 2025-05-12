import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';

void main() {
  group('Documentation', () {
    test('creates an empty Documentation instance', () {
      final documentation = Documentation();
      expect(documentation.sections, isEmpty);
      expect(documentation.decisions, isEmpty);
      expect(documentation.images, isEmpty);
    });

    test('creates a Documentation instance with sections', () {
      final section = DocumentationSection(
        title: 'Getting Started',
        content: '# Getting Started\n\nWelcome to the project.',
        order: 1,
      );
      
      final documentation = Documentation(sections: [section]);
      expect(documentation.sections.length, 1);
      expect(documentation.sections.first.title, 'Getting Started');
    });

    test('serializes and deserializes a Documentation instance', () {
      final section = DocumentationSection(
        title: 'Introduction',
        content: '# Introduction\n\nThis is the introduction.',
        order: 1,
      );
      
      final decision = Decision(
        id: 'ADR-001',
        date: DateTime(2023, 1, 15),
        status: 'Accepted',
        title: 'Use Flutter for frontend',
        content: '# Decision\n\nWe will use Flutter for the frontend.',
      );
      
      final image = Image(
        name: 'architecture.png',
        content: 'base64content',
        type: 'image/png',
      );
      
      final documentation = Documentation(
        sections: [section],
        decisions: [decision],
        images: [image],
      );
      
      final json = documentation.toJson();
      final fromJson = Documentation.fromJson(json);
      
      // Verify sections
      expect(fromJson.sections.length, 1);
      expect(fromJson.sections.first.title, 'Introduction');
      expect(fromJson.sections.first.content, '# Introduction\n\nThis is the introduction.');
      expect(fromJson.sections.first.order, 1);
      
      // Verify decisions
      expect(fromJson.decisions.length, 1);
      expect(fromJson.decisions.first.id, 'ADR-001');
      expect(fromJson.decisions.first.title, 'Use Flutter for frontend');
      
      // Verify images
      expect(fromJson.images.length, 1);
      expect(fromJson.images.first.name, 'architecture.png');
      expect(fromJson.images.first.type, 'image/png');
    });
  });
  
  group('DocumentationSection', () {
    test('creates a DocumentationSection instance', () {
      final section = DocumentationSection(
        title: 'Architecture',
        content: '# Architecture\n\nThis is the architecture overview.',
        order: 2,
      );
      
      expect(section.title, 'Architecture');
      expect(section.content, '# Architecture\n\nThis is the architecture overview.');
      expect(section.order, 2);
      expect(section.format, DocumentationFormat.markdown);
      expect(section.filename, isNull);
      expect(section.elementId, isNull);
    });
    
    test('serializes and deserializes a DocumentationSection instance', () {
      final section = DocumentationSection(
        title: 'API',
        content: '# API Documentation',
        format: DocumentationFormat.asciidoc,
        order: 3,
        filename: 'api.adoc',
        elementId: 'api-1',
      );
      
      final json = section.toJson();
      final fromJson = DocumentationSection.fromJson(json);
      
      expect(fromJson.title, 'API');
      expect(fromJson.content, '# API Documentation');
      expect(fromJson.format, DocumentationFormat.asciidoc);
      expect(fromJson.order, 3);
      expect(fromJson.filename, 'api.adoc');
      expect(fromJson.elementId, 'api-1');
    });
  });
  
  group('Decision', () {
    test('creates a Decision instance', () {
      final date = DateTime(2023, 5, 10);
      final decision = Decision(
        id: 'ADR-002',
        date: date,
        status: 'Proposed',
        title: 'Use Firebase for backend',
        content: '# Decision\n\nWe will use Firebase for the backend.',
      );
      
      expect(decision.id, 'ADR-002');
      expect(decision.date, date);
      expect(decision.status, 'Proposed');
      expect(decision.title, 'Use Firebase for backend');
      expect(decision.content, '# Decision\n\nWe will use Firebase for the backend.');
      expect(decision.format, DocumentationFormat.markdown);
      expect(decision.elementId, isNull);
      expect(decision.links, isEmpty);
    });
    
    test('serializes and deserializes a Decision instance', () {
      final date = DateTime(2023, 6, 15);
      final decision = Decision(
        id: 'ADR-003',
        date: date,
        status: 'Accepted',
        title: 'Database choice',
        content: '# Database Decision',
        format: DocumentationFormat.asciidoc,
        elementId: 'database-1',
        links: ['ADR-001', 'ADR-002'],
      );
      
      final json = decision.toJson();
      final fromJson = Decision.fromJson(json);
      
      expect(fromJson.id, 'ADR-003');
      expect(fromJson.date.year, date.year);
      expect(fromJson.date.month, date.month);
      expect(fromJson.date.day, date.day);
      expect(fromJson.status, 'Accepted');
      expect(fromJson.title, 'Database choice');
      expect(fromJson.content, '# Database Decision');
      expect(fromJson.format, DocumentationFormat.asciidoc);
      expect(fromJson.elementId, 'database-1');
      expect(fromJson.links, ['ADR-001', 'ADR-002']);
    });
  });
  
  group('Image', () {
    test('creates an Image instance', () {
      final image = Image(
        name: 'logo.png',
        content: 'base64encodedcontent',
        type: 'image/png',
      );
      
      expect(image.name, 'logo.png');
      expect(image.content, 'base64encodedcontent');
      expect(image.type, 'image/png');
    });
    
    test('serializes and deserializes an Image instance', () {
      final image = Image(
        name: 'diagram.svg',
        content: 'svgcontent',
        type: 'image/svg+xml',
      );
      
      final json = image.toJson();
      final fromJson = Image.fromJson(json);
      
      expect(fromJson.name, 'diagram.svg');
      expect(fromJson.content, 'svgcontent');
      expect(fromJson.type, 'image/svg+xml');
    });
  });
}