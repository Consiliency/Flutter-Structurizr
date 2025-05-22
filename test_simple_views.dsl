workspace {
    name "Test Workspace"
    description "A simple test workspace with views"

    model {
        user = person "User" "A user of the system"
        system = softwareSystem "Test System" "A test system"
        
        user -> system "Uses"
    }

    views {
        systemcontext system "SystemContext" {
            include *
            description "The system context diagram"
        }
    }
}