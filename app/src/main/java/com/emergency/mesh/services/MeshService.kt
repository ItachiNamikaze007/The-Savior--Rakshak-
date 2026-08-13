package com.emergency.mesh.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.emergency.mesh.MainActivity
import com.emergency.mesh.R
import com.emergency.mesh.handlers.MessageHandler
import com.emergency.mesh.models.MeshMessage
import com.emergency.mesh.models.MeshPeer
import com.emergency.mesh.models.UserRole
import com.emergency.mesh.network.ConnectionManager

/**
 * Foreground service for mesh network operations
 * Keeps connections alive and handles background message relay
 */
class MeshService : Service() {

    private lateinit var connectionManager: ConnectionManager
    private lateinit var messageHandler: MessageHandler
    
    private val binder = MeshBinder()
    private val serviceCallbacks = java.util.concurrent.CopyOnWriteArrayList<MeshServiceCallback>()

    companion object {
        private const val TAG = "MeshService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "emergency_mesh_channel"
        private const val PREF_USER_ROLE = "user_role"
        const val ACTION_SEND_MESSAGE = "com.emergency.mesh.SEND_MESSAGE"
        const val EXTRA_MESSAGE = "message"
    }

    inner class MeshBinder : Binder() {
        fun getService(): MeshService = this@MeshService
    }

    interface MeshServiceCallback {
        fun onMessageReceived(message: MeshMessage)
        fun onPeersUpdated(peers: List<MeshPeer>)
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        
        // Initialize managers
        connectionManager = ConnectionManager(this)
        messageHandler = MessageHandler(this)
        
        // Load user role and set on connection manager
        loadUserRole()
        
        // Set up callbacks
        connectionManager.onMessageReceived { message ->
            notifyMessageReceived(message)
        }
        
        connectionManager.onPeersUpdated { peers ->
            notifyPeersUpdated(peers)
        }
        
        // Initialize connection manager
        connectionManager.initialize()
        
        // Create notification channel
        createNotificationChannel()
        
        // Start as foreground service
        startForeground()
    }

    /**
     * Load user role from SharedPreferences and set on ConnectionManager
     */
    private fun loadUserRole() {
        val prefs = getSharedPreferences("emergency_mesh", Context.MODE_PRIVATE)
        val savedRole = prefs.getString(PREF_USER_ROLE, null)
        
        if (savedRole != null) {
            try {
                connectionManager.currentUserRole = UserRole.valueOf(savedRole)
                Log.d(TAG, "User role loaded: ${connectionManager.currentUserRole}")
            } catch (e: Exception) {
                Log.e(TAG, "Error loading user role", e)
            }
        }
    }

    /**
     * Set user role (called from MainActivity when role is selected)
     */
    fun setUserRole(role: UserRole) {
        connectionManager.currentUserRole = role
        Log.d(TAG, "User role set: $role")
    }

    /**
     * Set power mode for BLE operations
     * @param highRange true for maximum range (higher battery usage), false for power saving
     */
    fun setPowerMode(highRange: Boolean) {
        connectionManager.setPowerMode(highRange)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        
        // Start mesh network discovery
        connectionManager.startDiscovery()
        
        // Request location update
        messageHandler.requestLocationUpdate()
        
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
        
        connectionManager.cleanup()
        serviceCallbacks.clear()
    }

    /**
     * Start service as foreground
     */
    private fun startForeground() {
        val notification = createNotification()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    /**
     * Create notification for foreground service
     */
    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Emergency Mesh Active")
            .setContentText("Mesh network running")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    /**
     * Create notification channel
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Emergency Mesh Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps mesh network running"
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Send message through mesh network
     */
    fun sendMessage(message: MeshMessage) {
        connectionManager.sendMessage(message)
    }

    /**
     * Get active peers
     */
    fun getActivePeers(): List<MeshPeer> {
        return connectionManager.getActivePeers()
    }

    /**
     * Register callback
     */
    fun registerCallback(callback: MeshServiceCallback) {
        serviceCallbacks.add(callback)
    }

    /**
     * Unregister callback
     */
    fun unregisterCallback(callback: MeshServiceCallback) {
        serviceCallbacks.remove(callback)
    }

    /**
     * Notify callbacks of received message
     */
    private fun notifyMessageReceived(message: MeshMessage) {
        serviceCallbacks.forEach { it.onMessageReceived(message) }
        
        // Show notification for important messages
        if (message.type == com.emergency.mesh.models.MessageType.SOS) {
            showSOSNotification(message)
        }
    }

    /**
     * Notify callbacks of peer updates
     */
    private fun notifyPeersUpdated(peers: List<MeshPeer>) {
        serviceCallbacks.forEach { it.onPeersUpdated(peers) }
    }

    /**
     * Show notification for SOS message
     */
    private fun showSOSNotification(message: MeshMessage) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🚨 SOS ALERT")
            .setContentText(message.content)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(message.id.hashCode(), notification)
    }
}
