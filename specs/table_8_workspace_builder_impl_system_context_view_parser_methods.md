## Table 8: **WorkspaceBuilderImpl & SystemContextViewParser Methods**
| Method                                         | Calls                                                                                           | Example Method Call                                  |
|------------------------------------------------|-------------------------------------------------------------------------------------------------|------------------------------------------------------|
| WorkspaceBuilderImpl.addSystemContextView(SystemContextViewNode): void | SystemContextViewParser.parse, addDefaultElements, addImpliedRelationships, populateDefaults, setDefaultsFromJava | `builder.addSystemContextView(viewNode);`           |
| WorkspaceBuilderImpl.addDefaultElements(SystemContextViewNode): void | ViewNode.addElement                                                                             | `builder.addDefaultElements(viewNode);`             |
| WorkspaceBuilderImpl.addImpliedRelationships(): void | ModelNode.addImpliedRelationship                                                                | `builder.addImpliedRelationships();`                |
| WorkspaceBuilderImpl.populateDefaults(): void   | -                                                                                               | `builder.populateDefaults();`                        |
| WorkspaceBuilderImpl.setDefaultsFromJava(): void | -                                                                                               | `builder.setDefaultsFromJava();`                     |
| SystemContextViewParser.parse(SystemContextViewNode): SystemContextView | handleIncludeAll, handleIncludeExclude, populateDefaults, setAdvancedFeatures                 | `parser.parse(viewNode);`                            |
| SystemContextViewParser.handleIncludeAll(SystemContextViewNode): void | ViewNode.addElement                                                                             | `parser.handleIncludeAll(viewNode);`                 |
| SystemContextViewParser.handleIncludeExclude(SystemContextViewNode): void | ViewNode.addElement                                                                             | `parser.handleIncludeExclude(viewNode);`             |
| SystemContextViewParser.populateDefaults(SystemContextViewNode): void | ViewNode.addElement                                                                             | `parser.populateDefaults(viewNode);`                 |
| SystemContextViewParser.setAdvancedFeatures(SystemContextViewNode): void | ViewNode.setProperty                                                                            | `parser.setAdvancedFeatures(viewNode);`              |
| SystemContextViewNode.setIncludeRule(IncludeRule): void | -                                                                                               | `viewNode.setIncludeRule(rule);`                     |
| SystemContextViewNode.setExcludeRule(ExcludeRule): void | -                                                                                               | `viewNode.setExcludeRule(rule);`                     |
| SystemContextViewNode.setInheritance(ViewNode): void | -                                                                                               | `viewNode.setInheritance(parentView);`               |
| ViewNode.addElement(ElementNode): void          | -                                                                                               | `viewNode.addElement(elementNode);`                  |
| ViewNode.setProperty(String, dynamic): void     | -                                                                                               | `viewNode.setProperty('theme', 'dark');`             |

# 2024-06 Update: WorkspaceBuilderImpl & SystemContextViewParser Methods
- Batch fixes have resolved ambiguous imports and type mismatches in workspace builder and view parser files.
- All new code should use explicit imports and type aliasing to avoid conflicts with Flutter built-ins.
- See implementation_status.md for current completion status and next steps. 