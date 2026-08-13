package com.emergency.mesh

import android.Manifest
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.setupWithNavController
import com.emergency.mesh.handlers.MessageHandler
import com.emergency.mesh.handlers.VoiceHandler
import com.emergency.mesh.models.MeshMessage
import com.emergency.mesh.models.MeshPeer
import com.emergency.mesh.models.UserProfile
import com.emergency.mesh.models.UserRole
import com.emergency.mesh.services.MeshService
import com.google.android.material.bottomnavigation.BottomNavigationView
import java.util.*

/**
 * Main activity with navigation-based UI for emergency mesh communication
 */
class MainActivity : AppCompatActivity() {

    lateinit var userRole: UserRole
        private set
    lateinit var deviceId: String
        private set
    var userProfile: UserProfile? = null
        private set
    
    var meshService: MeshService? = null
        private set
    private var serviceBound = false
    
    lateinit var messageHandler: MessageHandler
        private set
    lateinit var voiceHandler: VoiceHandler
        private set
    
    // Callbacks for fragments
    private val messageCallbacks = mutableListOf<(MeshMessage) -> Unit>()
    private val peerCallbacks = mutableListOf<(List<MeshPeer>) -> Unit>()
    
    // Current state
    private var currentPeers: List<MeshPeer> = emptyList()
    private var isSafeStatusSet = false
    private val safePeerIds = mutableSetOf<String>()
    private val messageHistory = mutableListOf<MeshMessage>()
    
    companion object {
        private const val TAG = "MainActivity"
        private const val PERMISSIONS_REQUEST_CODE = 100
        private const val PREF_USER_ROLE = "user_role"
        private const val PREF_DEVICE_ID = "device_id"
        private const val PREF_LANGUAGE = "language"
        private const val PREF_SAFE_STATUS = "safe_status"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize handlers
        messageHandler = MessageHandler(this)
        voiceHandler = VoiceHandler(this)
        
        // Check if user registration is needed
        if (!UserProfile.exists(this)) {
            showRegistrationDialog {
                loadOrSelectUserRole()
            }
        } else {
            userProfile = UserProfile.load(this)
            loadOrSelectUserRole()
        }
    }

    /**
     * Show user registration dialog on first launch
     */
    private fun showRegistrationDialog(onComplete: () -> Unit) {
        val dialogView: View = LayoutInflater.from(this).inflate(R.layout.dialog_registration, null)
        
        val etName = dialogView.findViewById<EditText>(R.id.etName)
        val etPhone = dialogView.findViewById<EditText>(R.id.etPhone)
        val etEmergencyContact = dialogView.findViewById<EditText>(R.id.etEmergencyContact)
        val etBloodType = dialogView.findViewById<EditText>(R.id.etBloodType)
        val etMedicalInfo = dialogView.findViewById<EditText>(R.id.etMedicalInfo)
        
        AlertDialog.Builder(this)
            .setTitle(R.string.personal_info)
            .setView(dialogView)
            .setPositiveButton(R.string.save_profile) { _, _ ->
                val name = etName.text.toString().trim()
                
                if (name.isBlank()) {
                    Toast.makeText(this, R.string.name_required, Toast.LENGTH_SHORT).show()
                    showRegistrationDialog(onComplete)
                    return@setPositiveButton
                }
                
                val profile = UserProfile(
                    name = name,
                    phone = etPhone.text.toString().trim(),
                    emergencyContact = etEmergencyContact.text.toString().trim(),
                    bloodType = etBloodType.text.toString().trim(),
                    medicalInfo = etMedicalInfo.text.toString().trim()
                )
                
                UserProfile.save(this, profile)
                userProfile = profile
                
                Toast.makeText(this, R.string.registration_complete, Toast.LENGTH_SHORT).show()
                onComplete()
            }
            .setCancelable(false)
            .show()
    }

    /**
     * Load or select user role
     */
    private fun loadOrSelectUserRole() {
        val prefs = getSharedPreferences("emergency_mesh", Context.MODE_PRIVATE)
        val savedRole = prefs.getString(PREF_USER_ROLE, null)
        
        if (savedRole != null) {
            userRole = UserRole.valueOf(savedRole)
            deviceId = prefs.getString(PREF_DEVICE_ID, UUID.randomUUID().toString())
                ?: UUID.randomUUID().toString()
            isSafeStatusSet = prefs.getBoolean(PREF_SAFE_STATUS, false)
            continueSetup()
        } else {
            showRoleSelectionDialog()
        }
    }

    /**
     * Show role selection dialog
     */
    private fun showRoleSelectionDialog() {
        val roles = arrayOf(getString(R.string.role_citizen), getString(R.string.role_official))
        
        AlertDialog.Builder(this)
            .setTitle(R.string.select_role)
            .setItems(roles) { _, which ->
                userRole = if (which == 0) UserRole.CITIZEN else UserRole.OFFICIAL
                deviceId = UUID.randomUUID().toString()
                
                val prefs = getSharedPreferences("emergency_mesh", Context.MODE_PRIVATE)
                prefs.edit()
                    .putString(PREF_USER_ROLE, userRole.name)
                    .putString(PREF_DEVICE_ID, deviceId)
                    .apply()
                
                continueSetup()
            }
            .setCancelable(false)
            .show()
    }

    private fun continueSetup() {
        setContentView(R.layout.activity_main)
        setupNavigation()
        requestPermissions()
    }

    private fun setupNavigation() {
        val navHostFragment = supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        val navController = navHostFragment.navController
        
        val bottomNav = findViewById<BottomNavigationView>(R.id.bottom_navigation)
        bottomNav.setupWithNavController(navController)
    }

    /**
     * Request necessary permissions
     */
    private fun requestPermissions() {
        val permissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.BLUETOOTH,
            Manifest.permission.BLUETOOTH_ADMIN
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_SCAN)
            permissions.add(Manifest.permission.BLUETOOTH_ADVERTISE)
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        val permissionsToRequest = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionsToRequest.toTypedArray(),
                PERMISSIONS_REQUEST_CODE
            )
        } else {
            startMeshService()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSIONS_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            
            if (allGranted) {
                startMeshService()
            } else {
                Toast.makeText(this, R.string.permissions_required, Toast.LENGTH_LONG).show()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        if (::userRole.isInitialized) {
            bindMeshService()
        }
    }

    override fun onStop() {
        super.onStop()
        unbindMeshService()
    }

    override fun onDestroy() {
        super.onDestroy()
        voiceHandler.cleanup()
    }

    /**
     * Start mesh service
     */
    private fun startMeshService() {
        val intent = Intent(this, MeshService::class.java)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    /**
     * Bind to mesh service
     */
    private fun bindMeshService() {
        val intent = Intent(this, MeshService::class.java)
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    /**
     * Unbind from mesh service
     */
    private fun unbindMeshService() {
        if (serviceBound) {
            meshService?.unregisterCallback(serviceCallback)
            unbindService(serviceConnection)
            serviceBound = false
        }
    }

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as MeshService.MeshBinder
            meshService = binder.getService()
            serviceBound = true
            
            if (::userRole.isInitialized) {
                meshService?.setUserRole(userRole)
            }
            
            meshService?.registerCallback(serviceCallback)
            
            // Re-broadcast safe status if set
            if (isSafeStatusSet) {
                 val message = messageHandler.createSafeMessage(deviceId, true)
                 meshService?.sendMessage(message)
            }
            
            Log.d(TAG, "Service connected")
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            meshService = null
            serviceBound = false
            Log.d(TAG, "Service disconnected")
        }
    }

    private val serviceCallback = object : MeshService.MeshServiceCallback {
        override fun onMessageReceived(message: MeshMessage) {
            // Add to history
            messageHistory.add(message)
            
            if (message.type == com.emergency.mesh.models.MessageType.SAFE) {
                if (message.content == "Status cleared") {
                    safePeerIds.remove(message.senderId)
                } else {
                    safePeerIds.add(message.senderId)
                }
                // Notify peers updated to refresh safe count
                runOnUiThread {
                    peerCallbacks.forEach { it(currentPeers) }
                }
            }
            
            runOnUiThread {
                messageCallbacks.forEach { it(message) }
            }
        }

        override fun onPeersUpdated(peers: List<MeshPeer>) {
            currentPeers = peers
            runOnUiThread {
                peerCallbacks.forEach { it(peers) }
            }
        }
    }

    // Public methods for fragments
    
    fun registerMessageCallback(callback: (MeshMessage) -> Unit) {
        messageCallbacks.add(callback)
    }
    
    fun unregisterMessageCallback(callback: (MeshMessage) -> Unit) {
        messageCallbacks.remove(callback)
    }
    
    fun registerPeerCallback(callback: (List<MeshPeer>) -> Unit) {
        peerCallbacks.add(callback)
        // Immediately send current peers
        callback(currentPeers)
    }
    
    fun unregisterPeerCallback(callback: (List<MeshPeer>) -> Unit) {
        peerCallbacks.remove(callback)
    }
    
    fun sendMessage(message: MeshMessage) {
        meshService?.sendMessage(message)
        // Add to history if it's a chat message or SOS
        if (message.type != com.emergency.mesh.models.MessageType.SAFE) {
             messageHistory.add(message)
        }
    }
    
    fun getMessageHistory(): List<MeshMessage> = messageHistory.toList()
    
    fun setPowerMode(highRange: Boolean) {
        meshService?.setPowerMode(highRange)
    }
    
    fun getPeerCount(): Int = currentPeers.size
    
    fun getSafePeerCount(): Int = safePeerIds.size
    
    fun isSafe(): Boolean = isSafeStatusSet
    
    fun setSafeStatus(safe: Boolean) {
        isSafeStatusSet = safe
        getSharedPreferences("emergency_mesh", Context.MODE_PRIVATE)
            .edit()
            .putBoolean(PREF_SAFE_STATUS, safe)
            .apply()
    }
    
    fun updateUserRole(role: UserRole) {
        userRole = role
        getSharedPreferences("emergency_mesh", Context.MODE_PRIVATE)
            .edit()
            .putString(PREF_USER_ROLE, role.name)
            .apply()
        meshService?.setUserRole(role)
    }
    
    fun setLanguage(languageCode: String) {
        getSharedPreferences("emergency_mesh", Context.MODE_PRIVATE)
            .edit()
            .putString(PREF_LANGUAGE, languageCode)
            .apply()
        
        // Apply language change
        val locale = Locale(languageCode)
        Locale.setDefault(locale)
        val config = Configuration(resources.configuration)
        config.setLocale(locale)
        resources.updateConfiguration(config, resources.displayMetrics)
        
        // Recreate activity to apply changes
        recreate()
    }
    
    fun getCurrentLanguage(): String {
        return getSharedPreferences("emergency_mesh", Context.MODE_PRIVATE)
            .getString(PREF_LANGUAGE, "en") ?: "en"
    }
}
