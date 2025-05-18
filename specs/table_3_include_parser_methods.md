## Table 3: **IncludeParser Methods**
| Method                                         | Calls                                                                                           | Example Method Call                                  |
|------------------------------------------------|-------------------------------------------------------------------------------------------------|------------------------------------------------------|
| IncludeParser.parse(List<Token>): List<IncludeNode> | ContextStack.push, ContextStack.pop, _parseFileInclude, _parseViewInclude, _parseExclude, _resolveRecursive, _resolveCircular, handleError | `includeParser.parse(tokens);`                       |
| IncludeParser._parseFileInclude(List<Token>): IncludeNode | IncludeNode.setType                                                                             | `includeParser._parseFileInclude(tokens);`           |
| IncludeParser._parseViewInclude(List<Token>): IncludeNode | IncludeNode.setType                                                                             | `includeParser._parseViewInclude(tokens);`           |
| IncludeParser._parseExclude(List<Token>): ExcludeNode | ExcludeNode.setType                                                                             | `includeParser._parseExclude(tokens);`           |
| IncludeParser._resolveRecursive(List<IncludeNode>): void | -                                                                                               | `includeParser._resolveRecursive(includeNodes);`      |
| IncludeParser._resolveCircular(List<IncludeNode>): void  | -                                                                                               | `includeParser._resolveCircular(includeNodes);`       |
| IncludeNode.setType(IncludeType): void                  | -                                                                                               | `includeNode.setType(IncludeType.file);`              |

# 2024-06 Update: IncludeParser Methods
- All IncludeParser methods now use explicit imports and type aliasing to avoid conflicts with Flutter built-ins.
- Recent batch fixes resolved ambiguous imports and type mismatches in include-related files.
- See implementation_status.md for current completion status. 