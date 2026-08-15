import '../../domain/entities/emergency_type.dart';
import '../../domain/entities/sos_request.dart';
import '../../domain/entities/sos_status.dart';

class SosPayloadModel {
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

  const SosPayloadModel({
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

  /// Factory constructor to convert from Domain Entity
  factory SosPayloadModel.fromEntity(SosRequest entity) {
    return SosPayloadModel(
      sosId: entity.sosId,
      timestamp: entity.timestamp,
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      emergencyType: entity.emergencyType,
      peopleCount: entity.peopleCount,
      injuredCount: entity.injuredCount,
      status: entity.status,
      deviceId: entity.deviceId,
      isSimulatedGps: entity.isSimulatedGps,
    );
  }

  /// Converts this model to a Domain Entity
  SosRequest toEntity() {
    return SosRequest(
      sosId: sosId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      emergencyType: emergencyType,
      peopleCount: peopleCount,
      injuredCount: injuredCount,
      status: status,
      deviceId: deviceId,
      isSimulatedGps: isSimulatedGps,
    );
  }

  /// Helper to safely parse timestamp from Firestore Timestamp, String, or epoch int
  static DateTime _parseTimestamp(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    try {
      // Handles Cloud Firestore Timestamp without direct compile-time coupling
      return (val as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Deserializes from JSON Map (supports both camelCase and snake_case keys)
  factory SosPayloadModel.fromJson(Map<String, dynamic> json) {
    return SosPayloadModel(
      sosId: json['sosId'] as String? ?? json['sos_id'] as String? ?? '',
      timestamp: _parseTimestamp(json['timestamp']),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      emergencyType: json['emergencyType'] != null
          ? EmergencyType.fromString(json['emergencyType'] as String)
          : (json['emergency_type'] != null
              ? EmergencyType.fromString(json['emergency_type'] as String)
              : EmergencyType.other),
      peopleCount: (json['peopleCount'] as num?)?.toInt() ??
          (json['people_count'] as num?)?.toInt() ??
          1,
      injuredCount: (json['injuredCount'] as num?)?.toInt() ??
          (json['injured_count'] as num?)?.toInt() ??
          0,
      status: json['status'] != null
          ? SosStatus.fromString(json['status'] as String)
          : SosStatus.pending,
      deviceId: json['deviceId'] as String? ??
          json['device_id'] as String? ??
          'NODE-AND-01',
      isSimulatedGps: json['isSimulatedGps'] as bool? ??
          json['is_simulated_gps'] as bool? ??
          false,
    );
  }

  /// Serializes to standard JSON Map
  Map<String, dynamic> toJson() {
    return {
      'sos_id': sosId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'emergency_type': emergencyType.name,
      'people_count': peopleCount,
      'injured_count': injuredCount,
      'status': status.name,
      'device_id': deviceId,
      'is_simulated_gps': isSimulatedGps,
    };
  }

  /// Serializes specifically for Cloud Firestore sos_requests documents
  Map<String, dynamic> toFirestoreJson() {
    return {
      'sosId': sosId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'emergencyType': emergencyType.name,
      'peopleCount': peopleCount,
      'injuredCount': injuredCount,
      'status': status.name,
      'deviceId': deviceId,
      'isSimulatedGps': isSimulatedGps,
    };
  }

  SosPayloadModel copyWith({
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
    return SosPayloadModel(
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
}
