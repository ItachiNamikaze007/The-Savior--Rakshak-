package com.emergency.mesh.handlers

import android.content.Context
import android.media.*
import android.util.Log
import java.io.*

/**
 * Handles voice message recording and playback
 * Manages audio capture with automatic cleanup
 */
class VoiceHandler(private val context: Context) {

    private var audioRecorder: AudioRecord? = null
    private var audioPlayer: AudioTrack? = null
    private var isRecording = false
    private var recordingThread: Thread? = null
    private var recordingCallback: ((ByteArray) -> Unit)? = null

    companion object {
        private const val TAG = "VoiceHandler"
        private const val SAMPLE_RATE = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        private const val MAX_RECORDING_DURATION_MS = 30000 // 30 seconds
        
        private fun getBufferSize(): Int {
            return AudioRecord.getMinBufferSize(
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT
            )
        }
    }

    /**
     * Start recording voice message
     */
    fun startRecording(onComplete: (ByteArray) -> Unit) {
        if (isRecording) {
            Log.w(TAG, "Already recording")
            return
        }

        recordingCallback = onComplete

        try {
            val bufferSize = getBufferSize()
            
            audioRecorder = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                bufferSize
            )
            
            if (audioRecorder?.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord not initialized")
                recordingCallback = null
                return
            }
            
            audioRecorder?.startRecording()
            isRecording = true
            
            Log.d(TAG, "Recording started")
            
            recordingThread = Thread {
                recordAudio(bufferSize)
            }
            recordingThread?.start()
            
            // Auto-stop after max duration
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                if (isRecording) {
                    Log.d(TAG, "Auto-stopping recording after max duration")
                    stopRecording()
                }
            }, MAX_RECORDING_DURATION_MS.toLong())
            
        } catch (e: SecurityException) {
            Log.e(TAG, "No permission to record audio", e)
            isRecording = false
            recordingCallback = null
        } catch (e: Exception) {
            Log.e(TAG, "Error starting recording", e)
            isRecording = false
            recordingCallback = null
        }
    }

    /**
     * Record audio data
     */
    private fun recordAudio(bufferSize: Int) {
        val buffer = ByteArray(bufferSize)
        val outputStream = ByteArrayOutputStream()
        
        try {
            while (isRecording) {
                val readBytes = audioRecorder?.read(buffer, 0, bufferSize) ?: 0
                
                if (readBytes > 0) {
                    outputStream.write(buffer, 0, readBytes)
                }
            }
            
            val audioData = outputStream.toByteArray()
            Log.d(TAG, "Recording completed: ${audioData.size} bytes")
            
            // Callback with audio data on main thread
            val callback = recordingCallback
            if (callback != null && audioData.isNotEmpty()) {
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    callback(audioData)
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error recording audio", e)
        } finally {
            outputStream.close()
        }
    }

    /**
     * Stop recording
     */
    fun stopRecording() {
        if (!isRecording) return
        
        Log.d(TAG, "Stopping recording...")
        isRecording = false
        
        try {
            // Give the recording thread a moment to finish
            Thread.sleep(100)
            
            audioRecorder?.stop()
            audioRecorder?.release()
            audioRecorder = null
            
            recordingThread?.join(2000)
            recordingThread = null
            
            Log.d(TAG, "Recording stopped successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recording", e)
        } finally {
            recordingCallback = null
        }
    }

    /**
     * Play audio data
     */
    fun playAudio(audioData: ByteArray) {
        Thread {
            try {
                val bufferSize = AudioTrack.getMinBufferSize(
                    SAMPLE_RATE,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AUDIO_FORMAT
                )
                
                audioPlayer = AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AUDIO_FORMAT)
                            .setSampleRate(SAMPLE_RATE)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(bufferSize)
                    .build()
                
                audioPlayer?.play()
                audioPlayer?.write(audioData, 0, audioData.size)
                
                // Wait for playback to complete
                Thread.sleep((audioData.size * 1000L) / (SAMPLE_RATE * 2))
                
                audioPlayer?.stop()
                audioPlayer?.release()
                audioPlayer = null
                
                Log.d(TAG, "Playback completed")
                
            } catch (e: Exception) {
                Log.e(TAG, "Error playing audio", e)
            }
        }.start()
    }

    /**
     * Clean up resources
     */
    fun cleanup() {
        stopRecording()
        
        try {
            audioPlayer?.stop()
            audioPlayer?.release()
            audioPlayer = null
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning up audio player", e)
        }
    }

    /**
     * Check if currently recording
     */
    fun isRecording(): Boolean = isRecording
}
