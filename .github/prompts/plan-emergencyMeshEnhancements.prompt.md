# Plan: EmergencyMesh Feature Enhancements

Implementing unlimited hop forwarding with role-based visibility, message queuing for reliability, user registration, tap-to-play voice messages, and sent message display.

## Steps

1. **Modify hop logic in [MeshMessage.kt](app/src/main/java/com/emergency/mesh/models/MeshMessage.kt) and [ConnectionManager.kt](app/src/main/java/com/emergency/mesh/network/ConnectionManager.kt)**
   - Remove `MAX_HOPS` limit from `hasExceededMaxHops()` — always return `false` for relay decisions
   - Add new method `shouldDisplayForRole(role: UserRole): Boolean` — returns `true` if `hops <= 5` OR `role == OFFICIAL`
   - Update `handleReceivedMessage()` to always relay but conditionally notify UI based on role

2. **Add message queue system in [ConnectionManager.kt](app/src/main/java/com/emergency/mesh/network/ConnectionManager.kt)**
   - Add `pendingMessages: ConcurrentLinkedQueue<MeshMessage>` for outbound queue
   - Modify `sendMessage()` to queue messages when no peers connected
   - Add `flushMessageQueue()` called when peers are discovered in `onPeerDiscovered()`
   - Add queue persistence using SharedPreferences or local file for crash recovery

3. **Create user registration in new [UserProfile.kt](app/src/main/java/com/emergency/mesh/models/UserProfile.kt) and update [MainActivity.kt](app/src/main/java/com/emergency/mesh/MainActivity.kt)**
   - Create `UserProfile` data class with `name`, `phone`, `emergencyContact`, `bloodType`, `medicalInfo`
   - Add registration dialog on first launch (before role selection)
   - Store profile in SharedPreferences
   - Update `MeshMessage` to include `senderName` and `senderProfile` fields for SOS messages

4. **Implement tap-to-play voice messages in [MainActivity.kt](app/src/main/java/com/emergency/mesh/MainActivity.kt)**
   - Store received `MeshMessage` objects (not just formatted strings) in a separate list
   - Remove auto-play from `onMessageReceived()` callback
   - Implement `lvMessages.setOnItemClickListener` to detect voice messages and call `voiceHandler.playAudio()`
   - Add visual indicator (🎤 tap to play) for voice messages
   - Also add an option to ensure that the voice message is only played when tapped, not automatically played upon receipt. It is also forwarded when the message is relayed to other peers.

5. **Display sent messages in [MainActivity.kt](app/src/main/java/com/emergency/mesh/MainActivity.kt)**
   - After calling `meshService?.sendMessage()`, also add the message to `receivedMessages` list with "📤 Sent" prefix
   - Update `formatMessageForDisplay()` in [MessageHandler.kt](app/src/main/java/com/emergency/mesh/handlers/MessageHandler.kt) to accept optional `isSent` parameter

## Further Considerations

1. **Queue persistence strategy?** File-based JSON / SharedPreferences / Room database — recommend SharedPreferences for simplicity since messages are temporary - Yes use SharedPreferences
2. **Voice message storage limit?** Should we cap stored voice messages (e.g., last 20) to prevent memory issues with large ByteArrays? Yes, implement a cap of 20 messages.
3. **Registration required fields?** Name (required) + Phone/EmergencyContact/BloodType/MedicalInfo (optional) — confirm which are mandatory - Yes, only Name is mandatory; others are optional.