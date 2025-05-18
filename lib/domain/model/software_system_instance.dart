import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_structurizr/domain/model/element.dart'
    show Element, Relationship, ElementListConverter;

part 'software_system_instance.freezed.dart';
part 'software_system_instance.g.dart';

@freezed
class SoftwareSystemInstance with _$SoftwareSystemInstance implements Element {
  const SoftwareSystemInstance._();

  const factory SoftwareSystemInstance({
    required String id,
    required String softwareSystemId,
    required String name,
    String? description,
    @Default('SoftwareSystemInstance') String type,
    @Default([]) List<String> tags,
    @Default({}) Map<String, String> properties,
    @Default([]) List<Relationship> relationships,
    String? parentId,
    @ElementListConverter() @Default([]) List<Element> children,
  }) = _SoftwareSystemInstance;

  factory SoftwareSystemInstance.fromJson(Map<String, dynamic> json) =>
      _$SoftwareSystemInstanceFromJson(json);

  @override
  SoftwareSystemInstance addTag(String tag) => this;
  @override
  SoftwareSystemInstance addTags(List<String> newTags) => this;
  @override
  SoftwareSystemInstance addProperty(String key, String value) => this;
  @override
  SoftwareSystemInstance addRelationship({
    required String destinationId,
    required String description,
    String? technology,
    List<String> tags = const [],
    Map<String, String> properties = const {},
  }) =>
      this;
  @override
  Relationship? getRelationshipById(String relationshipId) => null;
  @override
  List<Relationship> getRelationshipsTo(String destinationId) => const [];
  @override
  SoftwareSystemInstance addChild(Element childNode) => this;
  @override
  SoftwareSystemInstance setIdentifier(String identifier) => this;
}
