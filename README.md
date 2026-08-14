# SoSquad - RAKSHAK-NET (Phase 1 Online MVP)

**RAKSHAK-NET** is a hybrid disaster response and rescue coordination system built for SIH and emergency response operations.

---

## Architecture Overview (Clean Architecture)

```
d:\SoSquad\
├── android\                    # Android configuration & location permissions
├── lib\
│   ├── core\
│   │   ├── constants\          # AppColors, AppStrings, AppTheme (Tactical Dark Theme)
│   │   ├── errors\             # LocationException, SosException
│   │   ├── services\           # LocationService (Geolocator GPS + Mock fallback), TelemetryService
│   │   └── utils\              # IdGenerator (RAK-YYYYMMDD-XXXX)
│   ├── features\
│   │   └── sos\
│   │       ├── data\
│   │       │   ├── models\     # SosPayloadModel (from/toJson, copyWith)
│   │       │   └── repositories\ # SosRepositoryImpl (Local mock repository)
│   │       ├── domain\
│   │       │   ├── entities\   # SosRequest, EmergencyType, SosStatus
│   │       │   └── repositories\ # ISosRepository (Domain contract)
│   │       └── presentation\
│   │           ├── providers\  # SosStateNotifier (ChangeNotifier)
│   │           ├── screens\    # HomeSosScreen, SosConfirmationSheet, ActiveSosBroadcastScreen
│   │           └── widgets\    # GpsTelemetryCard, EmergencyTypeSelector, PeopleCounterCard, PulsingSosButton, StatusBadge
│   └── main.dart               # MultiProvider DI & App Entry
└── test\                       # Unit and widget test suite
```

---

## Implemented Working Flows (Phase 1 MVP)

1. **Launch**: Opens SoSquad / RAKSHAK-NET Tactical Emergency Console.
2. **GPS Acquisition & Error Handling**:
   - Automatically checks hardware status and requests `ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION`.
   - Formats live latitude/longitude with cardinal coordinates (`28.6139° N, 77.2090° E`) and accuracy in meters.
   - Robust error handling for `serviceDisabled`, `permissionDenied`, `permissionDeniedForever`, and `timeout`.
   - Provides an explicit "Simulated GPS (Dev Mode)" toggle for emulators or demo environments without altering real device hardware behavior.
3. **Emergency Type Selection**:
   - `Medical`, `Flood`, `Fire`, `Earthquake`, `Other` with custom icons and emergency color badges.
4. **Casualty Counter Controls**:
   - Number of affected / trapped people.
   - Number of injured requiring immediate medical aid with validation rules.
5. **SOS Trigger & Confirmation**:
   - Large central glowing red radar pulsing SOS button.
   - Confirmation modal with 3-second rapid auto-dispatch countdown and abort option.
6. **Payload Generation**:
   - Generates unique ID `RAK-YYYYMMDD-XXXX`.
   - Encapsulates 8 core fields: SOS ID, timestamp, latitude, longitude, emergency type, people count, injured count, and status.
7. **Active Broadcast Screen**:
   - Displays animated distress radar beacon.
   - Live status transition: `TRANSMITTING` $\rightarrow$ `ACKNOWLEDGED BY HQ`.
   - Copyable SOS ID, incident payload details, and transmission event timeline.
   - SOS cancellation action with safety confirmation dialog.

---

## How to Run

1. Ensure Flutter is installed:
   ```bash
   flutter doctor
   ```
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run test suite:
   ```bash
   flutter test
   ```
4. Run on Android device / emulator:
   ```bash
   flutter run
   ```

---

## Phase 2 Roadmap
- Backend integration (REST / WebSockets / Firebase / Supabase) via `ISosRepository`.
- LoRa mesh offline peer-to-peer distress beacon transmission.
- Real-time command dashboard with live GIS map tracking.
- Rescue team triage and resource routing.
