workspace "Big Bank Test" {
    name "Big Bank plc - Internet Banking System"
    description "The software architecture of the Big Bank plc Internet Banking System."

    model {
        customer = person "Customer" "A customer of the bank"
        internetBankingSystem = softwareSystem "Internet Banking System" "Allows customers to view information about their bank accounts" {
            singlePageApplication = container "Single-Page Application" "Provides all of the Internet banking functionality to customers via their web browser." "JavaScript and Angular"
            mobileApp = container "Mobile App" "Provides a limited subset of the Internet banking functionality to customers via their mobile device." "Xamarin"
            webApplication = container "Web Application" "Delivers the static content and the Internet banking single page application." "Java and Spring MVC"
            apiApplication = container "API Application" "Provides Internet banking functionality via a JSON/HTTPS API." "Java and Spring MVC"
            database = container "Database" "Stores user registration information, hashed authentication credentials, access logs, etc." "Oracle Database Schema"
        }
        mainframe = softwareSystem "Mainframe Banking System" "Stores all of the core banking information about customers, accounts, transactions, etc." "Existing System"
        email = softwareSystem "E-mail System" "The internal Microsoft Exchange e-mail system." "Existing System"

        customer -> internetBankingSystem "Views account balances, and makes payments using"
        internetBankingSystem -> mainframe "Gets account information from, and makes payments using" "XML/HTTPS"
        internetBankingSystem -> email "Sends e-mail using" "SMTP"
        customer -> webApplication "Visits bigbank.com/ib using" "HTTPS"
        customer -> singlePageApplication "Views account balances, and makes payments using"
        customer -> mobileApp "Views account balances, and makes payments using"
        webApplication -> singlePageApplication "Delivers to the customer's web browser"
    }

    views {
        systemcontext internetBankingSystem "SystemContext" {
            include *
            description "The system context diagram for the Internet Banking System."
        }

        container internetBankingSystem "Containers" {
            include *
            description "The container diagram for the Internet Banking System."
        }
    }
}