import 'package:flutter_structurizr/domain/model/model.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/style/branding.dart';
import 'package:flutter_structurizr/domain/view/views.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace.freezed.dart';
part 'workspace.g.dart';

/// JsonConverter for Model serialization
class ModelConverter implements JsonConverter<Model, Map<String, dynamic>> {
  const ModelConverter();

  @override
  Model fromJson(Map<String, dynamic> json) => Model.fromJson(json);

  @override
  Map<String, dynamic> toJson(Model model) => model.toJson();
}

/// JsonConverter for Documentation serialization
class DocumentationConverter implements JsonConverter<Documentation, Map<String, dynamic>> {
  const DocumentationConverter();

  @override
  Documentation fromJson(Map<String, dynamic> json) => Documentation.fromJson(json);

  @override
  Map<String, dynamic> toJson(Documentation documentation) => documentation.toJson();
}

/// Represents a Structurizr workspace, which is the top-level container for
/// architecture models, views, documentation, and configuration.
@freezed
class Workspace with _$Workspace {
  const Workspace._();

  /// Creates a new workspace with the given properties.
  const factory Workspace({
    /// The workspace ID in the Structurizr service.
    required int id,

    /// The name of the workspace.
    required String name,

    /// Optional description of the workspace.
    String? description,

    /// Optional version identifier.
    String? version,

    /// The architecture model containing all elements and relationships.
    @ModelConverter() required Model model,

    /// Documentation associated with this workspace.
    @DocumentationConverter() Documentation? documentation,

    /// Views associated with this workspace.
    @Default(Views()) Views views,

    /// Styles for this workspace.
    @Default(Styles()) Styles styles,

    /// Branding for this workspace.
    Branding? branding,

    /// Configuration for this workspace.
    WorkspaceConfiguration? configuration,
  }) = _Workspace;

  /// Creates a workspace from a JSON object.
  factory Workspace.fromJson(Map<String, dynamic> json) => _$WorkspaceFromJson(json);
  
  /// Validates the workspace for consistency.
  /// Returns a list of validation errors, or an empty list if valid.
  List<String> validate() {
    final errors = <String>[];
    
    // Check for required properties
    if (name.isEmpty) {
      errors.add('Workspace name is required');
    }
    
    // Validate the model
    errors.addAll(model.validate());
    
    return errors;
  }
  
  /// Updates the model in this workspace.
  Workspace updateModel(Model updatedModel) {
    return copyWith(model: updatedModel);
  }
}

/// Configuration for a Structurizr workspace.
@freezed
class WorkspaceConfiguration with _$WorkspaceConfiguration {
  const WorkspaceConfiguration._();

  /// Creates a new workspace configuration with the given properties.
  const factory WorkspaceConfiguration({
    /// User-specific settings.
    List<User>? users,
    
    /// Custom properties as key-value pairs.
    @Default({}) Map<String, String> properties,
    
    /// Last modified timestamp.
    DateTime? lastModifiedDate,
    
    /// Last modified user.
    String? lastModifiedUser,
    
    /// Last modified agent.
    String? lastModifiedAgent,
  }) = _WorkspaceConfiguration;

  /// Creates a workspace configuration from a JSON object.
  factory WorkspaceConfiguration.fromJson(Map<String, dynamic> json) => _$WorkspaceConfigurationFromJson(json);
}

/// Represents a user of the workspace.
@freezed
class User with _$User {
  const User._();

  /// Creates a new user with the given properties.
  const factory User({
    /// User's username or ID.
    required String username,
    
    /// User's role in the workspace.
    required String role,
  }) = _User;

  /// Creates a user from a JSON object.
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}