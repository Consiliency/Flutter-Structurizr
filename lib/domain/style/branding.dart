import 'package:freezed_annotation/freezed_annotation.dart';

part 'branding.freezed.dart';
part 'branding.g.dart';

/// Represents branding information for a workspace.
@freezed
class Branding with _$Branding {
  const Branding._();

  /// Creates a new branding with the given properties.
  const factory Branding({
    /// Logo URL or data URI.
    String? logo,
    
    /// Font information.
    @Default([]) List<Font> fonts,
  }) = _Branding;

  /// Creates branding from a JSON object.
  factory Branding.fromJson(Map<String, dynamic> json) => _$BrandingFromJson(json);

  /// Adds a font to this branding.
  Branding addFont(Font font) {
    return copyWith(fonts: [...fonts, font]);
  }
}

/// Represents a font for branding.
@freezed
class Font with _$Font {
  const Font._();

  /// Creates a new font with the given properties.
  const factory Font({
    /// Font name.
    required String name,
    
    /// Font URL.
    required String url,
  }) = _Font;

  /// Creates a font from a JSON object.
  factory Font.fromJson(Map<String, dynamic> json) => _$FontFromJson(json);
}