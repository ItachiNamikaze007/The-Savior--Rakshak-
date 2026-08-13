package com.emergency.mesh.models

/**
 * Represents a peer in the mesh network
 */
data class MeshPeer(
    val deviceId: String,
    val deviceName: String,
    val connectionType: ConnectionType,
    val lastSeen: Long = System.currentTimeMillis(),
    val signalStrength: Int = 0
) {
    
    enum class ConnectionType {
        BLUETOOTH_LE,
        WIFI_DIRECT
    }

    /**
     * Check if peer is still active (seen within timeout)
     */
    fun isActive(): Boolean {
        return System.currentTimeMillis() - lastSeen < PEER_TIMEOUT_MS
    }

    companion object {
        const val PEER_TIMEOUT_MS = 60_000L // 1 minute
    }
}
