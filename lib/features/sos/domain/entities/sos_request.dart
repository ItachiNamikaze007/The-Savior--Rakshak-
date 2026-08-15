import 'emergency_type.dart';
import 'sos_status.dart';

class SosRequest {
  final String sosId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final EmergencyType emergencyType;
  final int peopleCount;
  final int injuredCount;
  final SosStatus status;
  final String deviceId;
  final bool isSimulatedGps;

  const SosRequest({
    required this.sosId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.accuracy = 0.0,
    required this.emergencyType,
    required this.peopleCount,
    required this.injuredCount,
    this.status = SosStatus.pending,
    this.deviceId = 'NODE-AND-01',
    this.isSimulatedGps = false,
  });

  SosRequest copyWith({
    String? sosId,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    double? accuracy,
    EmergencyType? emergencyType,
    int? peopleCount,
    int? injuredCount,
    SosStatus? status,
    String? deviceId,
    bool? isSimulatedGps,
  }) {
    return SosRequest(
      sosId: sosId ?? this.sosId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      emergencyType: emergencyType ?? this.emergencyType,
      peopleCount: peopleCount ?? this.peopleCount,
      injuredCount: injuredCount ?? this.injuredCount,
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
      isSimulatedGps: isSimulatedGps ?? this.isSimulatedGps,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SosRequest &&
          runtimeType == other.runtimeType &&
          sosId == other.sosId &&
          timestamp == other.timestamp &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          emergencyType == other.emergencyType &&
          peopleCount == other.peopleCount &&
          injuredCount == other.injuredCount &&
          status == other.status &&
          deviceId == other.deviceId;

  @override
  int get hashCode =>
      sosId.hashCode ^
      timestamp.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      emergencyType.hashCode ^
      peopleCount.hashCode ^
      injuredCount.hashCode ^
      status.hashCode ^
      deviceId.hashCode;
}
