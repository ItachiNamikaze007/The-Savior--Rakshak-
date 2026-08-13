package com.emergency.mesh.models

import java.io.Serializable

/**
 * Types of messages supported by the mesh network
 */
enum class MessageType {
    TEXT,
    VOICE,
    SOS,
    SAFE
}

/**
 * Represents a message in the emergency mesh network
 */
data class MeshMessage(
    val id: String,
    val type: MessageType,
    val content: String,
    val latitude: Double?,
    val longitude: Double?,
    val timestamp: Long,
    val senderId: String,
    val senderName: String = "",
    val senderProfile: String = "", // Serialized UserProfile info for SOS
    val hops: Int = 0,
    val audioData: ByteArray? = null
) : Serializable {

    companion object {
        private const val serialVersionUID = 2L // Version 2 with senderName/senderProfile
        const val DISPLAY_MAX_HOPS = 5 // Max hops for citizen visibility
    }

    /**
     * Get formatted location string
     */
    fun getLocationString(): String {
        return if (latitude != null && longitude != null) {
            "Lat: %.6f, Lon: %.6f".format(latitude, longitude)
        } else {
            "Location not available"
        }
    }

    /**
     * Create a copy with incremented hop count for relaying
     */
    fun relay(): MeshMessage {
        return copy(hops = hops + 1)
    }

    /**
     * Check if message should be displayed based on user role
     * - Citizens only see messages within 5 hops
     * - Officials see all messages regardless of hop count
     */
    fun shouldDisplayForRole(role: UserRole): Boolean {
        return hops <= DISPLAY_MAX_HOPS || role == UserRole.OFFICIAL
    }

    /**
     * Messages are always relayed (no hop limit for relay)
     * Returning false means this message should still be relayed
     */
    fun hasExceededMaxHops(): Boolean {
        // Always return false - unlimited relay
        return false
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as MeshMessage

        if (id != other.id) return false

        return true
    }

    override fun hashCode(): Int {
        return id.hashCode()
    }
}
