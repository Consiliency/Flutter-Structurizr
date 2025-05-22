package com.structurizr.flutter

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class ShareReceiver(private val context: Context, private val flutterEngine: FlutterEngine) : MethodCallHandler {
    companion object {
        private const val CHANNEL = "structurizr/android_share"
        private const val EVENT_CHANNEL = "structurizr/android_share_events"
        private const val SHARED_PREFS = "structurizr_share_prefs"
    }
    
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var sharedFiles: MutableList<SharedFileInfo> = mutableListOf()
    private var shareIntentData: ShareIntentData? = null
    
    data class SharedFileInfo(
        val path: String,
        val name: String,
        val mimeType: String?,
        val size: Long?
    )
    
    data class ShareIntentData(
        val action: String?,
        val type: String?,
        val text: String?,
        val subject: String?,
        val files: List<SharedFileInfo>?
    )
    
    fun initialize() {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(result)
            "getSharedFiles" -> handleGetSharedFiles(result)
            "clearSharedFiles" -> handleClearSharedFiles(result)
            "shareWorkspace" -> handleShareWorkspace(call, result)
            "shareMultipleWorkspaces" -> handleShareMultipleWorkspaces(call, result)
            "configureShareTarget" -> handleConfigureShareTarget(call, result)
            "getCapabilities" -> handleGetCapabilities(result)
            "wasOpenedViaShare" -> handleWasOpenedViaShare(result)
            "getShareIntentData" -> handleGetShareIntentData(result)
            "createWorkspaceShortcut" -> handleCreateWorkspaceShortcut(call, result)
            "supportsShortcuts" -> handleSupportsShortcuts(result)
            else -> result.notImplemented()
        }
    }
    
    private fun handleInitialize(result: Result) {
        try {
            // Initialize share integration
            result.success(true)
        } catch (e: Exception) {
            result.error("INIT_ERROR", "Failed to initialize share integration", e.message)
        }
    }
    
    private fun handleGetSharedFiles(result: Result) {
        try {
            val files = sharedFiles.map { file ->
                mapOf(
                    "path" to file.path,
                    "name" to file.name,
                    "mimeType" to file.mimeType,
                    "size" to file.size
                )
            }
            result.success(files)
        } catch (e: Exception) {
            result.error("GET_FILES_ERROR", "Failed to get shared files", e.message)
        }
    }
    
    private fun handleClearSharedFiles(result: Result) {
        try {
            sharedFiles.clear()
            shareIntentData = null
            result.success(true)
        } catch (e: Exception) {
            result.error("CLEAR_ERROR", "Failed to clear shared files", e.message)
        }
    }
    
    private fun handleShareWorkspace(call: MethodCall, result: Result) {
        try {
            val filePath = call.argument<String>("filePath")
            val title = call.argument<String>("title") ?: "Share Workspace"
            val subject = call.argument<String>("subject") ?: "Structurizr Workspace"
            
            if (filePath == null) {
                result.error("INVALID_ARGS", "File path is required", null)
                return
            }
            
            val file = File(filePath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File does not exist", null)
                return
            }
            
            val uri = androidx.core.content.FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )
            
            val shareIntent = Intent().apply {
                action = Intent.ACTION_SEND
                type = getMimeType(file.extension)
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TITLE, title)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            
            val chooser = Intent.createChooser(shareIntent, title)
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(chooser)
            
            result.success(true)
        } catch (e: Exception) {
            result.error("SHARE_ERROR", "Failed to share workspace", e.message)
        }
    }
    
    private fun handleShareMultipleWorkspaces(call: MethodCall, result: Result) {
        try {
            val filePaths = call.argument<List<String>>("filePaths")
            val title = call.argument<String>("title") ?: "Share Workspaces"
            val subject = call.argument<String>("subject") ?: "Structurizr Workspaces"
            
            if (filePaths == null || filePaths.isEmpty()) {
                result.error("INVALID_ARGS", "File paths are required", null)
                return
            }
            
            val uris = filePaths.mapNotNull { filePath ->
                val file = File(filePath)
                if (file.exists()) {
                    androidx.core.content.FileProvider.getUriForFile(
                        context,
                        "${context.packageName}.fileprovider",
                        file
                    )
                } else null
            }
            
            if (uris.isEmpty()) {
                result.error("NO_FILES", "No valid files found", null)
                return
            }
            
            val shareIntent = Intent().apply {
                action = Intent.ACTION_SEND_MULTIPLE
                type = "application/*"
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TITLE, title)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            
            val chooser = Intent.createChooser(shareIntent, title)
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(chooser)
            
            result.success(true)
        } catch (e: Exception) {
            result.error("SHARE_ERROR", "Failed to share workspaces", e.message)
        }
    }
    
    private fun handleConfigureShareTarget(call: MethodCall, result: Result) {
        try {
            val supportedMimeTypes = call.argument<List<String>>("supportedMimeTypes")
            val supportedFileExtensions = call.argument<List<String>>("supportedFileExtensions")
            val activityLabel = call.argument<String>("activityLabel")
            
            // Store configuration in shared preferences
            val prefs = context.getSharedPreferences(SHARED_PREFS, Context.MODE_PRIVATE)
            prefs.edit().apply {
                putStringSet("supported_mime_types", supportedMimeTypes?.toSet())
                putStringSet("supported_file_extensions", supportedFileExtensions?.toSet())
                putString("activity_label", activityLabel)
                apply()
            }
            
            result.success(true)
        } catch (e: Exception) {
            result.error("CONFIG_ERROR", "Failed to configure share target", e.message)
        }
    }
    
    private fun handleGetCapabilities(result: Result) {
        try {
            val capabilities = mapOf(
                "shareTarget" to true,
                "fileSharing" to true,
                "multipleFiles" to true,
                "customMimeTypes" to true
            )
            result.success(capabilities)
        } catch (e: Exception) {
            result.error("CAPABILITIES_ERROR", "Failed to get capabilities", e.message)
        }
    }
    
    private fun handleWasOpenedViaShare(result: Result) {
        try {
            val wasOpened = shareIntentData != null
            result.success(wasOpened)
        } catch (e: Exception) {
            result.error("CHECK_ERROR", "Failed to check share intent", e.message)
        }
    }
    
    private fun handleGetShareIntentData(result: Result) {
        try {
            val data = shareIntentData?.let { intentData ->
                mapOf(
                    "action" to intentData.action,
                    "type" to intentData.type,
                    "text" to intentData.text,
                    "subject" to intentData.subject,
                    "files" to intentData.files?.map { file ->
                        mapOf(
                            "path" to file.path,
                            "name" to file.name,
                            "mimeType" to file.mimeType,
                            "size" to file.size
                        )
                    }
                )
            }
            result.success(data)
        } catch (e: Exception) {
            result.error("GET_DATA_ERROR", "Failed to get share intent data", e.message)
        }
    }
    
    private fun handleCreateWorkspaceShortcut(call: MethodCall, result: Result) {
        try {
            val workspaceName = call.argument<String>("workspaceName")
            val workspacePath = call.argument<String>("workspacePath")
            val iconPath = call.argument<String>("iconPath")
            
            if (workspaceName == null || workspacePath == null) {
                result.error("INVALID_ARGS", "Workspace name and path are required", null)
                return
            }
            
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra("workspace_path", workspacePath)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            }
            
            val icon = if (iconPath != null && File(iconPath).exists()) {
                IconCompat.createWithContentUri(Uri.fromFile(File(iconPath)))
            } else {
                IconCompat.createWithResource(context, android.R.drawable.ic_menu_edit)
            }
            
            val shortcut = ShortcutInfoCompat.Builder(context, "workspace_$workspacePath")
                .setShortLabel(workspaceName)
                .setLongLabel("Open $workspaceName")
                .setIcon(icon)
                .setIntent(intent)
                .build()
            
            val success = ShortcutManagerCompat.requestPinShortcut(context, shortcut, null)
            result.success(success)
        } catch (e: Exception) {
            result.error("SHORTCUT_ERROR", "Failed to create shortcut", e.message)
        }
    }
    
    private fun handleSupportsShortcuts(result: Result) {
        try {
            val supports = ShortcutManagerCompat.isRequestPinShortcutSupported(context)
            result.success(supports)
        } catch (e: Exception) {
            result.error("SHORTCUT_CHECK_ERROR", "Failed to check shortcut support", e.message)
        }
    }
    
    fun handleIncomingIntent(intent: Intent) {
        try {
            when (intent.action) {
                Intent.ACTION_SEND -> handleSingleFile(intent)
                Intent.ACTION_SEND_MULTIPLE -> handleMultipleFiles(intent)
            }
        } catch (e: Exception) {
            println("Error handling incoming intent: ${e.message}")
        }
    }
    
    private fun handleSingleFile(intent: Intent) {
        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
        
        val files = mutableListOf<SharedFileInfo>()
        
        if (uri != null) {
            val file = copyFileFromUri(uri)
            if (file != null) {
                files.add(file)
            }
        }
        
        shareIntentData = ShareIntentData(
            action = intent.action,
            type = intent.type,
            text = text,
            subject = subject,
            files = files
        )
        
        sharedFiles.addAll(files)
        
        // Notify Flutter
        eventSink?.success(mapOf(
            "type" to "fileReceived",
            "data" to mapOf(
                "files" to files.map { mapOf(
                    "path" to it.path,
                    "name" to it.name,
                    "mimeType" to it.mimeType,
                    "size" to it.size
                )}
            )
        ))
    }
    
    private fun handleMultipleFiles(intent: Intent) {
        val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
        
        val files = mutableListOf<SharedFileInfo>()
        
        uris?.forEach { uri ->
            val file = copyFileFromUri(uri)
            if (file != null) {
                files.add(file)
            }
        }
        
        shareIntentData = ShareIntentData(
            action = intent.action,
            type = intent.type,
            text = null,
            subject = subject,
            files = files
        )
        
        sharedFiles.addAll(files)
        
        // Notify Flutter
        eventSink?.success(mapOf(
            "type" to "multipleFilesReceived",
            "data" to mapOf(
                "files" to files.map { mapOf(
                    "path" to it.path,
                    "name" to it.name,
                    "mimeType" to it.mimeType,
                    "size" to it.size
                )}
            )
        ))
    }
    
    private fun copyFileFromUri(uri: Uri): SharedFileInfo? {
        try {
            val inputStream: InputStream = context.contentResolver.openInputStream(uri) ?: return null
            
            val fileName = getFileName(uri) ?: "shared_file"
            val mimeType = context.contentResolver.getType(uri)
            
            val internalDir = File(context.filesDir, "shared")
            if (!internalDir.exists()) {
                internalDir.mkdirs()
            }
            
            val file = File(internalDir, fileName)
            val outputStream = FileOutputStream(file)
            
            inputStream.use { input ->
                outputStream.use { output ->
                    input.copyTo(output)
                }
            }
            
            return SharedFileInfo(
                path = file.absolutePath,
                name = fileName,
                mimeType = mimeType,
                size = file.length()
            )
        } catch (e: Exception) {
            println("Error copying file from URI: ${e.message}")
            return null
        }
    }
    
    private fun getFileName(uri: Uri): String? {
        return context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
            if (cursor.moveToFirst() && nameIndex >= 0) {
                cursor.getString(nameIndex)
            } else null
        }
    }
    
    private fun getMimeType(extension: String): String {
        return when (extension.lowercase()) {
            "json" -> "application/json"
            "dsl" -> "text/plain"
            else -> MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase()) 
                ?: "application/octet-stream"
        }
    }
    
    fun dispose() {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        eventSink = null
    }
}