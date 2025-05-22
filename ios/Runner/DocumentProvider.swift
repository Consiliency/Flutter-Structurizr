import Foundation
import UIKit

@available(iOS 11.0, *)
class StructurizrDocumentProvider: NSObject {
    static let shared = StructurizrDocumentProvider()
    
    private var securityScopedResources: [String: URL] = [:]
    private var activeBookmarks: [String] = []
    
    override init() {
        super.init()
        configureDocumentProvider()
    }
    
    private func configureDocumentProvider() {
        // Configure document types and provider settings
        let documentTypes = [
            "public.json",
            "public.plain-text",
            "com.structurizr.dsl",
            "com.structurizr.workspace"
        ]
        
        // Set up document provider capabilities
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(documentProviderDidBecomeActive),
            name: .NSExtensionHostDidBecomeActive,
            object: nil
        )
    }
    
    @objc private func documentProviderDidBecomeActive() {
        // Handle document provider activation
        print("Structurizr Document Provider became active")
    }
    
    // MARK: - Security-Scoped Bookmarks
    
    func createBookmark(for url: URL) -> String? {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security-scoped resource")
            return nil
        }
        
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            let bookmarkString = bookmarkData.base64EncodedString()
            activeBookmarks.append(bookmarkString)
            
            return bookmarkString
        } catch {
            print("Error creating bookmark: \\(error)")
            url.stopAccessingSecurityScopedResource()
            return nil
        }
    }
    
    func resolveBookmark(_ bookmarkString: String) -> URL? {
        guard let bookmarkData = Data(base64Encoded: bookmarkString) else {
            return nil
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("Bookmark is stale, may need to recreate")
            }
            
            return url
        } catch {
            print("Error resolving bookmark: \\(error)")
            return nil
        }
    }
    
    func startAccessingResource(bookmarkString: String) -> Bool {
        guard let url = resolveBookmark(bookmarkString) else {
            return false
        }
        
        let success = url.startAccessingSecurityScopedResource()
        if success {
            securityScopedResources[bookmarkString] = url
        }
        
        return success
    }
    
    func stopAccessingResource(bookmarkString: String) -> Bool {
        guard let url = securityScopedResources[bookmarkString] else {
            return false
        }
        
        url.stopAccessingSecurityScopedResource()
        securityScopedResources.removeValue(forKey: bookmarkString)
        
        return true
    }
    
    // MARK: - Directory Access
    
    func enableFilesAccess(for directory: String) -> Bool {
        guard let url = URL(string: directory) else {
            return false
        }
        
        // Check if directory is accessible
        guard url.startAccessingSecurityScopedResource() else {
            return false
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Create bookmark for persistent access
        _ = createBookmark(for: url)
        
        return true
    }
    
    func isDirectoryAccessible(_ directory: String) -> Bool {
        guard let url = URL(string: directory) else {
            return false
        }
        
        let accessible = url.startAccessingSecurityScopedResource()
        if accessible {
            url.stopAccessingSecurityScopedResource()
        }
        
        return accessible
    }
    
    // MARK: - Document Provider Interface
    
    func provideDocument(at url: URL, completionHandler: @escaping (URL?, Error?) -> Void) {
        // Provide document to Files app
        guard url.startAccessingSecurityScopedResource() else {
            completionHandler(nil, DocumentProviderError.accessDenied)
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Copy document to temporary location for Files app
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            
            try FileManager.default.copyItem(at: url, to: tempURL)
            completionHandler(tempURL, nil)
        } catch {
            completionHandler(nil, error)
        }
    }
    
    func documentChanged(at url: URL) {
        // Handle document changes
        NotificationCenter.default.post(
            name: .documentDidChange,
            object: self,
            userInfo: ["url": url]
        )
    }
    
    // MARK: - Capabilities
    
    func getCapabilities() -> [String: Bool] {
        return [
            "documentProvider": true,
            "fileCoordination": true,
            "securityScopedBookmarks": true,
            "directoryAccess": true
        ]
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Stop accessing all security-scoped resources
        for (bookmarkString, url) in securityScopedResources {
            url.stopAccessingSecurityScopedResource()
        }
        securityScopedResources.removeAll()
        
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Error Types

enum DocumentProviderError: Error {
    case accessDenied
    case fileNotFound
    case copyFailed
    case bookmarkStale
    
    var localizedDescription: String {
        switch self {
        case .accessDenied:
            return "Access to the document was denied"
        case .fileNotFound:
            return "The requested file was not found"
        case .copyFailed:
            return "Failed to copy the document"
        case .bookmarkStale:
            return "The bookmark is stale and needs to be recreated"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let documentDidChange = Notification.Name("StructurizrDocumentDidChange")
}

// MARK: - Flutter Method Channel Integration

@available(iOS 11.0, *)
class StructurizrIOSFilesMethodChannel: NSObject {
    static let shared = StructurizrIOSFilesMethodChannel()
    private let documentProvider = StructurizrDocumentProvider.shared
    
    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enableFilesAccess":
            handleEnableFilesAccess(call, result: result)
        case "disableFilesAccess":
            handleDisableFilesAccess(call, result: result)
        case "isDirectoryAccessible":
            handleIsDirectoryAccessible(call, result: result)
        case "createBookmark":
            handleCreateBookmark(call, result: result)
        case "resolveBookmark":
            handleResolveBookmark(call, result: result)
        case "startAccessingResource":
            handleStartAccessingResource(call, result: result)
        case "stopAccessingResource":
            handleStopAccessingResource(call, result: result)
        case "getCapabilities":
            handleGetCapabilities(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleEnableFilesAccess(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let directory = args["directory"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let success = documentProvider.enableFilesAccess(for: directory)
        result(success)
    }
    
    private func handleDisableFilesAccess(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Implement disable logic if needed
        result(true)
    }
    
    private func handleIsDirectoryAccessible(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let directory = args["directory"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let accessible = documentProvider.isDirectoryAccessible(directory)
        result(accessible)
    }
    
    private func handleCreateBookmark(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String,
              let url = URL(string: filePath) else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let bookmark = documentProvider.createBookmark(for: url)
        result(bookmark)
    }
    
    private func handleResolveBookmark(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let bookmarkData = args["bookmarkData"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let url = documentProvider.resolveBookmark(bookmarkData)
        result(url?.absoluteString)
    }
    
    private func handleStartAccessingResource(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let bookmarkData = args["bookmarkData"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let success = documentProvider.startAccessingResource(bookmarkString: bookmarkData)
        result(success)
    }
    
    private func handleStopAccessingResource(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let bookmarkData = args["bookmarkData"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let success = documentProvider.stopAccessingResource(bookmarkString: bookmarkData)
        result(success)
    }
    
    private func handleGetCapabilities(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let capabilities = documentProvider.getCapabilities()
        result(capabilities)
    }
}