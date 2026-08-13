# Release Notes - v1.0

**Date**: December 9, 2025
**Version**: 1.0.0

## Summary
This is the first official release of Emergency Mesh. It transforms the project from a prototype into a polished, user-friendly application suitable for real-world emergency scenarios. The focus has been on usability, localization, and core safety features.

## New Features
*   **Multi-Screen Architecture**: Replaced the single-screen layout with a modern, fragment-based navigation system (Home, Chat, Profile).
*   **Safe Status Broadcasting**: Users can now mark themselves as "Safe", which is broadcasted to the entire mesh network.
*   **Language Support**: Added full localization for:
    *   Hindi (हिंदी)
    *   Tamil (தமிழ்)
    *   Telugu (తెలుగు)
    *   Bengali (বাংলা)
*   **Voice Messaging**: Integrated 30-second voice recording and playback directly in the chat interface.
*   **Profile Management**: Users can now save medical info, emergency contacts, and blood type locally.
*   **Visual Polish**: Implemented Material Design 3 components, consistent theming, and vector icons.

## Improvements
*   **Network Stability**: Simplified the networking layer to rely exclusively on BLE for better stability and battery life (removed experimental Wi-Fi Direct support).
*   **Message Handling**: Improved message reliability and added visual indicators for different message types (SOS, Safe, Voice, Text).
*   **Permissions**: Streamlined permission requests flow for Android 12+ support.

## Known Issues
*   Range is limited by Bluetooth capabilities (typically 30-100 meters between nodes).
*   Voice messages may take longer to transfer over BLE mesh compared to text.

## Installation
Install the `app-debug.apk` generated in `app/build/outputs/apk/debug/`.
