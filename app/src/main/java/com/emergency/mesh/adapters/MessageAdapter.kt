package com.emergency.mesh.adapters

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.emergency.mesh.R
import com.emergency.mesh.models.MeshMessage
import com.emergency.mesh.models.MessageType
import java.text.SimpleDateFormat
import java.util.*

/**
 * Data class to hold message with sent/received status
 */
data class MessageItem(
    val message: MeshMessage,
    val isSent: Boolean
)

/**
 * RecyclerView adapter for WhatsApp-style chat messages
 */
class MessageAdapter(
    private val context: Context,
    private val onVoiceMessageClick: (MeshMessage) -> Unit,
    private val onSenderClick: (MeshMessage) -> Unit
) : RecyclerView.Adapter<MessageAdapter.MessageViewHolder>() {

    private val messages = mutableListOf<MessageItem>()
    private val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())

    class MessageViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val bubbleContainer: LinearLayout = view.findViewById(R.id.bubbleContainer)
        val tvMessageType: TextView = view.findViewById(R.id.tvMessageType)
        val tvSender: TextView = view.findViewById(R.id.tvSender)
        val tvContent: TextView = view.findViewById(R.id.tvContent)
        val voiceContainer: LinearLayout = view.findViewById(R.id.voiceContainer)
        val ivPlayPause: ImageView = view.findViewById(R.id.ivPlayPause)
        val tvVoiceDuration: TextView = view.findViewById(R.id.tvVoiceDuration)
        val tvLocation: TextView = view.findViewById(R.id.tvLocation)
        val tvTime: TextView = view.findViewById(R.id.tvTime)
        val tvHops: TextView = view.findViewById(R.id.tvHops)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MessageViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_message, parent, false)
        return MessageViewHolder(view)
    }

    override fun onBindViewHolder(holder: MessageViewHolder, position: Int) {
        val item = messages[position]
        val message = item.message
        val isSent = item.isSent

        // Set alignment based on sent/received
        val layoutParams = holder.bubbleContainer.layoutParams as FrameLayout.LayoutParams
        if (isSent) {
            layoutParams.gravity = Gravity.END
            holder.bubbleContainer.background = ContextCompat.getDrawable(context, R.drawable.bubble_sent)
        } else {
            layoutParams.gravity = Gravity.START
            holder.bubbleContainer.background = ContextCompat.getDrawable(context, R.drawable.bubble_received)
        }
        holder.bubbleContainer.layoutParams = layoutParams

        // Handle different message types
        when (message.type) {
            MessageType.SOS -> {
                holder.tvMessageType.visibility = View.VISIBLE
                holder.tvMessageType.text = "🚨 EMERGENCY SOS"
                holder.bubbleContainer.background = ContextCompat.getDrawable(context, R.drawable.bubble_sos)
                holder.tvContent.visibility = View.VISIBLE
                holder.tvContent.text = message.content
                holder.voiceContainer.visibility = View.GONE
            }
            MessageType.SAFE -> {
                holder.tvMessageType.visibility = View.VISIBLE
                holder.tvMessageType.text = "✅ SAFE"
                holder.bubbleContainer.background = ContextCompat.getDrawable(context, R.drawable.bubble_safe)
                holder.tvContent.visibility = View.VISIBLE
                holder.tvContent.text = message.content
                holder.voiceContainer.visibility = View.GONE
            }
            MessageType.VOICE -> {
                holder.tvMessageType.visibility = View.GONE
                holder.tvContent.visibility = View.GONE
                holder.voiceContainer.visibility = View.VISIBLE
                
                // Calculate duration (rough estimate from audio data size)
                val durationSecs = if (message.audioData != null) {
                    (message.audioData.size / 16000).coerceAtLeast(1) // Rough estimate
                } else 0
                holder.tvVoiceDuration.text = String.format("%d:%02d", durationSecs / 60, durationSecs % 60)
                
                // Voice bubble has special background
                if (!isSent) {
                    holder.bubbleContainer.background = ContextCompat.getDrawable(context, R.drawable.bubble_voice)
                }
                
                // Click to play
                holder.voiceContainer.setOnClickListener {
                    if (message.audioData != null) {
                        onVoiceMessageClick(message)
                    } else {
                        Toast.makeText(context, "Voice data not available", Toast.LENGTH_SHORT).show()
                    }
                }
                holder.ivPlayPause.setOnClickListener {
                    if (message.audioData != null) {
                        onVoiceMessageClick(message)
                    }
                }
            }
            MessageType.TEXT -> {
                holder.tvMessageType.visibility = View.GONE
                holder.tvContent.visibility = View.VISIBLE
                holder.tvContent.text = message.content
                holder.voiceContainer.visibility = View.GONE
            }
        }

        // Sender name
        val senderName = if (isSent) {
            "You"
        } else if (message.senderName.isNotBlank()) {
            message.senderName
        } else {
            message.senderId.take(8)
        }
        holder.tvSender.text = senderName
        holder.tvSender.visibility = if (isSent) View.GONE else View.VISIBLE
        
        if (!isSent) {
            holder.tvSender.setOnClickListener {
                onSenderClick(message)
            }
        }

        // Location - clickable to open Google Maps
        if (message.latitude != null && message.longitude != null) {
            holder.tvLocation.visibility = View.VISIBLE
            holder.tvLocation.text = "📍 ${String.format("%.4f", message.latitude)}, ${String.format("%.4f", message.longitude)}"
            
            holder.tvLocation.setOnClickListener {
                openInGoogleMaps(message.latitude, message.longitude, senderName)
            }
        } else {
            holder.tvLocation.visibility = View.GONE
        }

        // Time
        holder.tvTime.text = timeFormat.format(Date(message.timestamp))

        // Hops (only show for received messages with hops > 0)
        if (!isSent && message.hops > 0) {
            holder.tvHops.visibility = View.VISIBLE
            holder.tvHops.text = "• ${message.hops} hop${if (message.hops > 1) "s" else ""}"
        } else {
            holder.tvHops.visibility = View.GONE
        }
    }

    override fun getItemCount(): Int = messages.size

    /**
     * Add a new message to the list (at the end for chronological order)
     */
    fun addMessage(message: MeshMessage, isSent: Boolean) {
        messages.add(MessageItem(message, isSent))
        notifyItemInserted(messages.size - 1)
    }

    /**
     * Add a new message item to the list
     */
    fun addMessage(item: MessageItem) {
        messages.add(item)
        notifyItemInserted(messages.size - 1)
    }

    /**
     * Clear all messages
     */
    fun clearMessages() {
        val size = messages.size
        messages.clear()
        notifyItemRangeRemoved(0, size)
    }

    /**
     * Get message at position
     */
    fun getMessageAt(position: Int): MessageItem? {
        return if (position in messages.indices) messages[position] else null
    }

    /**
     * Get total message count
     */
    fun getMessageCount(): Int = messages.size

    /**
     * Remove oldest messages if over limit
     */
    fun trimToSize(maxSize: Int) {
        while (messages.size > maxSize) {
            messages.removeAt(0)
            notifyItemRemoved(0)
        }
    }

    /**
     * Open location in Google Maps for navigation
     */
    private fun openInGoogleMaps(latitude: Double, longitude: Double, label: String) {
        try {
            // URI format: geo:lat,lon?q=lat,lon(label)
            val uri = Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude($label)")
            val mapIntent = Intent(Intent.ACTION_VIEW, uri)
            mapIntent.setPackage("com.google.android.apps.maps")
            
            if (mapIntent.resolveActivity(context.packageManager) != null) {
                context.startActivity(mapIntent)
            } else {
                // Fallback to browser if Google Maps not installed
                val browserUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude")
                val browserIntent = Intent(Intent.ACTION_VIEW, browserUri)
                context.startActivity(browserIntent)
            }
        } catch (e: Exception) {
            Toast.makeText(context, "Could not open maps", Toast.LENGTH_SHORT).show()
        }
    }
}
