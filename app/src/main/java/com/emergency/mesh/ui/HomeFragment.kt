package com.emergency.mesh.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.emergency.mesh.MainActivity
import com.emergency.mesh.R
import com.emergency.mesh.models.MeshMessage
import com.emergency.mesh.models.MeshPeer
import com.emergency.mesh.models.MessageType
import com.google.android.material.button.MaterialButton
import com.google.android.material.switchmaterial.SwitchMaterial

/**
 * Home screen fragment with SOS, Safe status, and quick actions
 */
class HomeFragment : Fragment() {

    private lateinit var mainActivity: MainActivity
    
    // Views
    private lateinit var tvStatus: TextView
    private lateinit var tvPeerCount: TextView
    private lateinit var tvPowerMode: TextView
    private lateinit var tvSafeStatus: TextView
    private lateinit var switchPowerMode: SwitchMaterial
    private lateinit var btnSOS: MaterialButton
    private lateinit var btnSafe: MaterialButton
    private lateinit var btnNeedHelp: MaterialButton
    private lateinit var btnNeedWater: MaterialButton
    private lateinit var btnNeedMedical: MaterialButton
    private lateinit var btnNeedShelter: MaterialButton
    private lateinit var statusIndicator: View
    
    private val peerCallback: (List<MeshPeer>) -> Unit = { peers ->
        updatePeerCount(peers.size)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_home, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        mainActivity = requireActivity() as MainActivity
        
        initViews(view)
        setupListeners()
        updateSafeStatus()
    }

    override fun onResume() {
        super.onResume()
        mainActivity.registerPeerCallback(peerCallback)
    }

    override fun onPause() {
        super.onPause()
        mainActivity.unregisterPeerCallback(peerCallback)
    }

    private fun initViews(view: View) {
        tvStatus = view.findViewById(R.id.tvStatus)
        tvPeerCount = view.findViewById(R.id.tvPeerCount)
        tvPowerMode = view.findViewById(R.id.tvPowerMode)
        tvSafeStatus = view.findViewById(R.id.tvSafeStatus)
        switchPowerMode = view.findViewById(R.id.switchPowerMode)
        btnSOS = view.findViewById(R.id.btnSOS)
        btnSafe = view.findViewById(R.id.btnSafe)
        btnNeedHelp = view.findViewById(R.id.btnNeedHelp)
        btnNeedWater = view.findViewById(R.id.btnNeedWater)
        btnNeedMedical = view.findViewById(R.id.btnNeedMedical)
        btnNeedShelter = view.findViewById(R.id.btnNeedShelter)
        statusIndicator = view.findViewById(R.id.statusIndicator)
    }

    private fun setupListeners() {
        // Power mode toggle
        switchPowerMode.setOnCheckedChangeListener { _, isChecked ->
            mainActivity.setPowerMode(isChecked)
            tvPowerMode.text = if (isChecked) {
                getString(R.string.high_range_mode)
            } else {
                getString(R.string.power_saving_mode)
            }
        }
        
        // SOS button
        btnSOS.setOnClickListener {
            sendSOS()
        }
        
        // Safe status button
        btnSafe.setOnClickListener {
            sendSafeStatus()
        }
        
        // Quick message buttons
        btnNeedHelp.setOnClickListener {
            sendQuickMessage(getString(R.string.need_help))
        }
        
        btnNeedWater.setOnClickListener {
            sendQuickMessage(getString(R.string.need_water))
        }
        
        btnNeedMedical.setOnClickListener {
            sendQuickMessage(getString(R.string.need_medical))
        }
        
        btnNeedShelter.setOnClickListener {
            sendQuickMessage(getString(R.string.need_shelter))
        }
    }

    private fun sendSOS() {
        val message = mainActivity.messageHandler.createSOSMessage(mainActivity.deviceId)
        mainActivity.sendMessage(message)
        
        Toast.makeText(context, R.string.sos_sent, Toast.LENGTH_SHORT).show()
        
        // Visual feedback - pulse effect
        btnSOS.animate()
            .scaleX(0.95f)
            .scaleY(0.95f)
            .setDuration(100)
            .withEndAction {
                btnSOS.animate()
                    .scaleX(1f)
                    .scaleY(1f)
                    .setDuration(100)
                    .start()
            }
            .start()
    }

    private fun sendSafeStatus() {
        val isSafe = !mainActivity.isSafe()
        mainActivity.setSafeStatus(isSafe)
        
        // Create and send safe status message
        val message = mainActivity.messageHandler.createSafeMessage(mainActivity.deviceId, isSafe)
        mainActivity.sendMessage(message)
        
        updateSafeStatus()
        Toast.makeText(context, R.string.safe_status_sent, Toast.LENGTH_SHORT).show()
    }

    private fun updateSafeStatus() {
        if (mainActivity.isSafe()) {
            tvSafeStatus.text = getString(R.string.status_safe)
            btnSafe.text = "✓ " + getString(R.string.i_am_safe)
        } else {
            tvSafeStatus.text = getString(R.string.safe_description)
            btnSafe.text = getString(R.string.i_am_safe)
        }
    }

    private fun sendQuickMessage(content: String) {
        val message = mainActivity.messageHandler.createTextMessage(content, mainActivity.deviceId)
        mainActivity.sendMessage(message)
        
        Toast.makeText(context, R.string.message_sent, Toast.LENGTH_SHORT).show()
    }

    private fun updatePeerCount(count: Int) {
        if (count > 0) {
            val safeCount = mainActivity.getSafePeerCount()
            tvPeerCount.text = getString(R.string.peers_connected_safe, count, safeCount)
            tvStatus.text = getString(R.string.network_status)
            statusIndicator.setBackgroundResource(R.drawable.bg_status_online)
        } else {
            tvPeerCount.text = getString(R.string.no_peers)
            tvStatus.text = getString(R.string.network_status)
            statusIndicator.setBackgroundResource(R.drawable.bg_status_offline)
        }
    }
}
