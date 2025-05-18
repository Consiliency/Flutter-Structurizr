import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/style/branding.dart';

void main() {
  group('Branding', () {
    test('creates branding with default values', () {
      const branding = Branding();

      expect(branding.logo, isNull);
      expect(branding.fonts, isEmpty);
    });

    test('creates branding with all properties', () {
      const font = Font(
        name: 'Open Sans',
        url: 'https://fonts.googleapis.com/css?family=Open+Sans',
      );

      const branding = Branding(
        logo: 'logo.png',
        fonts: [font],
      );

      expect(branding.logo, equals('logo.png'));
      expect(branding.fonts, hasLength(1));
      expect(branding.fonts[0].name, equals('Open Sans'));
    });

    test('adds font', () {
      const branding = Branding();

      const font = Font(
        name: 'Open Sans',
        url: 'https://fonts.googleapis.com/css?family=Open+Sans',
      );

      final updatedBranding = branding.addFont(font);

      expect(updatedBranding.fonts, hasLength(1));
      expect(updatedBranding.fonts[0], equals(font));
    });
  });

  group('Font', () {
    test('creates font with required properties', () {
      const font = Font(
        name: 'Open Sans',
        url: 'https://fonts.googleapis.com/css?family=Open+Sans',
      );

      expect(font.name, equals('Open Sans'));
      expect(font.url,
          equals('https://fonts.googleapis.com/css?family=Open+Sans'));
    });
  });
}
