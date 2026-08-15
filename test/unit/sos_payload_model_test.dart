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
      deviceId: 'NODE-AND-01',
      isSimulatedGps: false,
    );

    test('toJson serializes all required SOS fields correctly', () {
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
      expect(json['device_id'], equals('NODE-AND-01'));
      expect(json['is_simulated_gps'], isFalse);
    });

    test('toFirestoreJson serializes all 10 Cloud Firestore fields with camelCase keys', () {
      final model = SosPayloadModel.fromEntity(sampleEntity);
      final firestoreJson = model.toFirestoreJson();

      expect(firestoreJson['sosId'], equals('RAK-20260814-99AA'));
      expect(firestoreJson['timestamp'], equals(fixedTime.toIso8601String()));
      expect(firestoreJson['latitude'], equals(28.6139));
      expect(firestoreJson['longitude'], equals(77.2090));
      expect(firestoreJson['accuracy'], equals(4.5));
      expect(firestoreJson['emergencyType'], equals('flood'));
      expect(firestoreJson['peopleCount'], equals(6));
      expect(firestoreJson['injuredCount'], equals(2));
      expect(firestoreJson['status'], equals('pending'));
      expect(firestoreJson['deviceId'], equals('NODE-AND-01'));
      expect(firestoreJson['isSimulatedGps'], isFalse);
    });

    test('fromJson deserializes json payload with camelCase back into model', () {
      final Map<String, dynamic> json = {
        'sosId': 'RAK-20260814-B1C2',
        'timestamp': fixedTime.toIso8601String(),
        'latitude': 19.0760,
        'longitude': 72.8777,
        'accuracy': 3.2,
        'emergencyType': 'fire',
        'peopleCount': 12,
        'injuredCount': 4,
        'status': 'transmitting',
        'deviceId': 'NODE-TEST-02',
        'isSimulatedGps': true,
      };

      final model = SosPayloadModel.fromJson(json);

      expect(model.sosId, equals('RAK-20260814-B1C2'));
      expect(model.latitude, equals(19.0760));
      expect(model.longitude, equals(72.8777));
      expect(model.emergencyType, equals(EmergencyType.fire));
      expect(model.peopleCount, equals(12));
      expect(model.injuredCount, equals(4));
      expect(model.status, equals(SosStatus.transmitting));
      expect(model.deviceId, equals('NODE-TEST-02'));
      expect(model.isSimulatedGps, isTrue);
    });

    test('toEntity converts model to domain entity accurately', () {
      final model = SosPayloadModel.fromEntity(sampleEntity);
      final entity = model.toEntity();

      expect(entity.sosId, equals(sampleEntity.sosId));
      expect(entity.emergencyType, equals(sampleEntity.emergencyType));
      expect(entity.peopleCount, equals(sampleEntity.peopleCount));
      expect(entity.injuredCount, equals(sampleEntity.injuredCount));
      expect(entity.deviceId, equals(sampleEntity.deviceId));
      expect(entity, equals(sampleEntity));
    });
  });
}
