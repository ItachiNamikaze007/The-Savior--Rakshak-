import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../errors/app_exceptions.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double heading;
  final DateTime timestamp;
  final bool isSimulated;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.heading = 0.0,
    required this.timestamp,
    this.isSimulated = false,
  });

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    bool? isSimulated,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }
}

class LocationService {
  // Default simulated coordinates (National Disaster Response HQ coordinates for testing/demo)
  static final LocationData defaultSimulatedLocation = LocationData(
    latitude: 28.6139,
    longitude: 77.2090,
    accuracy: 4.8,
    altitude: 216.0,
    heading: 0.0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    isSimulated: true,
  );

  /// Fetches real GPS coordinates from device hardware.
  /// Throws [LocationException] with specific [LocationErrorCode] if permission or service is unavailable.
  Future<LocationData> getCurrentLocation({bool forceSimulated = false}) async {
    if (forceSimulated) {
      return LocationData(
        latitude: 28.6139 + (DateTime.now().millisecond % 50) * 0.0001,
        longitude: 77.2090 + (DateTime.now().second % 50) * 0.0001,
        accuracy: 4.5,
        altitude: 216.0,
        heading: 0.0,
        timestamp: DateTime.now(),
        isSimulated: true,
      );
    }

    // 1. Verify location services hardware is enabled
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw const LocationException(
        'GPS location service is disabled on this device. Please turn on Location in system settings.',
        code: LocationErrorCode.serviceDisabled,
      );
    }

    // 2. Verify permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Location permission was denied. RAKSHAK-NET requires GPS coordinates to dispatch rescue units.',
          code: LocationErrorCode.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. Please enable Location in App Settings.',
        code: LocationErrorCode.permissionDeniedForever,
      );
    }

    // 3. Acquire high-accuracy real GPS fix
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
        isSimulated: position.isMocked,
      );
    } on TimeoutException {
      // Try fetching last known position as fallback if live fix timed out
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LocationData(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
          accuracy: lastKnown.accuracy,
          altitude: lastKnown.altitude,
          speed: lastKnown.speed,
          heading: lastKnown.heading,
          timestamp: lastKnown.timestamp,
          isSimulated: lastKnown.isMocked,
        );
      }
      throw const LocationException(
        'GPS satellite lock timed out. Ensure you have clear line-of-sight to the sky or retry.',
        code: LocationErrorCode.timeout,
      );
    } catch (e) {
      throw LocationException(
        'Failed to acquire GPS fix: ${e.toString()}',
        code: LocationErrorCode.unknown,
      );
    }
  }

  /// Provides a real-time stream of live GPS location updates as the user moves.
  Stream<LocationData> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 2,
  }) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings).map(
      (pos) => LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        speed: pos.speed,
        heading: pos.heading,
        timestamp: pos.timestamp,
        isSimulated: pos.isMocked,
      ),
    );
  }

  /// Opens the app settings page so user can grant location permissions.
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Opens the device location settings page.
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
