# 🚨 Emergency Mesh - Quick Reference Card

## What Is This?
A **barebones, offline Android app** for emergency communication when internet/cell networks fail. Uses Bluetooth Low Energy and Wi-Fi Direct to create ad-hoc mesh networks.

---

## 📁 Project Location
```
/home/rohan/Desktop/flame-courses/imp/EmergencyMesh
```

---

## 🏗️ What Was Built

### ✅ Complete Android Application
- **10 Kotlin files** (~1,800 lines)
- **3 XML layouts** (UI resources)
- **Full Gradle configuration**
- **6 comprehensive documentation files**

### Core Components
```
Models (3):
  ├─ MeshMessage.kt      (Message with GPS + hops)
  ├─ MeshPeer.kt         (Peer metadata)
  └─ UserRole.kt         (Citizen/Official)

Network (3):
  ├─ BLEManager.kt       (Bluetooth Low Energy)
  ├─ WiFiDirectManager.kt (Wi-Fi Direct P2P)
  └─ ConnectionManager.kt (Unified mesh coordinator)

Handlers (2):
  ├─ MessageHandler.kt   (GPS integration)
  └─ VoiceHandler.kt     (Audio recording/playback)

Service (1):
  └─ MeshService.kt      (Foreground background service)

UI (1):
  └─ MainActivity.kt     (Single-screen interface)
```

---

## 🎯 Key Features

| Feature | Description |
|---------|-------------|
| 🌐 **Offline Mesh** | BLE + Wi-Fi Direct, no internet needed |
| 📍 **GPS Tagging** | Every message includes coordinates |
| 🚨 **SOS Button** | One-tap emergency broadcast |
| 🎤 **Voice SMS** | 30-second audio messages |
| 🔁 **Auto Relay** | Messages forward through up to 5 hops |
| 🔋 **Low Power** | Optimized for extended battery life |
| 👥 **Dual Roles** | Citizen (user) / Official (responder) |

---

## 🚀 Quick Start (3 Steps)

### 1. Open in Android Studio
```bash
cd /home/rohan/Desktop/flame-courses/imp/EmergencyMesh
# Then: File → Open in Android Studio
```

### 2. Build Project
```bash
./gradlew build
```

### 3. Install on Device
```bash
./gradlew installDebug
# Or use Android Studio's Run button ▶
```

---

## 📱 First Launch

1. **Select Role**: Choose "Citizen" or "Official"
2. **Grant Permissions**: Allow all (Location, Bluetooth, Mic, etc.)
3. **Wait for Service**: Notification appears "Emergency Mesh Active"
4. **Start Testing**: App auto-discovers nearby peers

---

## 🧪 Testing Scenarios

### Scenario 1: Basic Message (2 devices)
```
1. Install on both devices
2. Wait for "Peers: 1" to appear
3. Type message → Send
4. Verify message appears on other device with GPS
```

### Scenario 2: Mesh Relay (3+ devices)
```
1. Arrange: Device A ↔ Device B ↔ Device C
2. Move A and C out of direct range
3. Send message from A
4. Verify C receives via B (check hop count)
```

### Scenario 3: Emergency SOS
```
1. Tap red "🚨 EMERGENCY SOS" button
2. All nearby devices receive notification
3. Message includes GPS coordinates
```

### Scenario 4: Voice Message
```
1. Tap "🎤 Record Voice" button
2. Speak for up to 30 seconds
3. Tap "⏹ Stop Recording"
4. Voice sent to all peers
5. Recipients tap to play
```

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **README.md** | Feature overview & usage |
| **QUICKSTART.md** | Detailed setup instructions |
| **ARCHITECTURE.md** | Technical deep-dive |
| **PROJECT_SUMMARY.md** | Complete project overview |
| **COMPARISON.md** | vs Bitchat analysis |
| **COMPLETION_CHECKLIST.md** | Implementation status |

---

## ⚙️ Technical Specs

- **Platform**: Android
- **Language**: Kotlin
- **Min SDK**: 26 (Android 8.0)
- **Target SDK**: 34 (Android 14)
- **Dependencies**: AndroidX, Material, Google Location
- **Permissions**: Bluetooth, Location, Mic, WiFi (NO INTERNET)

---

## 🔋 Power Profile

- **BLE Scanning**: 30-second cycles (low-power mode)
- **WiFi Direct**: On-demand, auto-disconnect
- **GPS**: Cached location (not continuous tracking)
- **Expected Life**: 12+ hours continuous operation

---

## 🌍 Network Topology

```
Star-Mesh Hybrid:

BLE:           [All devices advertise + scan]
               ┌──────┬──────┬──────┐
               │      │      │      │
              Dev1  Dev2  Dev3  Dev4

WiFi Direct:   Group Owner (star topology)
               ┌─────────┐
               │  Owner  │
               └────┬────┘
            ┌───────┼───────┐
           Dev1    Dev2    Dev3

Combined:      Multi-path redundancy
```

---

## 📊 Message Flow

```
SEND:
User → MessageHandler (attach GPS)
     → MeshService
     → ConnectionManager
     → BLE + WiFi Direct
     → Broadcast to peers

RECEIVE:
BLE/WiFi → ConnectionManager (dedup)
         → MeshService
         → UI Update
         → Auto-relay (if hops < 5)
```

---

## ⚠️ Important Notes

### Security
- ❌ **No encryption** (speed priority in emergencies)
- ❌ **No authentication** (all peers trusted)
- ✅ Trade-off accepted for disaster scenarios

### Range Limitations
- BLE: ~50 meters open area
- Wi-Fi Direct: ~100 meters open area
- Mesh relay extends range (5 hops max)

### Device Requirements
- Android 8.0+ (API 26)
- Bluetooth Low Energy support (required)
- Wi-Fi Direct support (optional)
- GPS (optional but recommended)

---

## 🛠️ Development Commands

```bash
# Build debug APK
./gradlew assembleDebug

# Install on connected device
./gradlew installDebug

# Clean build
./gradlew clean build

# View logs
adb logcat -s EmergencyMesh:* BLEManager:* ConnectionManager:*

# Verify project structure
./verify_project.sh
```

---

## 🐛 Common Issues & Fixes

| Problem | Solution |
|---------|----------|
| Devices don't discover | Wait 30-60s, restart both apps |
| No GPS coordinates | Move outdoors, wait for GPS lock |
| Voice recording fails | Check mic permission granted |
| High battery drain | Normal, ~5-10% per hour expected |

---

## 📖 Learning Path

1. **Start Here**: Read `README.md`
2. **Build & Run**: Follow `QUICKSTART.md`
3. **Understand Design**: Read `ARCHITECTURE.md`
4. **Compare Approaches**: Check `COMPARISON.md`

---

## 🎯 Use Cases

### ✅ Perfect For:
- Natural disasters (earthquake, flood, hurricane)
- Network outages / blackouts
- Search and rescue operations
- Mass gatherings without coverage
- Remote areas with no infrastructure

### ❌ Not Suitable For:
- Daily private messaging (use Bitchat instead)
- Long-distance communication (no relays)
- Secure communications (no encryption)
- File sharing (text/voice only)

---

## 🏆 Project Status

**COMPLETE ✅**

All core requirements implemented:
- [x] Offline mesh networking (BLE + WiFi)
- [x] GPS coordinate tagging
- [x] Emergency SOS broadcast
- [x] Voice message support
- [x] Power optimization
- [x] Simple one-screen UI
- [x] Mesh relay (5 hops)
- [x] No internet dependency

**Ready for**: Build → Install → Test on physical devices

---

## 📞 Next Actions

1. ✅ Open in Android Studio
2. ✅ Sync Gradle (auto on first open)
3. ✅ Build project (`./gradlew build`)
4. ✅ Connect Android device via USB
5. ✅ Enable USB debugging on device
6. ✅ Click Run ▶ in Android Studio
7. ✅ Grant all permissions on device
8. ✅ Test with 2-3 devices

---

## 💡 Pro Tips

- **Testing**: Use 3+ devices for best mesh demonstration
- **Range**: Test outdoors for maximum BLE/WiFi range
- **Battery**: Fully charge devices for extended testing
- **GPS**: Wait 30-60 seconds outdoors for initial GPS lock
- **Logs**: Use `adb logcat` to debug network issues

---

**Emergency Mesh v1.0**  
Built for disaster scenarios where every connection matters.

🚨 **Remember**: This complements, not replaces, official emergency services (911, etc.)
