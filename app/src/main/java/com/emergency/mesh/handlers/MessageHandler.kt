package com.emergency.mesh.handlers

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.util.Log
import androidx.core.app.ActivityCompat
import com.emergency.mesh.models.MeshMessage
import com.emergency.mesh.models.MessageType
import com.emergency.mesh.models.UserProfile
import java.util.*

/**
 * Handles message creation with GPS coordinates
 * Manages location services and coordinate attachment
 */
class MessageHandler(private val context: Context) {

    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private var currentLocation: Location? = null

    companion object {
        private const val TAG = "MessageHandler"
        private const val LOCATION_TIMEOUT_MS = 5000L
    }

    /**
     * Get current user profile
     */
    private fun getUserProfile(): UserProfile? {
        return UserProfile.load(context)
    }

    /**
     * Get sender name from profile or default
     */
    private fun getSenderName(): String {
        return getUserProfile()?.name ?: ""
    }

    /**
     * Create a text message with current GPS coordinates
     */
    fun createTextMessage(text: String, senderId: String): MeshMessage {
        val location = getCurrentLocation()
        val profile = getUserProfile()
        
        return MeshMessage(
            id = UUID.randomUUID().toString(),
            type = MessageType.TEXT,
            content = text,
            latitude = location?.latitude,
            longitude = location?.longitude,
            timestamp = System.currentTimeMillis(),
            senderId = senderId,
            senderName = getSenderName(),
            senderProfile = profile?.getSOSInfo() ?: ""
        )
    }

    /**
     * Create a voice message with current GPS coordinates
     */
    fun createVoiceMessage(audioData: ByteArray, senderId: String): MeshMessage {
        val location = getCurrentLocation()
        val profile = getUserProfile()
        
        return MeshMessage(
            id = UUID.randomUUID().toString(),
            type = MessageType.VOICE,
            content = "Voice message",
            latitude = location?.latitude,
            longitude = location?.longitude,
            timestamp = System.currentTimeMillis(),
            senderId = senderId,
            senderName = getSenderName(),
            senderProfile = profile?.getSOSInfo() ?: "",
            audioData = audioData
        )
    }

    /**
     * Create an SOS message with current GPS coordinates and user profile
     */
    fun createSOSMessage(senderId: String): MeshMessage {
        val location = getCurrentLocation()
        val profile = getUserProfile()
        
        val sosContent = if (location != null) {
            "SOS - Emergency at ${location.latitude}, ${location.longitude}"
        } else {
            "SOS - Emergency (Location unavailable)"
        }
        
        return MeshMessage(
            id = UUID.randomUUID().toString(),
            type = MessageType.SOS,
            content = sosContent,
            latitude = location?.latitude,
            longitude = location?.longitude,
            timestamp = System.currentTimeMillis(),
            senderId = senderId,
            senderName = getSenderName(),
            senderProfile = profile?.getSOSInfo() ?: ""
        )
    }

    /**
     * Create a SAFE status message with current GPS coordinates
     */
    fun createSafeMessage(senderId: String, isSafe: Boolean): MeshMessage {
        val location = getCurrentLocation()
        val profile = getUserProfile()
        
        val safeContent = if (isSafe) {
            if (location != null) {
                "I am SAFE at ${String.format("%.4f", location.latitude)}, ${String.format("%.4f", location.longitude)}"
            } else {
                "I am SAFE"
            }
        } else {
            "Status cleared"
        }
        
        return MeshMessage(
            id = UUID.randomUUID().toString(),
            type = MessageType.SAFE,
            content = safeContent,
            latitude = location?.latitude,
            longitude = location?.longitude,
            timestamp = System.currentTimeMillis(),
            senderId = senderId,
            senderName = getSenderName(),
            senderProfile = profile?.getSOSInfo() ?: ""
        )
    }

    /**
     * Get current GPS location
     */
    private fun getCurrentLocation(): Location? {
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "Location permission not granted")
            return null
        }

        try {
            // Try GPS first
            var location = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            
            // Fallback to network provider
            if (location == null) {
                location = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            }
            
            // Fallback to passive provider
            if (location == null) {
                location = locationManager.getLastKnownLocation(LocationManager.PASSIVE_PROVIDER)
            }
            
            if (location != null) {
                currentLocation = location
                Log.d(TAG, "Location obtained: ${location.latitude}, ${location.longitude}")
            } else {
                Log.w(TAG, "No location available")
            }
            
            return location
        } catch (e: Exception) {
            Log.e(TAG, "Error getting location", e)
            return null
        }
    }

    /**
     * Request location update
     */
    fun requestLocationUpdate() {
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        try {
            locationManager.requestSingleUpdate(
                LocationManager.GPS_PROVIDER,
                { location ->
                    currentLocation = location
                    Log.d(TAG, "Location updated: ${location.latitude}, ${location.longitude}")
                },
                null
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting location update", e)
        }
    }

    /**
     * Format message for display
     * @param isSent Whether this is a message sent by the current user
     */
    fun formatMessageForDisplay(message: MeshMessage, isSent: Boolean = false): String {
        val timestamp = java.text.SimpleDateFormat("HH:mm:ss", Locale.getDefault())
            .format(Date(message.timestamp))
        
        val location = message.getLocationString()
        
        // Use sender name if available, otherwise use senderId
        val senderDisplay = if (message.senderName.isNotBlank()) {
            message.senderName
        } else {
            message.senderId.take(8) // Show first 8 chars of UUID
        }
        
        val prefix = if (isSent) "📤 Sent" else ""
        
        return when (message.type) {
            MessageType.SOS -> {
                val profileInfo = if (message.senderProfile.isNotBlank()) {
                    "\n${message.senderProfile}"
                } else ""
                "$prefix🚨 SOS [$senderDisplay]\n$timestamp\n$location\n${message.content}$profileInfo"
            }
            MessageType.SAFE -> "$prefix✅ SAFE [$senderDisplay]\n$timestamp\n$location\n${message.content}"
            MessageType.VOICE -> "$prefix🎤 Voice [$senderDisplay]\n$timestamp\n$location\n(Tap to play)"
            MessageType.TEXT -> "$prefix[$senderDisplay]\n$timestamp\n$location\n${message.content}"
        }
    }
}
