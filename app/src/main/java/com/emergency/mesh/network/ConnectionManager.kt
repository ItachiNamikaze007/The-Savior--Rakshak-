package com.emergency.mesh.network

import android.content.Context
import android.util.Log
import com.emergency.mesh.models.MeshMessage
import com.emergency.mesh.models.MeshPeer
import com.emergency.mesh.models.UserRole
import java.io.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Unified connection manager that handles BLE mesh networking
 * Coordinates message routing and peer discovery
 */
class ConnectionManager(private val context: Context) {

    private val bleManager = BLEManager(context)
    
    private val activePeers = ConcurrentHashMap<String, MeshPeer>()
    private val seenMessages = ConcurrentHashMap<String, Long>()
    
    // Message queue for storing messages when no peers connected
    private val pendingMessages = ConcurrentLinkedQueue<MeshMessage>()
    
    private val messageCallbacks = CopyOnWriteArrayList<(MeshMessage) -> Unit>()
    private val peerCallbacks = CopyOnWriteArrayList<(List<MeshPeer>) -> Unit>()
    
    // Current user role for display filtering
    var currentUserRole: UserRole = UserRole.CITIZEN

    companion object {
        private const val TAG = "ConnectionManager"
        private const val MESSAGE_CACHE_TIMEOUT = 300_000L // 5 minutes
        private const val PREF_PENDING_MESSAGES = "pending_messages"
        private const val KEY_QUEUE = "message_queue"
    }

    /**
     * Initialize network transports
     */
    fun initialize() {
        Log.d(TAG, "Initializing connection manager (BLE only)")
        
        // Load pending messages from storage
        loadPendingMessages()
        
        // Set up message callbacks
        bleManager.onMessageReceived { message ->
            handleReceivedMessage(message, "BLE")
        }
        
        // Set up peer callbacks
        bleManager.onPeerDiscovered { peer ->
            handlePeerDiscovered(peer)
        }
    }

    /**
     * Start discovering peers and advertising presence
     */
    fun startDiscovery() {
        Log.d(TAG, "Starting BLE peer discovery")
        
        // Start BLE advertising and scanning
        bleManager.startAdvertising()
        bleManager.startScanning()
    }

    /**
     * Stop discovery and advertising
     */
    fun stopDiscovery() {
        Log.d(TAG, "Stopping peer discovery")
        
        bleManager.stopAdvertising()
        bleManager.stopScanning()
    }

    /**
     * Set power mode for BLE operations
     * @param highRange true for maximum range (higher battery usage), false for power saving
     */
    fun setPowerMode(highRange: Boolean) {
        Log.d(TAG, "Setting power mode: ${if (highRange) "High Range" else "Power Saving"}")
        bleManager.setPowerMode(highRange)
    }
    /**
     * Send message through BLE transport
     * Always attempts to send immediately, queues if no peers for retry
     */
    fun sendMessage(message: MeshMessage) {
        Log.d(TAG, "Sending message: ${message.type} from ${message.senderId}")
        
        // Mark message as seen to prevent echo
        seenMessages[message.id] = System.currentTimeMillis()
        
        // Always try to send via BLE (it handles connections internally)
        bleManager.sendMessage(message)
        
        // Also queue the message in case we need to retry later
        val peers = getActivePeers()
        if (peers.isEmpty()) {
            Log.d(TAG, "No active peers, also queuing message: ${message.id}")
            pendingMessages.add(message)
            savePendingMessages()
        }
        
        // Clean up old message cache
        cleanupMessageCache()
    }

    /**
     * Handle received message from any transport
     */
    private fun handleReceivedMessage(message: MeshMessage, transport: String) {
        // Check if we've already seen this message
        if (seenMessages.containsKey(message.id)) {
            Log.d(TAG, "Ignoring duplicate message: ${message.id}")
            return
        }
        
        Log.d(TAG, "Received message via $transport: ${message.type}, hops: ${message.hops}")
        
        // Mark as seen
        seenMessages[message.id] = System.currentTimeMillis()
        
        // Check if message should be displayed for current user role
        if (message.shouldDisplayForRole(currentUserRole)) {
            // Notify listeners (UI will display)
            messageCallbacks.forEach { callback ->
                callback(message)
            }
        } else {
            Log.d(TAG, "Message not displayed for role $currentUserRole (hops: ${message.hops})")
        }
        
        // Always relay message regardless of hop count (unlimited relay)
        relayMessage(message)
    }

    /**
     * Relay message to other peers
     */
    private fun relayMessage(message: MeshMessage) {
        // No hop limit check - always relay
        val relayedMessage = message.relay()
        
        // Small delay to avoid network congestion
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            bleManager.sendMessage(relayedMessage)
        }, 1000)
    }

    /**
     * Handle discovered peer
     */
    private fun handlePeerDiscovered(peer: MeshPeer) {
        val updatedPeer = peer.copy(lastSeen = System.currentTimeMillis())
        activePeers[peer.deviceId] = updatedPeer
        Log.d(TAG, "Peer discovered: ${peer.deviceName} via ${peer.connectionType}")
        
        // Flush pending messages when peer is discovered
        flushMessageQueue()
        
        // Notify listeners with updated peer list
        peerCallbacks.forEach { callback ->
            callback(getActivePeers())
        }
    }

    /**
     * Get list of active peers
     */
    fun getActivePeers(): List<MeshPeer> {
        // Remove inactive peers
        activePeers.entries.removeAll { (_, peer) ->
            !peer.isActive()
        }
        
        return activePeers.values.toList()
    }

    /**
     * Register callback for received messages
     */
    fun onMessageReceived(callback: (MeshMessage) -> Unit) {
        messageCallbacks.add(callback)
    }

    /**
     * Register callback for peer list updates
     */
    fun onPeersUpdated(callback: (List<MeshPeer>) -> Unit) {
        peerCallbacks.add(callback)
    }

    /**
     * Clean up old messages from cache
     */
    private fun cleanupMessageCache() {
        val now = System.currentTimeMillis()
        seenMessages.entries.removeAll { (_, timestamp) ->
            now - timestamp > MESSAGE_CACHE_TIMEOUT
        }
    }

    /**
     * Flush pending messages when peers become available
     */
    private fun flushMessageQueue() {
        if (pendingMessages.isEmpty()) return
        
        val peers = getActivePeers()
        if (peers.isEmpty()) return
        
        Log.d(TAG, "Flushing ${pendingMessages.size} pending messages")
        
        while (pendingMessages.isNotEmpty()) {
            val message = pendingMessages.poll() ?: break
            bleManager.sendMessage(message)
        }
        
        // Clear persisted queue
        savePendingMessages()
    }

    /**
     * Save pending messages to SharedPreferences
     */
    private fun savePendingMessages() {
        try {
            val prefs = context.getSharedPreferences(PREF_PENDING_MESSAGES, Context.MODE_PRIVATE)
            
            // Convert queue to list for serialization (exclude voice messages due to size)
            val messagesToSave = pendingMessages.filter { it.audioData == null }.toList()
            
            // Serialize using ObjectOutputStream to handle ByteArray properly
            val baos = ByteArrayOutputStream()
            ObjectOutputStream(baos).use { oos ->
                oos.writeObject(ArrayList(messagesToSave))
            }
            val encoded = android.util.Base64.encodeToString(baos.toByteArray(), android.util.Base64.DEFAULT)
            
            prefs.edit().putString(KEY_QUEUE, encoded).apply()
            Log.d(TAG, "Saved ${messagesToSave.size} pending messages")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving pending messages", e)
        }
    }

    /**
     * Load pending messages from SharedPreferences
     */
    private fun loadPendingMessages() {
        try {
            val prefs = context.getSharedPreferences(PREF_PENDING_MESSAGES, Context.MODE_PRIVATE)
            val encoded = prefs.getString(KEY_QUEUE, null) ?: return
            
            val bytes = android.util.Base64.decode(encoded, android.util.Base64.DEFAULT)
            val bais = ByteArrayInputStream(bytes)
            ObjectInputStream(bais).use { ois ->
                @Suppress("UNCHECKED_CAST")
                val messages = ois.readObject() as? ArrayList<MeshMessage>
                messages?.forEach { pendingMessages.add(it) }
                Log.d(TAG, "Loaded ${messages?.size ?: 0} pending messages")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading pending messages", e)
        }
    }

    /**
     * Get pending message count
     */
    fun getPendingMessageCount(): Int {
        return pendingMessages.size
    }

    /**
     * Clean up all resources
     */
    fun cleanup() {
        Log.d(TAG, "Cleaning up connection manager")
        
        // Save any remaining pending messages
        savePendingMessages()
        
        stopDiscovery()
        bleManager.cleanup()
        
        activePeers.clear()
        seenMessages.clear()
        messageCallbacks.clear()
        peerCallbacks.clear()
    }
}
