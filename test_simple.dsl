workspace "Test" {
    model {
        user = person "User"
        system = softwareSystem "System"
        user -> system "uses"
    }
    
    views {
        systemContext system "Context" {
            include *
        }
    }
}