# Refactored Method Relationship Tables

This document organizes all parsing and model implementation methods into dependency-based tables for parallel developer handoff. Each table contains methods that call each other or are called by each other, and tables are ordered for optimal build order. Each method lists its interface, what it calls, and an example call.

---

## Table 1: **Token/ContextStack/Node Foundation**
| Method | Calls | Example Method Call |
|--------|-------|--------------------|
| ContextStack.push(Context ctx): void | - | `contextStack.push(currentContext);` |
| ContextStack.pop(): Context | - | `var ctx = contextStack.pop();` |
| ContextStack.current(): Context | - | `var ctx = contextStack.current();` |
| ContextStack.clear(): void | - | `contextStack.clear();` |
| ContextStack.size(): int | - | `int n = contextStack.size();` |
| handleError(ParseError err): void | ContextStack.current | `handleError(ParseError('Unexpected token'));` |
| integrateSubmodules(): void | ModelParser.parse, ViewsParser.parse, RelationshipParser.parse, IncludeParser.parse | `integrateSubmodules();` |

---

## Table 2: **Model Node/Group/Enterprise/Element Foundation**
| Method | Calls | Example Method Call |
|--------|-------|--------------------|
| ModelNode.addGroup(GroupNode): void | - | `modelNode.addGroup(groupNode);` |
| ModelNode.addEnterprise(EnterpriseNode): void | - | `modelNode.addEnterprise(enterpriseNode);` |
| ModelNode.addElement(ElementNode): void | - | `modelNode.addElement(elementNode);` |
| ModelNode.addRelationship(RelationshipNode): void | - | `modelNode.addRelationship(relationshipNode);` |
| GroupNode.addElement(ElementNode): void | - | `groupNode.addElement(elementNode);` |
| EnterpriseNode.addGroup(GroupNode): void | - | `enterpriseNode.addGroup(groupNode);` |
| ElementNode.addChild(ElementNode): void | - | `elementNode.addChild(childNode);` |
| ElementNode.setIdentifier(String): void | - | `elementNode.setIdentifier('user');` |
| PersonNode.setProperty(String, dynamic): void | - | `personNode.setProperty('name', 'User');` |
| SoftwareSystemNode.setProperty(String, dynamic): void | - | `softwareSystemNode.setProperty('description', 'A system');` |
| GroupNode.setProperty(String, dynamic): void | - | `groupNode.setProperty('type', 'Internal');` |
| EnterpriseNode.setProperty(String, dynamic): void | - | `enterpriseNode.setProperty('location', 'HQ');` |
| ModelNode.setAdvancedProperty(String, dynamic): void | - | `modelNode.setAdvancedProperty('foo', 42);` |
| ModelNode.addImpliedRelationship(RelationshipNode): void | - | `modelNode.addImpliedRelationship(relNode);` |

---

## Table 3: **IncludeParser Methods**
| Method | Calls | Example Method Call |
|--------|-------|--------------------|
| IncludeParser.parse(List<Token>): List<IncludeNode> | ContextStack.push, ContextStack.pop, _parseFileInclude, _parseViewInclude, _resolveRecursive, _resolveCircular, handleError | `includeParser.parse(tokens);` |
| IncludeParser._parseFileInclude(List<Token>): IncludeNode | IncludeNode.setType | `includeParser._parseFileInclude(tokens);` |
| IncludeParser._parseViewInclude(List<Token>): IncludeNode | IncludeNode.setType | `includeParser._parseViewInclude(tokens);` |
| IncludeParser._resolveRecursive(List<IncludeNode>): void | - | `includeParser._resolveRecursive(includeNodes);` |
| IncludeParser._resolveCircular(List<IncludeNode>): void | - | `includeParser._resolveCircular(includeNodes);` |
| IncludeNode.setType(IncludeType): void | - | `includeNode.setType(IncludeType.file);` |

---

## Table 4: **ElementParser Methods**
| Method | Calls | Example Method Call |
|--------|-------|--------------------|
| ElementParser.parsePerson(List<Token>): PersonNode | ContextStack.push, ContextStack.pop, _parseIdentifier, ElementNode.setIdentifier, PersonNode.setProperty, _parseParentChild, handleError | `elementParser.parsePerson(tokens);` |
| ElementParser.parseSoftwareSystem(List<Token>): SoftwareSystemNode | ContextStack.push, ContextStack.pop, _parseIdentifier, ElementNode.setIdentifier, SoftwareSystemNode.setProperty, _parseParentChild, handleError | `elementParser.parseSoftwareSystem(tokens);` |
| ElementParser._parseIdentifier(List<Token>): String | handleError | `elementParser._parseIdentifier(tokens);` |
| ElementParser._parseParentChild(List<Token>): void | ModelParser._parseNestedElement, RelationshipParser.parse, ElementNode.addChild, ElementNode.setProperty, handleError | `elementParser._parseParentChild(tokens);` |

---

## Table 5: **RelationshipParser Methods**
| Method | Calls | Example Method Call |
|--------|-------|--------------------|
| RelationshipParser.parse(List<Token>): List<RelationshipNode> | ContextStack.push, ContextStack.pop, _parseExplicit, _parseImplicit, _parseGroup, _parseNested, handleError | `relationshipParser.parse(tokens);` |
| RelationshipParser._parseExplicit(List<Token>): RelationshipNode | ElementParser._parseIdentifier, RelationshipNode.setSource, RelationshipNode.setDestination, handleError | `relationshipParser._parseExplicit(tokens);` |
| RelationshipParser._parseImplicit(List<Token>): RelationshipNode | ElementParser._parseIdentifier, RelationshipNode.setSource, RelationshipNode.setDestination, handleError | `relationshipParser._parseImplicit(tokens);` |
| RelationshipParser._parseGroup(List<Token>): void | RelationshipParser.parse, handleError | `relationshipParser._parseGroup(tokens);` |
| RelationshipParser._parseNested(List<Token>): void | RelationshipParser.parse, handleError | `relationshipParser._parseNested(tokens);` |
| RelationshipNode.setSource(String): void | - | `relationshipNode.setSource('user');` |
| RelationshipNode.setDestination(String): void | - | `relationshipNode.setDestination('system');` |

---

## Table 6: **ViewsParser Methods**
| Method | Calls | Example Method Call |
|--------|-------|--------------------|
| ViewsParser.parse(List<Token>): ViewsNode | ContextStack.push, ContextStack.pop, _parseViewBlock, ViewsNode.addView, handleError | `viewsParser.parse(tokens);` |
| ViewsParser._parseViewBlock(List<Token>): ViewNode | ContextStack.push, ContextStack.pop, ElementParser._parseIdentifier, _parseViewProperty, _parseInheritance, _parseIncludeExclude, ViewNode.setProperty, handleError | `viewsParser._parseViewBlock(tokens);` |
| ViewsParser._parseViewProperty(List<Token>): ViewPropertyNode | handleError | `viewsParser._parseViewProperty(tokens);` |
| ViewsParser._parseInheritance(List<Token>): void | ElementParser._parseIdentifier, SystemContextViewNode.setInheritance, handleError | `viewsParser._parseInheritance(tokens);` |
| ViewsParser._parseIncludeExclude(List<Token>): void | ElementParser._parseIdentifier, SystemContextViewNode.setIncludeRule, SystemContextViewNode.setExcludeRule, handleError | `viewsParser._parseIncludeExclude(tokens);` |
| ViewsNode.addView(ViewNode): void | - | `viewsNode.addView(viewNode);` |
| ViewNode.setProperty(ViewPropertyNode): void | - | `viewNode.setProperty(propertyNode);` |

---

## Table 7: **ModelParser Methods**
| Method | Calls | Example Method Call |
|--------|-------|--------------------|
| ModelParser.parse(List<Token>): ModelNode | ContextStack.push, ContextStack.pop, _parseGroup, _parseEnterprise, _parseNestedElement, _parseImpliedRelationship, ModelNode.addGroup, ModelNode.addEnterprise, ModelNode.addElement, handleError | `modelParser.parse(tokens);` |
| ModelParser._parseGroup(List<Token>): GroupNode | ContextStack.push, ContextStack.pop, ElementParser._parseIdentifier, ElementNode.setIdentifier, _parseNestedElement, GroupNode.addElement, GroupNode.setProperty, handleError | `modelParser._parseGroup(tokens);` |
| ModelParser._parseEnterprise(List<Token>): EnterpriseNode | ContextStack.push, ContextStack.pop, ElementParser._parseIdentifier, ElementNode.setIdentifier, _parseGroup, EnterpriseNode.addGroup, EnterpriseNode.setProperty, handleError | `modelParser._parseEnterprise(tokens);` |
| ModelParser._parseNestedElement(List<Token>): ElementNode | ElementParser.parsePerson, ElementParser.parseSoftwareSystem, ModelParser._parseGroup, ModelParser._parseEnterprise, ContextStack.push, ContextStack.pop, handleError | `modelParser._parseNestedElement(tokens);` |
| ModelParser._parseImpliedRelationship(List<Token>): RelationshipNode | RelationshipParser._parseImplicit, ModelNode.addImpliedRelationship, handleError | `modelParser._parseImpliedRelationship(tokens);` |
| ModelNode.addGroup(GroupNode): void | - | `modelNode.addGroup(groupNode);` |
| ModelNode.addEnterprise(EnterpriseNode): void | - | `modelNode.addEnterprise(enterpriseNode);` |
| ModelNode.addElement(ElementNode): void | - | `modelNode.addElement(elementNode);` |

---

## Table 8: **WorkspaceBuilderImpl & SystemContextViewParser Methods**
| Method | Calls | Example Method Call |
|--------|-------|--------------------|
| WorkspaceBuilderImpl.addSystemContextView(SystemContextViewNode): void | SystemContextViewParser.parse, addDefaultElements, addImpliedRelationships, populateDefaults, setDefaultsFromJava | `builder.addSystemContextView(viewNode);` |
| WorkspaceBuilderImpl.addDefaultElements(SystemContextViewNode): void | ViewNode.addElement | `builder.addDefaultElements(viewNode);` |
| WorkspaceBuilderImpl.addImpliedRelationships(): void | ModelNode.addImpliedRelationship | `builder.addImpliedRelationships();` |
| WorkspaceBuilderImpl.populateDefaults(): void | - | `builder.populateDefaults();` |
| WorkspaceBuilderImpl.setDefaultsFromJava(): void | - | `builder.setDefaultsFromJava();` |
| SystemContextViewParser.parse(SystemContextViewNode): SystemContextView | handleIncludeAll, handleIncludeExclude, populateDefaults, setAdvancedFeatures | `parser.parse(viewNode);` |
| SystemContextViewParser.handleIncludeAll(SystemContextViewNode): void | ViewNode.addElement | `parser.handleIncludeAll(viewNode);` |
| SystemContextViewParser.handleIncludeExclude(SystemContextViewNode): void | ViewNode.addElement | `parser.handleIncludeExclude(viewNode);` |
| SystemContextViewParser.populateDefaults(SystemContextViewNode): void | ViewNode.addElement | `parser.populateDefaults(viewNode);` |
| SystemContextViewParser.setAdvancedFeatures(SystemContextViewNode): void | ViewNode.setProperty | `parser.setAdvancedFeatures(viewNode);` |
| SystemContextViewNode.setIncludeRule(IncludeRule): void | - | `viewNode.setIncludeRule(rule);` |
| SystemContextViewNode.setExcludeRule(ExcludeRule): void | - | `viewNode.setExcludeRule(rule);` |
| SystemContextViewNode.setInheritance(ViewNode): void | - | `viewNode.setInheritance(parentView);` |
| ViewNode.addElement(ElementNode): void | - | `viewNode.addElement(elementNode);` |
| ViewNode.setProperty(String, dynamic): void | - | `viewNode.setProperty('theme', 'dark');` |

---

**How to use:**
- Each table can be handed to a separate dev team for parallel implementation.
- Methods in the same table have call dependencies and should be coordinated.
- Build tables in order (Table 1 first, then 2, etc.) for best results. 