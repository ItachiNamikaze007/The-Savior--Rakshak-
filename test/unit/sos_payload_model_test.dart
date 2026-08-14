import 'package:flutter_test/flutter_test.dart';
import 'package:sosquad/core/utils/id_generator.dart';
import 'package:sosquad/features/sos/data/models/sos_payload_model.dart';
import 'package:sosquad/features/sos/domain/entities/emergency_type.dart';
import 'package:sosquad/features/sos/domain/entities/sos_request.dart';
import 'package:sosquad/features/sos/domain/entities/sos_status.dart';

void main() {
  group('IdGenerator Tests', () {
    test('generateSosId produces standard RAK-YYYYMMDD-XXXX format', () {
      final fixedDate = DateTime(2026, 8, 14, 21, 30);
      final id = IdGenerator.generateSosId(timestamp: fixedDate);
      expect(id, startsWith('RAK-20260814-'));
      expect(id.length, equals(17));
    });
  });

  group('SosPayloadModel Tests', () {
    final fixedTime = DateTime(2026, 8, 14, 21, 30, 00);

    final sampleEntity = SosRequest(
      sosId: 'RAK-20260814-99AA',
      timestamp: fixedTime,
      latitude: 28.6139,
      longitude: 77.2090,
      accuracy: 4.5,
      emergencyType: EmergencyType.flood,
      peopleCount: 6,
      injuredCount: 2,
      status: SosStatus.pending,
      isSimulatedGps: false,
    );

    test('toJson serializes all required 8 SOS fields correctly', () {
      final model = SosPayloadModel.fromEntity(sampleEntity);
      final json = model.toJson();

      expect(json['sos_id'], equals('RAK-20260814-99AA'));
      expect(json['timestamp'], equals(fixedTime.toIso8601String()));
      expect(json['latitude'], equals(28.6139));
      expect(json['longitude'], equals(77.2090));
      expect(json['emergency_type'], equals('flood'));
      expect(json['people_count'], equals(6));
      expect(json['injured_count'], equals(2));
      expect(json['status'], equals('pending'));
      expect(json['is_simulated_gps'], isFalse);
    });

    test('fromJson deserializes json payload back into model', () {
      final Map<String, dynamic> json = {
        'sos_id': 'RAK-20260814-B1C2',
        'timestamp': fixedTime.toIso8601String(),
        'latitude': 19.0760,
        'longitude': 72.8777,
        'accuracy': 3.2,
        'emergency_type': 'fire',
        'people_count': 12,
        'injured_count': 4,
        'status': 'transmitting',
        'is_simulated_gps': true,
      };

      final model = SosPayloadModel.fromJson(json);

      expect(model.sosId, equals('RAK-20260814-B1C2'));
      expect(model.latitude, equals(19.0760));
      expect(model.longitude, equals(72.8777));
      expect(model.emergencyType, equals(EmergencyType.fire));
      expect(model.peopleCount, equals(12));
      expect(model.injuredCount, equals(4));
      expect(model.status, equals(SosStatus.transmitting));
      expect(model.isSimulatedGps, isTrue);
    });

    test('toEntity converts model to domain entity accurately', () {
      final model = SosPayloadModel.fromEntity(sampleEntity);
      final entity = model.toEntity();

      expect(entity.sosId, equals(sampleEntity.sosId));
      expect(entity.emergencyType, equals(sampleEntity.emergencyType));
      expect(entity.peopleCount, equals(sampleEntity.peopleCount));
      expect(entity.injuredCount, equals(sampleEntity.injuredCount));
      expect(entity, equals(sampleEntity));
    });
  });
}
