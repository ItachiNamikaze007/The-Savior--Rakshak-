package com.emergency.mesh.ui

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.emergency.mesh.MainActivity
import com.emergency.mesh.R
import com.emergency.mesh.adapters.MessageAdapter
import com.emergency.mesh.adapters.MessageItem
import com.emergency.mesh.models.MeshMessage
import com.emergency.mesh.models.MeshPeer
import com.emergency.mesh.models.MessageType
import com.google.android.material.floatingactionbutton.FloatingActionButton
import java.io.ByteArrayOutputStream

/**
 * Chat screen fragment with message list and input
 */
class ChatFragment : Fragment() {

    private lateinit var mainActivity: MainActivity
    
    // Views
    private lateinit var tvPeerInfo: TextView
    private lateinit var rvMessages: RecyclerView
    private lateinit var emptyState: LinearLayout
    private lateinit var etMessage: EditText
    private lateinit var btnSend: FloatingActionButton
    private lateinit var btnVoice: FloatingActionButton
    
    private lateinit var messageAdapter: MessageAdapter
    
    // Voice recording
    private var isRecording = false
    private var audioRecord: AudioRecord? = null
    private var recordingThread: Thread? = null
    private var audioData: ByteArrayOutputStream? = null
    
    private val messageCallback: (MeshMessage) -> Unit = { message ->
        addMessage(message, false)
    }
    
    private val peerCallback: (List<MeshPeer>) -> Unit = { peers ->
        updatePeerInfo(peers.size)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_chat, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        mainActivity = requireActivity() as MainActivity
        
        initViews(view)
        setupRecyclerView()
        setupListeners()
        
        // Load message history
        loadMessageHistory()
    }

    private fun loadMessageHistory() {
        val history = mainActivity.getMessageHistory()
        if (history.isNotEmpty()) {
            messageAdapter.clearMessages()
            history.forEach { message ->
                val isSent = message.senderId == mainActivity.deviceId
                messageAdapter.addMessage(message, isSent)
            }
            rvMessages.scrollToPosition(messageAdapter.itemCount - 1)
            updateEmptyState()
        }
    }

    override fun onResume() {
        super.onResume()
        mainActivity.registerMessageCallback(messageCallback)
        mainActivity.registerPeerCallback(peerCallback)
    }

    override fun onPause() {
        super.onPause()
        mainActivity.unregisterMessageCallback(messageCallback)
        mainActivity.unregisterPeerCallback(peerCallback)
        stopRecording()
    }

    private fun initViews(view: View) {
        tvPeerInfo = view.findViewById(R.id.tvPeerInfo)
        rvMessages = view.findViewById(R.id.rvMessages)
        emptyState = view.findViewById(R.id.emptyState)
        etMessage = view.findViewById(R.id.etMessage)
        btnSend = view.findViewById(R.id.btnSend)
        btnVoice = view.findViewById(R.id.btnVoice)
    }

    private fun setupRecyclerView() {
        messageAdapter = MessageAdapter(
            requireContext(),
            { message -> playVoiceMessage(message) },
            { message -> showSenderProfile(message) }
        )
        
        rvMessages.apply {
            layoutManager = LinearLayoutManager(context).apply {
                stackFromEnd = true
            }
            adapter = messageAdapter
        }
        
        updateEmptyState()
    }

    private fun showSenderProfile(message: MeshMessage) {
        if (message.senderProfile.isBlank()) {
            Toast.makeText(context, "No profile information available", Toast.LENGTH_SHORT).show()
            return
        }
        
        androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("Sender Profile")
            .setMessage(message.senderProfile)
            .setPositiveButton(android.R.string.ok, null)
            .show()
    }

    private fun setupListeners() {
        btnSend.setOnClickListener {
            sendTextMessage()
        }
        
        btnVoice.setOnClickListener {
            toggleVoiceRecording()
        }
    }

    private fun sendTextMessage() {
        val content = etMessage.text.toString().trim()
        
        if (content.isEmpty()) {
            return
        }
        
        val message = mainActivity.messageHandler.createTextMessage(content, mainActivity.deviceId)
        mainActivity.sendMessage(message)
        addMessage(message, true)
        
        etMessage.text.clear()
    }

    private fun toggleVoiceRecording() {
        if (isRecording) {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private fun startRecording() {
        try {
            val sampleRate = 16000
            val channelConfig = AudioFormat.CHANNEL_IN_MONO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
            val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
            
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                channelConfig,
                audioFormat,
                bufferSize
            )
            
            audioData = ByteArrayOutputStream()
            
            audioRecord?.startRecording()
            isRecording = true
            
            // Update UI
            btnVoice.setImageResource(R.drawable.ic_send)
            Toast.makeText(context, R.string.recording_started, Toast.LENGTH_SHORT).show()
            
            // Start recording thread with 30 second limit
            val startTime = System.currentTimeMillis()
            
            recordingThread = Thread {
                val buffer = ByteArray(1024)
                while (isRecording && (System.currentTimeMillis() - startTime) < 30000) {
                    val bytesRead = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (bytesRead > 0) {
                        audioData?.write(buffer, 0, bytesRead)
                    }
                }
                
                // Auto-stop after 30 seconds
                if (isRecording) {
                    activity?.runOnUiThread {
                        stopRecording()
                    }
                }
            }
            recordingThread?.start()
            
        } catch (e: SecurityException) {
            Toast.makeText(context, R.string.microphone_permission_required, Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            Toast.makeText(context, "Recording failed: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun stopRecording() {
        if (!isRecording) return
        
        isRecording = false
        
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        
        recordingThread = null
        
        // Update UI
        btnVoice.setImageResource(R.drawable.ic_mic)
        
        // Send voice message if we have data
        val data = audioData?.toByteArray()
        audioData = null
        
        if (data != null && data.isNotEmpty()) {
            val message = mainActivity.messageHandler.createVoiceMessage(data, mainActivity.deviceId)
            mainActivity.sendMessage(message)
            addMessage(message, true)
            
            Toast.makeText(context, R.string.voice_message_sent, Toast.LENGTH_SHORT).show()
        }
    }

    private fun playVoiceMessage(message: MeshMessage) {
        message.audioData?.let { data ->
            mainActivity.voiceHandler.playAudio(data)
        }
    }

    private fun addMessage(message: MeshMessage, isSent: Boolean) {
        messageAdapter.addMessage(MessageItem(message, isSent))
        rvMessages.scrollToPosition(messageAdapter.itemCount - 1)
        updateEmptyState()
    }

    private fun updateEmptyState() {
        if (messageAdapter.itemCount == 0) {
            emptyState.visibility = View.VISIBLE
            rvMessages.visibility = View.GONE
        } else {
            emptyState.visibility = View.GONE
            rvMessages.visibility = View.VISIBLE
        }
    }

    private fun updatePeerInfo(count: Int) {
        tvPeerInfo.text = if (count > 0) {
            resources.getQuantityString(R.plurals.peers_count, count, count)
        } else {
            getString(R.string.no_peers)
        }
    }
}
