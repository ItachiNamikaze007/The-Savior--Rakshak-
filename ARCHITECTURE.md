# Emergency Mesh - Technical Architecture

## System Overview

EmergencyMesh is a decentralized, offline-first emergency communication system that leverages Wi-Fi Direct and Bluetooth Low Energy (BLE) to create ad-hoc mesh networks without internet connectivity.

## Architecture Layers

### 1. Presentation Layer
- `MainActivity.kt` - Single-screen UI with role-based features
- Minimal Material Design components
- Real-time message display with ListView
- Large touch targets for emergency scenarios

### 2. Service Layer
- `MeshService.kt` - Foreground service managing mesh network lifecycle
- Runs continuously in background
- Handles message routing and peer management
- Generates notifications for SOS alerts

### 3. Network Layer

#### ConnectionManager
- **Purpose**: Unified abstraction over BLE and Wi-Fi Direct
- **Key Features**:
  - Dual-transport message sending
  - Message deduplication (prevents loops)
  - Hop count limiting (max 5 hops)
  - Automatic peer cleanup

#### BLEManager
- **Discovery**: Low-power scanning with service UUID filtering
- **Advertising**: Makes device discoverable to peers
- **Data Transfer**: GATT server/client for message exchange
- **Power Optimization**: 30-second scan/advertise intervals

#### WiFiDirectManager
- **Group Formation**: Automatic P2P group creation
- **Socket Communication**: TCP sockets for reliable message delivery
- **Higher Bandwidth**: Preferred for voice messages
- **Auto-disconnect**: Closes connections after transmission

### 4. Handler Layer

#### MessageHandler
- **Location Integration**: GPS coordinate attachment
- **Message Creation**: Factory methods for TEXT/VOICE/SOS
- **Fallback**: Graceful degradation when GPS unavailable
- **Formatting**: User-friendly message display

#### VoiceHandler
- **Recording**: AudioRecord API with 16kHz mono PCM
- **Compression**: Raw PCM (no encoding for simplicity)
- **Duration Limit**: 30-second hard limit with auto-stop
- **Playback**: AudioTrack for received voice messages
- **Cleanup**: Immediate deletion after transmission

### 5. Model Layer
- `MeshMessage` - Serializable message with coordinates and metadata
- `MeshPeer` - Peer representation with connection type
- `UserRole` - CITIZEN vs OFFICIAL role enum

## Data Flow

### Sending a Message
```
User Input → MessageHandler (attach GPS) → MeshService → ConnectionManager
→ BLEManager + WiFiDirectManager → Broadcast to all peers
```

### Receiving a Message
```
BLE/WiFi Reception → ConnectionManager (dedup check) → MeshService
→ UI Update + Notification → Auto-relay (if hops < 5)
```

### Message Relay (Mesh Behavior)
```
Receive Message → Check hop count → Increment hops → 1s delay
→ Re-broadcast to other peers (avoid sender)
```

## Message Protocol

### Message Structure
```kotlin
data class MeshMessage(
    val id: String,              // UUID for deduplication
    val type: MessageType,       // TEXT, VOICE, or SOS
    val content: String,         // Message text
    val latitude: Double?,       // GPS lat (nullable)
    val longitude: Double?,      // GPS lon (nullable)
    val timestamp: Long,         // Unix timestamp
    val senderId: String,        // Device UUID
    val hops: Int = 0,          // Relay count
    val audioData: ByteArray?    // Voice data (if VOICE)
)
```

### Serialization
- Uses Java `ObjectOutputStream` for simplicity
- Alternative: Protocol Buffers for production use

## Network Topology

### Star-Mesh Hybrid
- **BLE**: Devices advertise and scan simultaneously (mesh)
- **Wi-Fi Direct**: One device becomes group owner (star)
- **Combined**: Creates resilient multi-path network

### Peer Discovery
1. BLE broadcasts SERVICE_UUID
2. Nearby devices detect advertisement
3. GATT connection established
4. Wi-Fi Direct group formed in parallel
5. Peer added to active peer list

### Message Routing
- **Flooding Algorithm**: Send to all connected peers
- **Deduplication**: Track seen message IDs (5-minute cache)
- **Hop Limiting**: Prevent infinite loops (max 5 hops)
- **Priority**: SOS messages bypass queues

## Power Management

### Battery Optimization Techniques

1. **Intermittent Scanning**
   - BLE scan: 10s active, 20s pause
   - Wi-Fi discovery: On-demand only

2. **Connection Lifecycle**
   - BLE: Keep GATT connections alive
   - Wi-Fi Direct: Disconnect after message delivery

3. **Location Services**
   - Use cached location (`getLastKnownLocation`)
   - No continuous GPS tracking
   - Single update on service start

4. **Audio Management**
   - Record only when needed
   - No background recording
   - Immediate buffer cleanup

5. **Service Management**
   - Foreground service (user visible)
   - Android manages lifecycle
   - Survives app background/close

## Security Considerations

### Current Implementation (None)
- **No encryption**: Messages sent in plain text
- **No authentication**: Any device can join
- **No integrity checks**: Messages not signed

### Rationale
- Emergency scenarios prioritize speed over security
- Encryption adds complexity and battery drain
- Trust model: All participants are allies in disaster

### Future Security (Out of Scope)
- Pre-shared keys for encryption
- Device whitelisting
- Message signing

## Scalability

### Network Size
- **Optimal**: 10-50 devices per mesh
- **Maximum**: ~100 devices (before congestion)
- **Limiting Factor**: Bluetooth connection limits (7 active)

### Geographic Range
- **Single Hop**: 
  - BLE: ~50 meters
  - Wi-Fi Direct: ~100 meters
- **Multi-Hop**: Extended range through relay
- **Example**: 5 hops = ~500m theoretical range

### Message Throughput
- **BLE**: ~100 bytes/sec (sufficient for text)
- **Wi-Fi Direct**: ~1-10 MB/sec (for voice)
- **Bottleneck**: BLE discovery latency (1-5 seconds)

## Error Handling

### Network Failures
- Automatic retry on failed transmission
- Dual-transport redundancy (BLE + Wi-Fi)
- Graceful degradation (Wi-Fi optional)

### Permission Denials
- Graceful UI degradation
- Clear permission prompts
- No crash on missing permissions

### GPS Unavailability
- "Location not available" fallback
- Message still sent without coordinates
- No blocking on GPS lock

### Audio Failures
- Silent failure on microphone issues
- No crash on playback errors
- Toast notifications for user feedback

## Testing Strategy

### Unit Testing (Out of Scope)
- Message serialization/deserialization
- Hop count increment logic
- Deduplication algorithm

### Integration Testing
- BLE-WiFi handoff
- Message relay through multiple hops
- Service lifecycle management

### Field Testing
- Multi-device mesh formation
- Range testing in open/obstructed areas
- Battery drain over 24 hours
- Message latency under load

## Performance Metrics

### Target Metrics
- **Message Latency**: < 5 seconds single-hop
- **Battery Life**: > 12 hours continuous operation
- **Discovery Time**: < 10 seconds to find nearby peer
- **Relay Latency**: < 2 seconds per hop

### Monitoring
- Peer count display
- Message timestamps for latency calculation
- Android Battery Historian for power profiling

## Deployment Considerations

### Minimum Viable Deployment
- 3+ devices for mesh demonstration
- Open outdoor area for range testing
- Fully charged devices

### Real-World Scenarios
- Natural disasters (earthquakes, floods)
- Network outages
- Remote areas without coverage
- Mass gatherings (concerts, protests)

## Future Enhancements (Roadmap)

### Phase 2 (Not Implemented)
- Offline maps for SOS visualization
- Message priority queuing
- Battery level sharing among peers
- Automatic role detection (emergency responders)

### Phase 3 (Not Implemented)
- End-to-end encryption
- Message persistence (SQLite)
- Multi-language support
- Accessibility features

---

**Design Philosophy**: Simplicity, reliability, and offline-first operation in emergency scenarios where traditional infrastructure has failed.
