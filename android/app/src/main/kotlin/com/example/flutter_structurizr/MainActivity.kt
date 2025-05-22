package com.example.flutter_structurizr

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.app.Activity
import android.content.ContentResolver
import android.database.Cursor
import android.provider.OpenableColumns
import androidx.core.content.ContextCompat
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.NotificationCompat
// import androidx.work.WorkManager
// import androidx.work.OneTimeWorkRequestBuilder  
// import androidx.work.Data
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.net.NetworkInterface
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {
    companion object {
        private const val ANDROID_FILES_CHANNEL = "com.structurizr.flutter/android_files"
        private const val ANDROID_CLOUD_STORAGE_CHANNEL = "com.structurizr.flutter/android_cloud_storage"
        private const val ANDROID_ECOSYSTEM_CHANNEL = "com.structurizr.flutter/android_ecosystem"
        private const val ANDROID_PERFORMANCE_CHANNEL = "com.structurizr.flutter/android_performance"
        
        private const val PICK_FILE_REQUEST = 100
        private const val CREATE_FILE_REQUEST = 101
        private const val STORAGE_PERMISSION_REQUEST = 200
    }
    
    private val executor = Executors.newSingleThreadExecutor()
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Android Files Integration
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ANDROID_FILES_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasStoragePermission" -> {
                    result.success(hasStoragePermission())
                }
                "requestStoragePermission" -> {
                    requestStoragePermission()
                    result.success(null)
                }
                "openFilePicker" -> {
                    val allowedTypes = call.argument<List<String>>("allowedTypes") ?: listOf("*/*")
                    val allowMultiple = call.argument<Boolean>("allowMultiple") ?: false
                    openFilePicker(allowedTypes, allowMultiple)
                    result.success(null)
                }
                "saveFile" -> {
                    val fileName = call.argument<String>("fileName") ?: "document"
                    val mimeType = call.argument<String>("mimeType") ?: "text/plain"
                    val content = call.argument<ByteArray>("content")
                    if (content != null) {
                        saveFile(fileName, mimeType, content, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Content cannot be null", null)
                    }
                }
                "getFileInfo" -> {
                    val uri = call.argument<String>("uri")
                    if (uri != null) {
                        getFileInfo(Uri.parse(uri), result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "URI cannot be null", null)
                    }
                }
                "readFile" -> {
                    val uri = call.argument<String>("uri")
                    if (uri != null) {
                        readFile(Uri.parse(uri), result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "URI cannot be null", null)
                    }
                }
                "getRecentFiles" -> {
                    val fileTypes = call.argument<List<String>>("fileTypes") ?: listOf()
                    val limit = call.argument<Int>("limit") ?: 10
                    getRecentFiles(fileTypes, limit, result)
                }
                else -> result.notImplemented()
            }
        }
        
        // Android Cloud Storage Integration
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ANDROID_CLOUD_STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCloudProviders" -> {
                    getCloudProviders(result)
                }
                "isCloudAvailable" -> {
                    val provider = call.argument<String>("provider") ?: ""
                    result.success(isCloudAvailable(provider))
                }
                "uploadToCloud" -> {
                    val provider = call.argument<String>("provider") ?: ""
                    val fileName = call.argument<String>("fileName") ?: ""
                    val content = call.argument<ByteArray>("content")
                    if (content != null) {
                        uploadToCloud(provider, fileName, content, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Content cannot be null", null)
                    }
                }
                "downloadFromCloud" -> {
                    val provider = call.argument<String>("provider") ?: ""
                    val fileName = call.argument<String>("fileName") ?: ""
                    downloadFromCloud(provider, fileName, result)
                }
                "syncWithCloud" -> {
                    val provider = call.argument<String>("provider") ?: ""
                    val localPath = call.argument<String>("localPath") ?: ""
                    syncWithCloud(provider, localPath, result)
                }
                "getCloudFileList" -> {
                    val provider = call.argument<String>("provider") ?: ""
                    val path = call.argument<String>("path") ?: ""
                    getCloudFileList(provider, path, result)
                }
                else -> result.notImplemented()
            }
        }
        
        // Android Ecosystem Integration
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ANDROID_ECOSYSTEM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "addShortcut" -> {
                    val id = call.argument<String>("id") ?: ""
                    val label = call.argument<String>("label") ?: ""
                    val description = call.argument<String>("description") ?: ""
                    val action = call.argument<String>("action") ?: ""
                    addShortcut(id, label, description, action, result)
                }
                "removeShortcut" -> {
                    val id = call.argument<String>("id") ?: ""
                    removeShortcut(id, result)
                }
                "sendNotification" -> {
                    val title = call.argument<String>("title") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    val actionUrl = call.argument<String>("actionUrl")
                    sendNotification(title, body, actionUrl, result)
                }
                "handleIntent" -> {
                    handleCurrentIntent(result)
                }
                "shareFile" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val mimeType = call.argument<String>("mimeType") ?: "text/plain"
                    shareFile(filePath, mimeType, result)
                }
                "openUrl" -> {
                    val url = call.argument<String>("url") ?: ""
                    openUrl(url, result)
                }
                "getDeviceInfo" -> {
                    getDeviceInfo(result)
                }
                else -> result.notImplemented()
            }
        }
        
        // Android Performance Integration
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ANDROID_PERFORMANCE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMemoryInfo" -> {
                    getMemoryInfo(result)
                }
                "getStorageInfo" -> {
                    getStorageInfo(result)
                }
                "getNetworkInfo" -> {
                    getNetworkInfo(result)
                }
                "getBatteryInfo" -> {
                    getBatteryInfo(result)
                }
                "getCpuInfo" -> {
                    getCpuInfo(result)
                }
                "startPerformanceMonitoring" -> {
                    val interval = call.argument<Int>("interval") ?: 5000
                    startPerformanceMonitoring(interval, result)
                }
                "stopPerformanceMonitoring" -> {
                    stopPerformanceMonitoring(result)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    // Storage Permission Methods
    private fun hasStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    private fun requestStoragePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val intent = Intent(android.provider.Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.WRITE_EXTERNAL_STORAGE),
                STORAGE_PERMISSION_REQUEST
            )
        }
    }
    
    // File Operations
    private fun openFilePicker(allowedTypes: List<String>, allowMultiple: Boolean) {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = if (allowedTypes.size == 1) allowedTypes[0] else "*/*"
            if (allowedTypes.size > 1) {
                putExtra(Intent.EXTRA_MIME_TYPES, allowedTypes.toTypedArray())
            }
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple)
        }
        startActivityForResult(intent, PICK_FILE_REQUEST)
    }
    
    private fun saveFile(fileName: String, mimeType: String, content: ByteArray, result: MethodChannel.Result) {
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        startActivityForResult(intent, CREATE_FILE_REQUEST)
    }
    
    private fun getFileInfo(uri: Uri, result: MethodChannel.Result) {
        executor.execute {
            try {
                val cursor = contentResolver.query(uri, null, null, null, null)
                cursor?.use {
                    if (it.moveToFirst()) {
                        val displayName = it.getString(it.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME))
                        val size = it.getLong(it.getColumnIndexOrThrow(OpenableColumns.SIZE))
                        val mimeType = contentResolver.getType(uri)
                        
                        val info = mapOf(
                            "name" to displayName,
                            "size" to size,
                            "mimeType" to mimeType,
                            "uri" to uri.toString()
                        )
                        runOnUiThread { result.success(info) }
                    } else {
                        runOnUiThread { result.error("FILE_NOT_FOUND", "File not found", null) }
                    }
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("FILE_ERROR", e.message, null) }
            }
        }
    }
    
    private fun readFile(uri: Uri, result: MethodChannel.Result) {
        executor.execute {
            try {
                val inputStream = contentResolver.openInputStream(uri)
                val content = inputStream?.readBytes()
                inputStream?.close()
                runOnUiThread { result.success(content) }
            } catch (e: Exception) {
                runOnUiThread { result.error("READ_ERROR", e.message, null) }
            }
        }
    }
    
    private fun getRecentFiles(fileTypes: List<String>, limit: Int, result: MethodChannel.Result) {
        executor.execute {
            try {
                val recentFiles = mutableListOf<Map<String, Any>>()
                // Implementation for getting recent files from MediaStore
                // This is a simplified version - full implementation would query MediaStore
                runOnUiThread { result.success(recentFiles) }
            } catch (e: Exception) {
                runOnUiThread { result.error("RECENT_FILES_ERROR", e.message, null) }
            }
        }
    }
    
    // Cloud Storage Methods
    private fun getCloudProviders(result: MethodChannel.Result) {
        val providers = listOf(
            mapOf("id" to "google_drive", "name" to "Google Drive", "available" to isCloudAvailable("google_drive")),
            mapOf("id" to "dropbox", "name" to "Dropbox", "available" to isCloudAvailable("dropbox")),
            mapOf("id" to "onedrive", "name" to "OneDrive", "available" to isCloudAvailable("onedrive"))
        )
        result.success(providers)
    }
    
    private fun isCloudAvailable(provider: String): Boolean {
        return when (provider) {
            "google_drive" -> isPackageInstalled("com.google.android.apps.docs")
            "dropbox" -> isPackageInstalled("com.dropbox.android")
            "onedrive" -> isPackageInstalled("com.microsoft.skydrive")
            else -> false
        }
    }
    
    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
    
    private fun uploadToCloud(provider: String, fileName: String, content: ByteArray, result: MethodChannel.Result) {
        // Placeholder implementation - would integrate with specific cloud provider SDKs
        result.error("NOT_IMPLEMENTED", "Cloud upload not yet implemented", null)
    }
    
    private fun downloadFromCloud(provider: String, fileName: String, result: MethodChannel.Result) {
        // Placeholder implementation - would integrate with specific cloud provider SDKs
        result.error("NOT_IMPLEMENTED", "Cloud download not yet implemented", null)
    }
    
    private fun syncWithCloud(provider: String, localPath: String, result: MethodChannel.Result) {
        // Placeholder implementation - would use WorkManager for background sync
        result.error("NOT_IMPLEMENTED", "Cloud sync not yet implemented", null)
    }
    
    private fun getCloudFileList(provider: String, path: String, result: MethodChannel.Result) {
        // Placeholder implementation - would query cloud provider APIs
        result.success(emptyList<Map<String, Any>>())
    }
    
    // Ecosystem Methods
    private fun addShortcut(id: String, label: String, description: String, action: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            // Implementation for app shortcuts would go here
            result.success(true)
        } else {
            result.error("UNSUPPORTED", "Shortcuts not supported on this Android version", null)
        }
    }
    
    private fun removeShortcut(id: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            // Implementation for removing shortcuts would go here
            result.success(true)
        } else {
            result.error("UNSUPPORTED", "Shortcuts not supported on this Android version", null)
        }
    }
    
    private fun sendNotification(title: String, body: String, actionUrl: String?, result: MethodChannel.Result) {
        if (NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            // Implementation for sending notifications would go here
            result.success(true)
        } else {
            result.error("PERMISSION_DENIED", "Notification permission not granted", null)
        }
    }
    
    private fun handleCurrentIntent(result: MethodChannel.Result) {
        val intent = intent
        val action = intent.action
        val data = intent.data
        
        val intentInfo = mapOf(
            "action" to action,
            "data" to data?.toString(),
            "type" to intent.type
        )
        result.success(intentInfo)
    }
    
    private fun shareFile(filePath: String, mimeType: String, result: MethodChannel.Result) {
        try {
            val file = File(filePath)
            if (file.exists()) {
                val uri = androidx.core.content.FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    file
                )
                
                val shareIntent = Intent(Intent.ACTION_SEND).apply {
                    type = mimeType
                    putExtra(Intent.EXTRA_STREAM, uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                
                startActivity(Intent.createChooser(shareIntent, "Share file"))
                result.success(true)
            } else {
                result.error("FILE_NOT_FOUND", "File does not exist", null)
            }
        } catch (e: Exception) {
            result.error("SHARE_ERROR", e.message, null)
        }
    }
    
    private fun openUrl(url: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("URL_ERROR", e.message, null)
        }
    }
    
    private fun getDeviceInfo(result: MethodChannel.Result) {
        val info = mapOf(
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "version" to Build.VERSION.RELEASE,
            "sdkVersion" to Build.VERSION.SDK_INT,
            "brand" to Build.BRAND,
            "product" to Build.PRODUCT
        )
        result.success(info)
    }
    
    // Performance Methods
    private fun getMemoryInfo(result: MethodChannel.Result) {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val memoryInfo = android.app.ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        val info = mapOf(
            "totalMemory" to memoryInfo.totalMem,
            "availableMemory" to memoryInfo.availMem,
            "lowMemory" to memoryInfo.lowMemory,
            "threshold" to memoryInfo.threshold
        )
        result.success(info)
    }
    
    private fun getStorageInfo(result: MethodChannel.Result) {
        val internalDir = filesDir
        val statFs = StatFs(internalDir.path)
        
        val info = mapOf(
            "totalSpace" to statFs.totalBytes,
            "freeSpace" to statFs.freeBytes,
            "availableSpace" to statFs.availableBytes
        )
        result.success(info)
    }
    
    private fun getNetworkInfo(result: MethodChannel.Result) {
        try {
            val networkInterfaces = NetworkInterface.getNetworkInterfaces()
            val interfaces = mutableListOf<Map<String, Any>>()
            
            for (netInterface in networkInterfaces) {
                val interfaceInfo = mapOf(
                    "name" to netInterface.name,
                    "displayName" to netInterface.displayName,
                    "isUp" to netInterface.isUp,
                    "isLoopback" to netInterface.isLoopback
                )
                interfaces.add(interfaceInfo)
            }
            
            result.success(mapOf("interfaces" to interfaces))
        } catch (e: Exception) {
            result.error("NETWORK_ERROR", e.message, null)
        }
    }
    
    private fun getBatteryInfo(result: MethodChannel.Result) {
        // Battery info would require BatteryManager integration
        result.error("NOT_IMPLEMENTED", "Battery info not yet implemented", null)
    }
    
    private fun getCpuInfo(result: MethodChannel.Result) {
        val info = mapOf(
            "processors" to Runtime.getRuntime().availableProcessors(),
            "architecture" to Build.SUPPORTED_ABIS[0]
        )
        result.success(info)
    }
    
    private fun startPerformanceMonitoring(interval: Int, result: MethodChannel.Result) {
        // Performance monitoring would use WorkManager for periodic tasks
        result.error("NOT_IMPLEMENTED", "Performance monitoring not yet implemented", null)
    }
    
    private fun stopPerformanceMonitoring(result: MethodChannel.Result) {
        // Stop performance monitoring
        result.error("NOT_IMPLEMENTED", "Performance monitoring not yet implemented", null)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (resultCode == Activity.RESULT_OK) {
            when (requestCode) {
                PICK_FILE_REQUEST -> {
                    // Handle file picker result
                    data?.data?.let { uri ->
                        // Notify Flutter about selected file
                    }
                }
                CREATE_FILE_REQUEST -> {
                    // Handle file creation result
                    data?.data?.let { uri ->
                        // Save content to created file
                    }
                }
            }
        }
    }
}