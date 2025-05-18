## Table 1: **Token/ContextStack/Node Foundation**
| Method                                    | Calls                | Example Method Call                                 |
|--------------------------------------------|----------------------|-----------------------------------------------------|
| ContextStack.push(Context ctx): void       | -                    | `contextStack.push(currentContext);`                |
| ContextStack.pop(): Context                | -                    | `var ctx = contextStack.pop();`                     |
| ContextStack.current(): Context            | -                    | `var ctx = contextStack.current();`                 |
| ContextStack.clear(): void                 | -                    | `contextStack.clear();`                             |
| ContextStack.size(): int                   | -                    | `int n = contextStack.size();`                      |
| handleError(String, SourcePosition?): void | ContextStack.current | `handleError("Unexpected token", position);`        |
| integrateSubmodules(): void                                 | ModelParser.parse, ViewsParser.parse, RelationshipParser.parse, IncludeParser.parse             | `integrateSubmodules();`                             | 