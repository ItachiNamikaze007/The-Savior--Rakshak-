import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sos_request.dart';
import '../../domain/entities/sos_status.dart';
import '../../domain/repositories/i_sos_repository.dart';
import '../models/sos_payload_model.dart';

/// Cloud Firestore implementation of [ISosRepository].
/// Writes and syncs emergency distress signals to the `sos_requests` Firestore collection.
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

    // Write to Firestore with merge to safely handle concurrent updates
    await docRef.set(
      transmittingModel.toFirestoreJson(),
      SetOptions(merge: true),
    );

    // In a live cloud environment, Cloud Functions or HQ acknowledge the request.
    // If running standalone, transition status to acknowledged in Firestore after handshake.
    try {
      await docRef.update({
        'status': SosStatus.acknowledged.name,
      });
      return transmittingModel.copyWith(status: SosStatus.acknowledged).toEntity();
    } catch (_) {
      // Return transmitting state if update fails
      return transmittingModel.toEntity();
    }
  }

  @override
  Future<SosRequest?> getSosStatus(String sosId) async {
    final doc = await _collection.doc(sosId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return SosPayloadModel.fromJson(doc.data()!).toEntity();
  }

  @override
  Future<SosRequest> cancelSos(String sosId) async {
    final docRef = _collection.doc(sosId);
    final doc = await docRef.get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('SOS request document not found for ID: $sosId');
    }

    final currentModel = SosPayloadModel.fromJson(doc.data()!);
    final cancelledModel = currentModel.copyWith(status: SosStatus.cancelled);

    await docRef.update({
      'status': SosStatus.cancelled.name,
    });

    return cancelledModel.toEntity();
  }

  @override
  Stream<SosRequest> watchSosStatus(String sosId) {
    return _collection.doc(sosId).snapshots().where((snapshot) => snapshot.exists && snapshot.data() != null).map((snapshot) {
      return SosPayloadModel.fromJson(snapshot.data()!).toEntity();
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
    });
  }

  @override
  Future<List<SosRequest>> getSosHistory() async {
    final querySnapshot = await _collection.get();
    return querySnapshot.docs
        .map((doc) => SosPayloadModel.fromJson(doc.data()).toEntity())
        .toList();
  }
}
