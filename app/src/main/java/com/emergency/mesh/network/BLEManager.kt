package com.emergency.mesh.network

import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.os.ParcelUuid
import android.util.Log
import com.emergency.mesh.models.MeshMessage
import com.emergency.mesh.models.MeshPeer
import java.io.*
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * Manages Bluetooth Low Energy connections for mesh networking
 * Handles discovery, advertising, and message transmission via BLE
 */
class BLEManager(private val context: Context) {

    private val bluetoothManager: BluetoothManager = 
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager.adapter
    
    private var bleAdvertiser: BluetoothLeAdvertiser? = null
    private var bleScanner: BluetoothLeScanner? = null
    private var gattServer: BluetoothGattServer? = null
    
    private val connectedDevices = ConcurrentHashMap<String, BluetoothDevice>()
    private val gattClients = ConcurrentHashMap<String, BluetoothGatt>()
    private val messageCallbacks = java.util.concurrent.CopyOnWriteArrayList<(MeshMessage) -> Unit>()
    private val peerCallbacks = java.util.concurrent.CopyOnWriteArrayList<(MeshPeer) -> Unit>()
    
    // New properties for reliable data transfer
    private val writeQueues = ConcurrentHashMap<String, ConcurrentLinkedQueue<ByteArray>>()
    private val isWriting = ConcurrentHashMap<String, Boolean>()
    private val deviceMtu = ConcurrentHashMap<String, Int>()
    private val incomingBuffers = ConcurrentHashMap<String, ByteArrayOutputStream>()
    private val deviceReady = ConcurrentHashMap<String, Boolean>()

    private var isAdvertising = false
    private var isScanning = false
    
    // Power mode: true = high range, false = power saving
    private var highRangeMode = true

    companion object {
        private const val TAG = "BLEManager"
        
        // Service UUID for emergency mesh
        val SERVICE_UUID: UUID = UUID.fromString("00001234-0000-1000-8000-00805f9b34fb")
        
        // Characteristic for message exchange
        val MESSAGE_CHARACTERISTIC_UUID: UUID = UUID.fromString("00001235-0000-1000-8000-00805f9b34fb")
        
        // Scan settings
        private const val SCAN_DURATION_MS = 10_000L
        private const val SCAN_INTERVAL_MS = 30_000L
        private const val ADVERTISE_DURATION_MS = 10_000L
        private const val ADVERTISE_INTERVAL_MS = 30_000L
    }

    /**
     * Set power mode for BLE operations
     * @param highRange true for maximum range (higher battery usage), false for power saving
     */
    fun setPowerMode(highRange: Boolean) {
        if (highRangeMode == highRange) return
        
        highRangeMode = highRange
        Log.d(TAG, "Power mode changed to: ${if (highRange) "High Range" else "Power Saving"}")
        
        // Restart advertising and scanning with new settings
        if (isAdvertising) {
            stopAdvertising()
            startAdvertising()
        }
        if (isScanning) {
            stopScanning()
            startScanning()
        }
    }

    /**
     * Start BLE advertising to make device discoverable
     */
    fun startAdvertising() {
        if (!checkBluetoothEnabled()) return
        
        bleAdvertiser = bluetoothAdapter?.bluetoothLeAdvertiser
        if (bleAdvertiser == null) {
            Log.e(TAG, "BLE Advertiser not available")
            return
        }

        // Use different settings based on power mode
        val advertiseMode = if (highRangeMode) {
            AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY  // Maximum advertising frequency
        } else {
            AdvertiseSettings.ADVERTISE_MODE_LOW_POWER    // Battery saving
        }
        
        val txPowerLevel = if (highRangeMode) {
            AdvertiseSettings.ADVERTISE_TX_POWER_HIGH     // Maximum range
        } else {
            AdvertiseSettings.ADVERTISE_TX_POWER_LOW      // Battery saving
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(advertiseMode)
            .setConnectable(true)
            .setTimeout(0)
            .setTxPowerLevel(txPowerLevel)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()

        val scanResponse = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .build()

        try {
            bleAdvertiser?.startAdvertising(settings, data, scanResponse, advertiseCallback)
            isAdvertising = true
            Log.d(TAG, "BLE advertising started (${if (highRangeMode) "High Range" else "Power Saving"})")
            setupGattServer()
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception starting BLE advertising", e)
        }
    }

    /**
     * Stop BLE advertising
     */
    fun stopAdvertising() {
        try {
            if (isAdvertising) {
                bleAdvertiser?.stopAdvertising(advertiseCallback)
                isAdvertising = false
                Log.d(TAG, "BLE advertising stopped")
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception stopping advertising", e)
        }
    }

    /**
     * Start scanning for nearby BLE devices
     */
    fun startScanning() {
        if (!checkBluetoothEnabled()) return
        
        bleScanner = bluetoothAdapter?.bluetoothLeScanner
        if (bleScanner == null) {
            Log.e(TAG, "BLE Scanner not available")
            return
        }

        // Use different scan mode based on power settings
        val scanMode = if (highRangeMode) {
            ScanSettings.SCAN_MODE_LOW_LATENCY  // Scan more frequently for faster discovery
        } else {
            ScanSettings.SCAN_MODE_LOW_POWER    // Battery saving
        }

        val settings = ScanSettings.Builder()
            .setScanMode(scanMode)
            .build()

        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()

        try {
            bleScanner?.startScan(listOf(filter), settings, scanCallback)
            isScanning = true
            Log.d(TAG, "BLE scanning started (${if (highRangeMode) "High Range" else "Power Saving"})")
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception starting BLE scan", e)
        }
    }

    /**
     * Stop scanning for BLE devices
     */
    fun stopScanning() {
        try {
            if (isScanning) {
                bleScanner?.stopScan(scanCallback)
                isScanning = false
                Log.d(TAG, "BLE scanning stopped")
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception stopping scan", e)
        }
    }

    /**
     * Set up GATT server to handle incoming connections
     */
    private fun setupGattServer() {
        try {
            gattServer = bluetoothManager.openGattServer(context, gattServerCallback)
            
            val messageCharacteristic = BluetoothGattCharacteristic(
                MESSAGE_CHARACTERISTIC_UUID,
                BluetoothGattCharacteristic.PROPERTY_WRITE or 
                BluetoothGattCharacteristic.PROPERTY_READ or
                BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                BluetoothGattCharacteristic.PERMISSION_WRITE or 
                BluetoothGattCharacteristic.PERMISSION_READ
            )

            val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
            service.addCharacteristic(messageCharacteristic)
            
            gattServer?.addService(service)
            Log.d(TAG, "GATT server started")
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception setting up GATT server", e)
        }
    }

    /**
     * Send message to all connected devices
     */
    fun sendMessage(message: MeshMessage) {
        // Serialize message
        val rawData = serializeMessage(message)
        
        // Frame data with 4-byte total length prefix
        val buffer = java.nio.ByteBuffer.allocate(4 + rawData.size)
        buffer.putInt(rawData.size)
        buffer.put(rawData)
        val messageData = buffer.array()
        
        // Send to all connected devices
        connectedDevices.values.forEach { device ->
            sendToDevice(device, messageData)
        }
    }

    /**
     * Send data to specific device via GATT connection
     */
    private fun sendToDevice(device: BluetoothDevice, data: ByteArray) {
        try {
            val address = device.address
            
            // Determine chunk size (MTU - 3 bytes overhead)
            val mtu = deviceMtu[address] ?: 23
            val chunkSize = mtu - 3
            
            // Split data into chunks
            var offset = 0
            while (offset < data.size) {
                val length = Math.min(chunkSize, data.size - offset)
                val chunk = ByteArray(length)
                System.arraycopy(data, offset, chunk, 0, length)
                
                // Add to queue
                writeQueues.computeIfAbsent(address) { ConcurrentLinkedQueue() }.add(chunk)
                offset += length
            }

            // Check if we already have a GATT connection
            val existingGatt = gattClients[address]
            if (existingGatt != null) {
                if (deviceReady[address] == true) {
                    processWriteQueue(address)
                }
            } else {
                // Create new GATT connection
                device.connectGatt(context, false, gattClientCallback)
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception sending to device", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error sending to device", e)
        }
    }
    
    /**
     * Write data to GATT characteristic
     */
    private fun writeToGatt(gatt: BluetoothGatt, data: ByteArray) {
        try {
            val service = gatt.getService(SERVICE_UUID)
            val characteristic = service?.getCharacteristic(MESSAGE_CHARACTERISTIC_UUID)
            
            if (characteristic != null) {
                characteristic.value = data
                characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                val success = gatt.writeCharacteristic(characteristic)
                if (success) {
                    Log.d(TAG, "Initiated write of ${data.size} bytes via GATT")
                } else {
                    Log.e(TAG, "Failed to initiate write GATT characteristic")
                    isWriting[gatt.device.address] = false
                }
            } else {
                Log.e(TAG, "Message characteristic not found")
                isWriting[gatt.device.address] = false
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception writing to GATT", e)
            isWriting[gatt.device.address] = false
        }
    }

    /**
     * Register callback for received messages
     */
    fun onMessageReceived(callback: (MeshMessage) -> Unit) {
        messageCallbacks.add(callback)
    }

    /**
     * Register callback for discovered peers
     */
    fun onPeerDiscovered(callback: (MeshPeer) -> Unit) {
        peerCallbacks.add(callback)
    }

    /**
     * Serialize message to byte array
     */
    private fun serializeMessage(message: MeshMessage): ByteArray {
        val baos = ByteArrayOutputStream()
        val oos = ObjectOutputStream(baos)
        oos.writeObject(message)
        oos.flush()
        return baos.toByteArray()
    }

    /**
     * Deserialize message from byte array
     */
    private fun deserializeMessage(data: ByteArray): MeshMessage? {
        return try {
            val bais = ByteArrayInputStream(data)
            val ois = ObjectInputStream(bais)
            ois.readObject() as MeshMessage
        } catch (e: Exception) {
            Log.e(TAG, "Error deserializing message", e)
            null
        }
    }

    /**
     * Check if Bluetooth is enabled
     */
    private fun checkBluetoothEnabled(): Boolean {
        if (bluetoothAdapter == null) {
            Log.e(TAG, "Bluetooth not supported")
            return false
        }
        if (!bluetoothAdapter.isEnabled) {
            Log.e(TAG, "Bluetooth not enabled")
            return false
        }
        return true
    }

    /**
     * Process the write queue for a device
     */
    private fun processWriteQueue(address: String) {
        if (isWriting[address] == true) return

        val queue = writeQueues[address] ?: return
        val chunk = queue.peek()

        if (chunk != null) {
            val gatt = gattClients[address]
            if (gatt != null && deviceReady[address] == true) {
                isWriting[address] = true
                writeToGatt(gatt, chunk)
            }
        } else {
            isWriting[address] = false
        }
    }

    private val gattClientCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
            val deviceAddress = gatt?.device?.address ?: return
            
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                Log.d(TAG, "GATT connected to $deviceAddress")
                // Request higher MTU for faster transfer
                val mtuRequested = gatt?.requestMtu(512) ?: false
                if (!mtuRequested) {
                    gatt?.discoverServices()
                }
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                Log.d(TAG, "GATT disconnected from $deviceAddress")
                gattClients.remove(deviceAddress)
                deviceReady[deviceAddress] = false
                isWriting[deviceAddress] = false
                gatt?.close()
            }
        }

        @SuppressLint("MissingPermission")
        override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) {
            val deviceAddress = gatt?.device?.address ?: return
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG, "MTU changed to $mtu for $deviceAddress")
                deviceMtu[deviceAddress] = mtu
            }
            // Proceed to discover services
            gatt?.discoverServices()
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            val deviceAddress = gatt?.device?.address ?: return
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG, "Services discovered for $deviceAddress")
                gattClients[deviceAddress] = gatt!!
                deviceReady[deviceAddress] = true
                processWriteQueue(deviceAddress)
            }
        }

        override fun onCharacteristicWrite(gatt: BluetoothGatt?, characteristic: BluetoothGattCharacteristic?, status: Int) {
            val deviceAddress = gatt?.device?.address ?: return
            
            if (status == BluetoothGatt.GATT_SUCCESS) {
                // Remove the successfully written chunk
                writeQueues[deviceAddress]?.poll()
                isWriting[deviceAddress] = false
                // Process next chunk
                processWriteQueue(deviceAddress)
            } else {
                Log.e(TAG, "Failed to write characteristic to $deviceAddress, status: $status. Dropping chunk.")
                writeQueues[deviceAddress]?.poll()
                isWriting[deviceAddress] = false
                processWriteQueue(deviceAddress)
            }
        }
    }

    /**
     * Advertise callback
     */
    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            Log.d(TAG, "Advertising started successfully")
        }

        override fun onStartFailure(errorCode: Int) {
            Log.e(TAG, "Advertising failed with error: $errorCode")
        }
    }

    /**
     * Scan callback
     */
    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            result?.let {
                try {
                    val device = it.device
                    val deviceName = device.name ?: "Unknown"
                    val deviceId = device.address
                    
                    Log.d(TAG, "Found device: $deviceName ($deviceId)")
                    
                    // Notify peer discovered
                    val peer = MeshPeer(
                        deviceId = deviceId,
                        deviceName = deviceName,
                        connectionType = MeshPeer.ConnectionType.BLUETOOTH_LE,
                        signalStrength = it.rssi
                    )
                    peerCallbacks.forEach { callback -> callback(peer) }
                    
                    // Store device
                    connectedDevices[deviceId] = device

                    // Auto-connect GATT client if not already connected
                    if (!gattClients.containsKey(deviceId)) {
                        try {
                            device.connectGatt(context, false, gattClientCallback)
                        } catch (e: SecurityException) {
                            Log.e(TAG, "Error auto-connecting GATT client", e)
                        }
                    }
                } catch (e: SecurityException) {
                    Log.e(TAG, "Security exception in scan callback", e)
                }
            }
        }

        override fun onScanFailed(errorCode: Int) {
            Log.e(TAG, "Scan failed with error: $errorCode")
        }
    }

    /**
     * GATT server callback
     */
    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice?, status: Int, newState: Int) {
            try {
                device?.let {
                    if (newState == BluetoothProfile.STATE_CONNECTED) {
                        Log.d(TAG, "Device connected to GATT server: ${it.address}")
                        connectedDevices[it.address] = it

                        val deviceName = try { it.name ?: "Unknown" } catch (e: SecurityException) { "Unknown" }
                        val peer = MeshPeer(
                            deviceId = it.address,
                            deviceName = deviceName,
                            connectionType = MeshPeer.ConnectionType.BLUETOOTH_LE
                        )
                        peerCallbacks.forEach { callback -> callback(peer) }
                    } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                        Log.d(TAG, "Device disconnected from GATT server: ${it.address}")
                        connectedDevices.remove(it.address)
                        incomingBuffers.remove(it.address)
                    }
                }
            } catch (e: SecurityException) {
                Log.e(TAG, "Security exception in connection state change", e)
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice?,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic?,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            try {
                if (characteristic?.uuid == MESSAGE_CHARACTERISTIC_UUID && value != null) {
                    val address = device?.address ?: return
                    Log.d(TAG, "Received chunk of ${value.size} bytes from $address")
                    
                    val buffer = incomingBuffers.computeIfAbsent(address) { ByteArrayOutputStream() }
                    buffer.write(value)
                    
                    var currentBytes = buffer.toByteArray()
                    while (currentBytes.size >= 4) {
                        val lengthBuffer = java.nio.ByteBuffer.wrap(currentBytes, 0, 4)
                        val expectedPayloadLength = lengthBuffer.int
                        
                        if (expectedPayloadLength <= 0 || expectedPayloadLength > 10_000_000) {
                            Log.e(TAG, "Invalid payload length $expectedPayloadLength from $address, clearing buffer")
                            incomingBuffers.remove(address)
                            break
                        }
                        
                        if (currentBytes.size >= 4 + expectedPayloadLength) {
                            val payload = currentBytes.copyOfRange(4, 4 + expectedPayloadLength)
                            val remaining = currentBytes.copyOfRange(4 + expectedPayloadLength, currentBytes.size)
                            
                            val message = deserializeMessage(payload)
                            if (message != null) {
                                Log.d(TAG, "Successfully reassembled message from $address: ${message.type}")
                                messageCallbacks.forEach { callback -> callback(message) }
                            }
                            
                            buffer.reset()
                            if (remaining.isNotEmpty()) {
                                buffer.write(remaining)
                                currentBytes = remaining
                            } else {
                                currentBytes = byteArrayOf()
                            }
                        } else {
                            break
                        }
                    }
                    
                    if (responseNeeded) {
                        gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
                    }
                }
            } catch (e: SecurityException) {
                Log.e(TAG, "Security exception in characteristic write", e)
            } catch (e: Exception) {
                Log.e(TAG, "Error processing write request", e)
            }
        }
    }

    /**
     * Clean up resources
     */
    fun cleanup() {
        stopAdvertising()
        stopScanning()
        try {
            gattServer?.close()
            gattClients.values.forEach { it.close() }
            gattClients.clear()
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception closing GATT connections", e)
        }
        connectedDevices.clear()
    }
}
