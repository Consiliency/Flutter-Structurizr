## Table 2: **Model Node/Group/Enterprise/Element Foundation**
| Method                                                      | Calls | Example Method Call                                  |
|-------------------------------------------------------------|-------|------------------------------------------------------|
| ModelNode.addGroup(GroupNode): void                         | -     | `modelNode.addGroup(groupNode);`                     |
| ModelNode.addEnterprise(EnterpriseNode): void               | -     | `modelNode.addEnterprise(enterpriseNode);`           |
| ModelNode.addElement(ElementNode): void                     | -     | `modelNode.addElement(elementNode);`                 |
| ModelNode.addRelationship(RelationshipNode): void           | -     | `modelNode.addRelationship(relationshipNode);`       |
| GroupNode.addElement(ElementNode): void                     | -     | `groupNode.addElement(elementNode);`                 |
| EnterpriseNode.addGroup(GroupNode): void                  | -     | `enterpriseNode.addGroup(groupNode);`                |
| ElementNode.addChild(ElementNode): void                     | -     | `elementNode.addChild(childNode);`                   |
| ElementNode.setIdentifier(String): void                     | -     | `elementNode.setIdentifier('user');`                |
| PersonNode.setProperty(String, dynamic): void               | -     | `personNode.setProperty('name', 'User');`             |
| SoftwareSystemNode.setProperty(String, dynamic): void       | -     | `softwareSystemNode.setProperty('description', 'A system');` |
| GroupNode.setProperty(String, dynamic): void                | -     | `groupNode.setProperty('type', 'Internal');`          |
| EnterpriseNode.setProperty(String, dynamic): void           | -     | `enterpriseNode.setProperty('location', 'HQ');`       |
| ModelNode.setAdvancedProperty(String, dynamic): void        | -     | `modelNode.setAdvancedProperty('foo', 42);`         |
| ModelNode.addImpliedRelationship(RelationshipNode): void    | -     | `modelNode.addImpliedRelationship(relNode);`        | 