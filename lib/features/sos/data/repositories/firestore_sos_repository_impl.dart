import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/emergency_type.dart';
import '../../domain/entities/sos_request.dart';
import '../../domain/entities/sos_status.dart';
import '../../domain/repositories/i_sos_repository.dart';
import '../models/sos_payload_model.dart';

/// Cloud Firestore implementation of [ISosRepository].
/// Writes and syncs emergency distress signals to the `sos_requests` Firestore collection.
/// Gracefully handles temporary network disconnects and DNS resolution issues.
class FirestoreSosRepositoryImpl implements ISosRepository {
  static const String collectionName = 'sos_requests';

  final FirebaseFirestore _firestore;

  FirestoreSosRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  @override
  Future<SosRequest> dispatchSos(SosRequest request) async {
    // 1. Initial State: TRANSMITTING
    final transmittingModel = SosPayloadModel.fromEntity(
      request.copyWith(status: SosStatus.transmitting),
    );

    final docRef = _collection.doc(request.sosId);

    try {
      // Write to Firestore with merge to safely handle concurrent updates.
      // Firestore offline persistence caches writes locally if network is down.
      await docRef.set(
        transmittingModel.toFirestoreJson(),
        SetOptions(merge: true),
      ).timeout(const Duration(seconds: 4));

      // Attempt handshake acknowledgement
      await docRef.update({
        'status': SosStatus.acknowledged.name,
      }).timeout(const Duration(seconds: 2));

      return transmittingModel.copyWith(status: SosStatus.acknowledged).toEntity();
    } catch (e) {
      debugPrint('Firestore network note during dispatch: $e');
      // Return transmitting state locally so UI and offline queue proceed seamlessly
      return transmittingModel.toEntity();
    }
  }

  @override
  Future<SosRequest?> getSosStatus(String sosId) async {
    try {
      final doc = await _collection.doc(sosId).get().timeout(const Duration(seconds: 3));
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return SosPayloadModel.fromJson(doc.data()!).toEntity();
    } catch (e) {
      debugPrint('Firestore network note during getSosStatus: $e');
      return null;
    }
  }

  @override
  Future<SosRequest> cancelSos(String sosId) async {
    final docRef = _collection.doc(sosId);

    try {
      final doc = await docRef.get().timeout(const Duration(seconds: 3));
      if (doc.exists && doc.data() != null) {
        final currentModel = SosPayloadModel.fromJson(doc.data()!);
        final cancelledModel = currentModel.copyWith(status: SosStatus.cancelled);

        await docRef.update({
          'status': SosStatus.cancelled.name,
        }).timeout(const Duration(seconds: 3));

        return cancelledModel.toEntity();
      }
    } catch (e) {
      debugPrint('Firestore network note during cancelSos: $e');
    }

    return SosRequest(
      sosId: sosId,
      timestamp: DateTime.now(),
      latitude: 0,
      longitude: 0,
      emergencyType: EmergencyType.other,
      peopleCount: 1,
      injuredCount: 0,
      status: SosStatus.cancelled,
    );
  }

  @override
  Future<void> updateSosStatus(String sosId, SosStatus newStatus) async {
    try {
      final docRef = _collection.doc(sosId);
      await docRef.update({
        'status': newStatus.name,
      }).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Firestore network note during updateSosStatus: $e');
    }
  }

  @override
  Stream<SosRequest> watchSosStatus(String sosId) {
    return _collection
        .doc(sosId)
        .snapshots()
        .where((snapshot) => snapshot.exists && snapshot.data() != null)
        .map((snapshot) => SosPayloadModel.fromJson(snapshot.data()!).toEntity())
        .handleError((error) {
      debugPrint('Firestore watchSosStatus network note: $error');
    });
  }

  @override
  Stream<List<SosRequest>> watchActiveSosRequests() {
    return _collection
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => SosPayloadModel.fromJson(doc.data()).toEntity())
          .where((req) => req.status != SosStatus.cancelled)
          .toList();
    }).handleError((error) {
      debugPrint('Firestore watchActiveSosRequests network note: $error');
      return <SosRequest>[];
    });
  }

  @override
  Stream<List<SosRequest>> watchAllSosRequests() {
    return _collection
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => SosPayloadModel.fromJson(doc.data()).toEntity())
          .toList();
    }).handleError((error) {
      debugPrint('Firestore watchAllSosRequests network note: $error');
      return <SosRequest>[];
    });
  }

  @override
  Stream<List<SosRequest>> watchUserSosRequests(String deviceId) {
    return _collection
        .where('deviceId', isEqualTo: deviceId)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => SosPayloadModel.fromJson(doc.data()).toEntity())
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }).handleError((error) {
      debugPrint('Firestore watchUserSosRequests network note: $error');
      return <SosRequest>[];
    });
  }

  @override
  Future<List<SosRequest>> getSosHistory() async {
    try {
      final querySnapshot = await _collection.get().timeout(const Duration(seconds: 4));
      return querySnapshot.docs
          .map((doc) => SosPayloadModel.fromJson(doc.data()).toEntity())
          .toList();
    } catch (e) {
      debugPrint('Firestore network note during getSosHistory: $e');
      return [];
    }
  }
}
