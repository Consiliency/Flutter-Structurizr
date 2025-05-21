workspace {
    model {
        softwareSystem = softwareSystem "Software System"
        user = person "User"
        user -> softwareSystem "Uses"
    }
    views {
        systemContext softwareSystem {
            include *
            autolayout lr
        }
        theme default
    }
}
