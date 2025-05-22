import Foundation
import CloudKit
import AuthenticationServices

@available(iOS 13.0, *)
class CloudStorageService: NSObject {
    private let methodChannel: FlutterMethodChannel
    private var container: CKContainer
    private var database: CKDatabase
    
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        self.container = CKContainer.default()
        self.database = container.privateCloudDatabase
        
        super.init()
        self.methodChannel.setMethodCallHandler(handleMethodCall)
    }
    
    func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            isAvailable(result: result)
        case "authenticate":
            authenticate(call: call, result: result)
        case "isAuthenticated":
            isAuthenticated(result: result)
        case "signOut":
            signOut(result: result)
        case "uploadFile":
            uploadFile(call: call, result: result)
        case "downloadFile":
            downloadFile(call: call, result: result)
        case "getFileInfo":
            getFileInfo(call: call, result: result)
        case "listFiles":
            listFiles(call: call, result: result)
        case "deleteFile":
            deleteFile(call: call, result: result)
        case "getQuotaInfo":
            getQuotaInfo(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func isAvailable(result: @escaping FlutterResult) {
        // Check if CloudKit is available
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    result(true)
                case .noAccount, .restricted, .couldNotDetermine:
                    result(false)
                case .temporarilyUnavailable:
                    result(false)
                @unknown default:
                    result(false)
                }
            }
        }
    }
    
    private func authenticate(call: FlutterMethodCall, result: @escaping FlutterResult) {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    // CloudKit account is available
                    result([
                        "success": true,
                        "accountStatus": "available"
                    ])
                case .noAccount:
                    result([
                        "success": false,
                        "error": "No iCloud account configured",
                        "accountStatus": "noAccount"
                    ])
                case .restricted:
                    result([
                        "success": false,
                        "error": "iCloud account is restricted",
                        "accountStatus": "restricted"
                    ])
                case .couldNotDetermine:
                    result([
                        "success": false,
                        "error": "Could not determine iCloud account status",
                        "accountStatus": "couldNotDetermine"
                    ])
                case .temporarilyUnavailable:
                    result([
                        "success": false,
                        "error": "iCloud is temporarily unavailable",
                        "accountStatus": "temporarilyUnavailable"
                    ])
                @unknown default:
                    result([
                        "success": false,
                        "error": "Unknown account status",
                        "accountStatus": "unknown"
                    ])
                }
            }
        }
    }
    
    private func isAuthenticated(result: @escaping FlutterResult) {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                result(status == .available)
            }
        }
    }
    
    private func signOut(result: @escaping FlutterResult) {
        // CloudKit doesn't have explicit sign out - user manages this in Settings
        result(true)
    }
    
    private func uploadFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let localPath = args["localPath"] as? String,
              let remotePath = args["remotePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let localURL = URL(fileURLWithPath: localPath)
        let fileName = URL(fileURLWithPath: remotePath).lastPathComponent
        
        // Create CKAsset from local file
        guard let asset = CKAsset(fileURL: localURL) else {
            result(FlutterError(code: "FILE_ERROR", message: "Could not create asset from file", details: nil))
            return
        }
        
        // Create CKRecord
        let recordID = CKRecord.ID(recordName: fileName)
        let record = CKRecord(recordType: "WorkspaceFile", recordID: recordID)
        record["fileName"] = fileName as CKRecordValue
        record["fileData"] = asset
        record["uploadDate"] = Date() as CKRecordValue
        
        // Save to CloudKit
        database.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "UPLOAD_ERROR", message: error.localizedDescription, details: nil))
                } else if let savedRecord = savedRecord {
                    result([
                        "success": true,
                        "fileId": savedRecord.recordID.recordName,
                        "uploadDate": ISO8601DateFormatter().string(from: Date())
                    ])
                } else {
                    result(FlutterError(code: "UPLOAD_ERROR", message: "Unknown upload error", details: nil))
                }
            }
        }
    }
    
    private func downloadFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let remotePath = args["remotePath"] as? String,
              let localPath = args["localPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let fileName = URL(fileURLWithPath: remotePath).lastPathComponent
        let recordID = CKRecord.ID(recordName: fileName)
        
        database.fetch(withRecordID: recordID) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "DOWNLOAD_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                
                guard let record = record,
                      let asset = record["fileData"] as? CKAsset,
                      let assetURL = asset.fileURL else {
                    result(FlutterError(code: "DOWNLOAD_ERROR", message: "Could not get file data", details: nil))
                    return
                }
                
                // Copy file to local path
                let localURL = URL(fileURLWithPath: localPath)
                
                do {
                    // Create directory if needed
                    try FileManager.default.createDirectory(at: localURL.deletingLastPathComponent(), 
                                                           withIntermediateDirectories: true, 
                                                           attributes: nil)
                    
                    // Copy file
                    if FileManager.default.fileExists(atPath: localPath) {
                        try FileManager.default.removeItem(at: localURL)
                    }
                    try FileManager.default.copyItem(at: assetURL, to: localURL)
                    
                    result([
                        "success": true,
                        "localPath": localPath
                    ])
                } catch {
                    result(FlutterError(code: "FILE_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    private func getFileInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let remotePath = args["remotePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let fileName = URL(fileURLWithPath: remotePath).lastPathComponent
        let recordID = CKRecord.ID(recordName: fileName)
        
        database.fetch(withRecordID: recordID) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    if let ckError = error as? CKError, ckError.code == .unknownItem {
                        result(nil) // File not found
                    } else {
                        result(FlutterError(code: "FETCH_ERROR", message: error.localizedDescription, details: nil))
                    }
                    return
                }
                
                guard let record = record else {
                    result(nil)
                    return
                }
                
                let fileName = record["fileName"] as? String ?? ""
                let uploadDate = record["uploadDate"] as? Date ?? Date()
                
                // Get file size if possible
                var fileSize: Int64 = 0
                if let asset = record["fileData"] as? CKAsset,
                   let assetURL = asset.fileURL {
                    do {
                        let attributes = try FileManager.default.attributesOfItem(atPath: assetURL.path)
                        fileSize = attributes[.size] as? Int64 ?? 0
                    } catch {
                        // Ignore size error
                    }
                }
                
                result([
                    "id": record.recordID.recordName,
                    "name": fileName,
                    "size": fileSize,
                    "modifiedTime": ISO8601DateFormatter().string(from: uploadDate)
                ])
            }
        }
    }
    
    private func listFiles(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let query = CKQuery(recordType: "WorkspaceFile", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "uploadDate", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "LIST_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                
                let fileInfos = records?.compactMap { record -> [String: Any]? in
                    let fileName = record["fileName"] as? String ?? ""
                    let uploadDate = record["uploadDate"] as? Date ?? Date()
                    
                    var fileSize: Int64 = 0
                    if let asset = record["fileData"] as? CKAsset,
                       let assetURL = asset.fileURL {
                        do {
                            let attributes = try FileManager.default.attributesOfItem(atPath: assetURL.path)
                            fileSize = attributes[.size] as? Int64 ?? 0
                        } catch {
                            // Ignore size error
                        }
                    }
                    
                    return [
                        "id": record.recordID.recordName,
                        "name": fileName,
                        "size": fileSize,
                        "modifiedTime": ISO8601DateFormatter().string(from: uploadDate)
                    ]
                } ?? []
                
                result(fileInfos)
            }
        }
    }
    
    private func deleteFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let remotePath = args["remotePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let fileName = URL(fileURLWithPath: remotePath).lastPathComponent
        let recordID = CKRecord.ID(recordName: fileName)
        
        database.delete(withRecordID: recordID) { deletedRecordID, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "DELETE_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(true)
                }
            }
        }
    }
    
    private func getQuotaInfo(result: @escaping FlutterResult) {
        // CloudKit doesn't provide direct quota information
        // This is a simplified implementation
        result([
            "totalBytes": 1073741824, // 1GB default
            "usedBytes": 0,
            "availableBytes": 1073741824
        ])
    }
}