import 'package:flutter_structurizr/domain/model/deployment_node.dart';
import 'package:flutter_structurizr/domain/model/container_instance.dart';
import 'package:flutter_structurizr/domain/model/software_system_instance.dart';
import 'package:flutter_structurizr/domain/model/infrastructure_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeploymentNode tests', () {
    late DeploymentNode deploymentNode;
    const nodeId = 'node-1';
    const nodeName = 'Amazon Web Services';
    const nodeDescription = 'AWS us-east-1';
    const nodeTechnology = 'Amazon Web Services';
    const nodeEnvironment = 'Production';

    setUp(() {
      deploymentNode = const DeploymentNode(
        id: nodeId,
        name: nodeName,
        description: nodeDescription,
        technology: nodeTechnology,
        environment: nodeEnvironment,
        instances: 1,
      );
    });

    test('DeploymentNode creation with ID', () {
      expect(deploymentNode.id, equals(nodeId));
      expect(deploymentNode.name, equals(nodeName));
      expect(deploymentNode.description, equals(nodeDescription));
      expect(deploymentNode.technology, equals(nodeTechnology));
      expect(deploymentNode.environment, equals(nodeEnvironment));
      expect(deploymentNode.instances, equals(1));
      expect(deploymentNode.type, equals('DeploymentNode'));
      expect(deploymentNode.tags, isEmpty);
      expect(deploymentNode.properties, isEmpty);
      expect(deploymentNode.relationships, isEmpty);
      expect(deploymentNode.children, isEmpty);
      expect(deploymentNode.containerInstances, isEmpty);
      expect(deploymentNode.softwareSystemInstances, isEmpty);
      expect(deploymentNode.infrastructureNodes, isEmpty);
    });

    test('DeploymentNode.create() factory generates UUID', () {
      final createdNode = DeploymentNode.create(
        name: nodeName,
        environment: nodeEnvironment,
        description: nodeDescription,
        technology: nodeTechnology,
        instances: 1,
      );

      expect(createdNode.id, isNotNull);
      expect(createdNode.id.length, greaterThan(0));
      expect(createdNode.name, equals(nodeName));
      expect(createdNode.description, equals(nodeDescription));
      expect(createdNode.technology, equals(nodeTechnology));
      expect(createdNode.environment, equals(nodeEnvironment));
      expect(createdNode.instances, equals(1));
      expect(
          createdNode.tags, contains('DeploymentNode')); // Default tag is added
    });

    test('addChildNode() adds a child deployment node', () {
      const childNode = DeploymentNode(
        id: 'child-node-1',
        name: 'EC2',
        environment: nodeEnvironment,
        technology: 'Amazon EC2',
        parentId: nodeId,
      );

      final updatedNode = deploymentNode.addChildNode(childNode);

      expect(updatedNode.children.length, equals(1));
      expect(updatedNode.children.first.id, equals(childNode.id));
      expect(updatedNode.children.first.name, equals(childNode.name));
      expect(updatedNode.children.first.parentId, equals(nodeId));

      // Original node should be unchanged (immutability test)
      expect(deploymentNode.children.length, equals(0));
    });

    test('addContainerInstance() adds a container instance', () {
      const containerInstance = ContainerInstance(
        id: 'container-instance-1',
        containerId: 'container-1',
        parentId: nodeId,
        instanceId: 1,
      );

      final updatedNode =
          deploymentNode.addContainerInstance(containerInstance);

      expect(updatedNode.containerInstances.length, equals(1));
      expect(updatedNode.containerInstances.first.id,
          equals(containerInstance.id));
      expect(updatedNode.containerInstances.first.containerId,
          equals('container-1'));

      // Original node should be unchanged (immutability test)
      expect(deploymentNode.containerInstances.length, equals(0));
    });

    test('addSoftwareSystemInstance() adds a software system instance', () {
      const systemInstance = SoftwareSystemInstance(
        id: 'system-instance-1',
        softwareSystemId: 'system-1',
        parentId: nodeId,
        instanceId: 1,
      );

      final updatedNode =
          deploymentNode.addSoftwareSystemInstance(systemInstance);

      expect(updatedNode.softwareSystemInstances.length, equals(1));
      expect(updatedNode.softwareSystemInstances.first.id,
          equals(systemInstance.id));
      expect(updatedNode.softwareSystemInstances.first.softwareSystemId,
          equals('system-1'));
    });

    test('addInfrastructureNode() adds an infrastructure node', () {
      const infraNode = InfrastructureNode(
        id: 'infra-1',
        name: 'Load Balancer',
        technology: 'Amazon ELB',
        parentId: nodeId,
      );

      final updatedNode = deploymentNode.addInfrastructureNode(infraNode);

      expect(updatedNode.infrastructureNodes.length, equals(1));
      expect(updatedNode.infrastructureNodes.first.id, equals(infraNode.id));
      expect(
          updatedNode.infrastructureNodes.first.name, equals(infraNode.name));
    });

    test('Nested child nodes are handled properly', () {
      const childNode1 = DeploymentNode(
        id: 'child-1',
        name: 'VPC',
        environment: nodeEnvironment,
        parentId: nodeId,
      );

      const childNode2 = DeploymentNode(
        id: 'child-2',
        name: 'Subnet',
        environment: nodeEnvironment,
        parentId: 'child-1',
      );

      // Add first level child
      final nodeWithChild = deploymentNode.addChildNode(childNode1);

      // Add second level child to first child
      final childWithGrandchild = childNode1.addChildNode(childNode2);

      // Update first level child with its updated version
      final nodeWithGrandchild =
          nodeWithChild.copyWith(children: [childWithGrandchild]);

      // Check hierarchy
      expect(nodeWithGrandchild.children.length, equals(1));
      expect(nodeWithGrandchild.children.first.children.length, equals(1));
      expect(nodeWithGrandchild.children.first.children.first.id,
          equals('child-2'));
    });
  });

  group('InfrastructureNode tests', () {
    late InfrastructureNode infraNode;
    const nodeId = 'infra-1';
    const nodeName = 'Load Balancer';
    const nodeDescription = 'Handles load balancing';
    const nodeTechnology = 'Amazon ELB';
    const parentId = 'node-1';

    setUp(() {
      infraNode = const InfrastructureNode(
        id: nodeId,
        name: nodeName,
        description: nodeDescription,
        technology: nodeTechnology,
        parentId: parentId,
      );
    });

    test('InfrastructureNode creation with ID', () {
      expect(infraNode.id, equals(nodeId));
      expect(infraNode.name, equals(nodeName));
      expect(infraNode.description, equals(nodeDescription));
      expect(infraNode.technology, equals(nodeTechnology));
      expect(infraNode.parentId, equals(parentId));
      expect(infraNode.type, equals('InfrastructureNode'));
      expect(infraNode.tags, isEmpty);
      expect(infraNode.properties, isEmpty);
      expect(infraNode.relationships, isEmpty);
    });

    test('InfrastructureNode.create() factory generates UUID', () {
      final createdNode = InfrastructureNode.create(
        name: nodeName,
        parentId: parentId,
        description: nodeDescription,
        technology: nodeTechnology,
      );

      expect(createdNode.id, isNotNull);
      expect(createdNode.id.length, greaterThan(0));
      expect(createdNode.name, equals(nodeName));
      expect(createdNode.description, equals(nodeDescription));
      expect(createdNode.technology, equals(nodeTechnology));
      expect(createdNode.parentId, equals(parentId));
      expect(createdNode.tags,
          contains('InfrastructureNode')); // Default tag is added
    });

    test('addRelationship() adds a relationship from the infrastructure node',
        () {
      final updatedNode = infraNode.addRelationship(
        destinationId: 'container-instance-1',
        description: 'Forwards requests to',
        technology: 'HTTPS',
      );

      expect(updatedNode.relationships.length, equals(1));
      expect(updatedNode.relationships.first.sourceId, equals(nodeId));
      expect(updatedNode.relationships.first.destinationId,
          equals('container-instance-1'));
      expect(updatedNode.relationships.first.description,
          equals('Forwards requests to'));
      expect(updatedNode.relationships.first.technology, equals('HTTPS'));
    });
  });

  group('ContainerInstance tests', () {
    late ContainerInstance containerInstance;
    const instanceId = 'instance-1';
    const containerId = 'container-1';
    const parentId = 'node-1';
    const instanceNumber = 1;
    const healthEndpoint = '/health';

    setUp(() {
      containerInstance = const ContainerInstance(
        id: instanceId,
        containerId: containerId,
        parentId: parentId,
        instanceId: instanceNumber,
        healthEndpoint: healthEndpoint,
      );
    });

    test('ContainerInstance creation with ID', () {
      expect(containerInstance.id, equals(instanceId));
      expect(containerInstance.containerId, equals(containerId));
      expect(containerInstance.parentId, equals(parentId));
      expect(containerInstance.instanceId, equals(instanceNumber));
      expect(containerInstance.healthEndpoint, equals(healthEndpoint));
      expect(containerInstance.type, equals('ContainerInstance'));
      expect(containerInstance.tags, isEmpty);
      expect(containerInstance.properties, isEmpty);
      expect(containerInstance.relationships, isEmpty);

      // ContainerInstance has default name/description getters
      expect(containerInstance.name, equals('Container Instance'));
      expect(containerInstance.description, isNull);
    });

    test('ContainerInstance.create() factory generates UUID', () {
      final createdInstance = ContainerInstance.create(
        containerId: containerId,
        parentId: parentId,
        instanceId: instanceNumber,
        healthEndpoint: healthEndpoint,
      );

      expect(createdInstance.id, isNotNull);
      expect(createdInstance.id.length, greaterThan(0));
      expect(createdInstance.containerId, equals(containerId));
      expect(createdInstance.parentId, equals(parentId));
      expect(createdInstance.instanceId, equals(instanceNumber));
      expect(createdInstance.healthEndpoint, equals(healthEndpoint));
      expect(createdInstance.tags,
          contains('ContainerInstance')); // Default tag is added
    });

    test('addRelationship() adds a relationship from the container instance',
        () {
      final updatedInstance = containerInstance.addRelationship(
        destinationId: 'database-1',
        description: 'Reads from and writes to',
        technology: 'JDBC',
      );

      expect(updatedInstance.relationships.length, equals(1));
      expect(updatedInstance.relationships.first.sourceId, equals(instanceId));
      expect(updatedInstance.relationships.first.destinationId,
          equals('database-1'));
      expect(updatedInstance.relationships.first.description,
          equals('Reads from and writes to'));
      expect(updatedInstance.relationships.first.technology, equals('JDBC'));
    });
  });

  group('SoftwareSystemInstance tests', () {
    late SoftwareSystemInstance systemInstance;
    const instanceId = 'instance-1';
    const systemId = 'system-1';
    const parentId = 'node-1';
    const instanceNumber = 1;
    const healthEndpoint = '/health';

    setUp(() {
      systemInstance = const SoftwareSystemInstance(
        id: instanceId,
        softwareSystemId: systemId,
        parentId: parentId,
        instanceId: instanceNumber,
        healthEndpoint: healthEndpoint,
      );
    });

    test('SoftwareSystemInstance creation with ID', () {
      expect(systemInstance.id, equals(instanceId));
      expect(systemInstance.softwareSystemId, equals(systemId));
      expect(systemInstance.parentId, equals(parentId));
      expect(systemInstance.instanceId, equals(instanceNumber));
      expect(systemInstance.healthEndpoint, equals(healthEndpoint));
      expect(systemInstance.type, equals('SoftwareSystemInstance'));
      expect(systemInstance.tags, isEmpty);
      expect(systemInstance.properties, isEmpty);
      expect(systemInstance.relationships, isEmpty);

      // SoftwareSystemInstance has default name/description getters
      expect(systemInstance.name, equals('Software System Instance'));
      expect(systemInstance.description, isNull);
    });

    test('SoftwareSystemInstance.create() factory generates UUID', () {
      final createdInstance = SoftwareSystemInstance.create(
        softwareSystemId: systemId,
        parentId: parentId,
        instanceId: instanceNumber,
        healthEndpoint: healthEndpoint,
      );

      expect(createdInstance.id, isNotNull);
      expect(createdInstance.id.length, greaterThan(0));
      expect(createdInstance.softwareSystemId, equals(systemId));
      expect(createdInstance.parentId, equals(parentId));
      expect(createdInstance.instanceId, equals(instanceNumber));
      expect(createdInstance.healthEndpoint, equals(healthEndpoint));
      expect(createdInstance.tags,
          contains('SoftwareSystemInstance')); // Default tag is added
    });

    test(
        'addRelationship() adds a relationship from the software system instance',
        () {
      final updatedInstance = systemInstance.addRelationship(
        destinationId: 'other-system-1',
        description: 'Sends data to',
        technology: 'HTTP/JSON',
      );

      expect(updatedInstance.relationships.length, equals(1));
      expect(updatedInstance.relationships.first.sourceId, equals(instanceId));
      expect(updatedInstance.relationships.first.destinationId,
          equals('other-system-1'));
      expect(updatedInstance.relationships.first.description,
          equals('Sends data to'));
      expect(
          updatedInstance.relationships.first.technology, equals('HTTP/JSON'));
    });
  });
}
