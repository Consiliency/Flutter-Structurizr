## Table 6: **ViewsParser Methods**
| Method                                         | Calls                                                                                           | Example Method Call                                  |
|------------------------------------------------|-------------------------------------------------------------------------------------------------|------------------------------------------------------|
| ViewsParser.parse(List<Token>): ViewsNode       | ContextStack.push, ContextStack.pop, _parseViewBlock, ViewsNode.addView, handleError            | `viewsParser.parse(tokens);`                         |
| ViewsParser._parseViewBlock(List<Token>): ViewNode | ContextStack.push, ContextStack.pop, ElementParser._parseIdentifier, _parseViewProperty, _parseInheritance, _parseIncludeExclude, ViewNode.setProperty, handleError | `viewsParser._parseViewBlock(tokens);`              |
| ViewsParser._parseViewProperty(List<Token>): ViewPropertyNode | handleError | `viewsParser._parseViewProperty(tokens);`           |
| ViewsParser._parseInheritance(List<Token>): void | ElementParser._parseIdentifier, SystemContextViewNode.setInheritance, handleError               | `viewsParser._parseInheritance(tokens);`            |
| ViewsParser._parseIncludeExclude(List<Token>): void | ElementParser._parseIdentifier, SystemContextViewNode.setIncludeRule, SystemContextViewNode.setExcludeRule, handleError | `viewsParser._parseIncludeExclude(tokens);`        |
| ViewsParser._parseTags(List<Token>): TagsNode | handleError | `viewsParser._parseTags(tokens);`           |
| ViewsNode.addView(ViewNode): void               | -                                                                                               | `viewsNode.addView(viewNode);`                       |
| ViewNode.setProperty(ViewPropertyNode): void    | -                                                                                               | `viewNode.setProperty(propertyNode);`                |

# 2024-06 Update: ViewsParser Methods
- All ViewsParser methods now use explicit imports and type aliasing to avoid conflicts with Flutter built-ins.
- Recent batch fixes resolved ambiguous imports and type mismatches in view-related files.
- See implementation_status.md for current completion status. 