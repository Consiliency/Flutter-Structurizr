package com.structurizr.flutter

import android.content.Context
import android.content.Intent
import androidx.activity.result.ActivityResultLauncher
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.Scope
import com.google.api.client.extensions.android.http.AndroidHttp
import com.google.api.client.googleapis.extensions.android.gms.auth.GoogleAccountCredential
import com.google.api.client.json.gson.GsonFactory
import com.google.api.services.drive.Drive
import com.google.api.services.drive.DriveScopes
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class GoogleDriveService(
    private val context: Context,
    private val channel: MethodChannel,
    private val signInLauncher: ActivityResultLauncher<Intent>
) : MethodCallHandler {

    private var googleSignInClient: GoogleSignInClient? = null
    private var driveService: Drive? = null
    private var currentAccount: GoogleSignInAccount? = null

    init {
        setupGoogleSignIn()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> isAvailable(result)
            "authenticate" -> authenticate(call, result)
            "refreshToken" -> refreshToken(result)
            "signOut" -> signOut(result)
            else -> result.notImplemented()
        }
    }

    private fun setupGoogleSignIn() {
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestEmail()
            .requestScopes(Scope(DriveScopes.DRIVE_FILE))
            .build()

        googleSignInClient = GoogleSignIn.getClient(context, gso)
    }

    private fun isAvailable(result: MethodChannel.Result) {
        try {
            // Check if Google Play Services are available
            val account = GoogleSignIn.getLastSignedInAccount(context)
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun authenticate(call: MethodCall, result: MethodChannel.Result) {
        try {
            val clientId = call.argument<String>("clientId")
            val scopes = call.argument<List<String>>("scopes") ?: listOf(DriveScopes.DRIVE_FILE)

            // Check if already signed in
            val account = GoogleSignIn.getLastSignedInAccount(context)
            if (account != null && hasRequiredScopes(account, scopes)) {
                currentAccount = account
                setupDriveService(account)
                result.success(mapOf(
                    "accessToken" to getAccessToken(account),
                    "expiresIn" to 3600 // Default to 1 hour
                ))
                return
            }

            // Need to sign in
            val signInIntent = googleSignInClient?.signInIntent
            if (signInIntent != null) {
                // Store the result callback for when sign-in completes
                pendingAuthResult = result
                signInLauncher.launch(signInIntent)
            } else {
                result.error("SIGN_IN_ERROR", "Failed to create sign-in intent", null)
            }
        } catch (e: Exception) {
            result.error("AUTH_ERROR", "Authentication failed: ${e.message}", null)
        }
    }

    private fun refreshToken(result: MethodChannel.Result) {
        try {
            val account = GoogleSignIn.getLastSignedInAccount(context)
            if (account != null) {
                currentAccount = account
                setupDriveService(account)
                result.success(mapOf(
                    "accessToken" to getAccessToken(account),
                    "expiresIn" to 3600
                ))
            } else {
                result.error("NO_ACCOUNT", "No signed in account", null)
            }
        } catch (e: Exception) {
            result.error("REFRESH_ERROR", "Token refresh failed: ${e.message}", null)
        }
    }

    private fun signOut(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                googleSignInClient?.signOut()?.addOnCompleteListener { task ->
                    currentAccount = null
                    driveService = null
                    result.success(true)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("SIGN_OUT_ERROR", "Sign out failed: ${e.message}", null)
                }
            }
        }
    }

    fun handleSignInResult(account: GoogleSignInAccount?) {
        if (account != null) {
            currentAccount = account
            setupDriveService(account)
            pendingAuthResult?.success(mapOf(
                "accessToken" to getAccessToken(account),
                "expiresIn" to 3600
            ))
        } else {
            pendingAuthResult?.error("SIGN_IN_FAILED", "Google Sign-In failed", null)
        }
        pendingAuthResult = null
    }

    private fun setupDriveService(account: GoogleSignInAccount) {
        try {
            val credential = GoogleAccountCredential.usingOAuth2(
                context,
                listOf(DriveScopes.DRIVE_FILE)
            )
            credential.selectedAccount = account.account

            driveService = Drive.Builder(
                AndroidHttp.newCompatibleTransport(),
                GsonFactory(),
                credential
            )
                .setApplicationName("Structurizr Flutter")
                .build()
        } catch (e: Exception) {
            // Handle setup error
        }
    }

    private fun hasRequiredScopes(account: GoogleSignInAccount, requiredScopes: List<String>): Boolean {
        val grantedScopes = account.grantedScopes.map { it.scopeUri }
        return requiredScopes.all { scope -> grantedScopes.contains(scope) }
    }

    private fun getAccessToken(account: GoogleSignInAccount): String {
        // In a real implementation, you would get the actual access token
        // This is a simplified version
        return account.idToken ?: account.id ?: "mock_token"
    }

    companion object {
        private var pendingAuthResult: MethodChannel.Result? = null
    }
}