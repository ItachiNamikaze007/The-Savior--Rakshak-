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
      isSimulatedGps: isSimulatedGps,
    );
  }

  /// Deserializes from JSON Map (ready for backend / REST / Firebase in Phase 2)
  factory SosPayloadModel.fromJson(Map<String, dynamic> json) {
    return SosPayloadModel(
      sosId: json['sos_id'] as String? ?? json['sosId'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      emergencyType: json['emergency_type'] != null
          ? EmergencyType.fromString(json['emergency_type'] as String)
          : EmergencyType.fromString(json['emergencyType'] as String? ?? 'other'),
      peopleCount: (json['people_count'] as num?)?.toInt() ?? (json['peopleCount'] as num?)?.toInt() ?? 1,
      injuredCount: (json['injured_count'] as num?)?.toInt() ?? (json['injuredCount'] as num?)?.toInt() ?? 0,
      status: json['status'] != null
          ? SosStatus.fromString(json['status'] as String)
          : SosStatus.pending,
      isSimulatedGps: json['is_simulated_gps'] as bool? ?? json['isSimulatedGps'] as bool? ?? false,
    );
  }

  /// Serializes to JSON Map
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
      'is_simulated_gps': isSimulatedGps,
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
      isSimulatedGps: isSimulatedGps ?? this.isSimulatedGps,
    );
  }
}
