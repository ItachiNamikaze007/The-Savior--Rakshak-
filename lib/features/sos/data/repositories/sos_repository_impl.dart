import 'dart:async';
import '../../domain/entities/sos_request.dart';
import '../../domain/entities/sos_status.dart';
import '../../domain/repositories/i_sos_repository.dart';
import '../models/sos_payload_model.dart';

class SosRepositoryImpl implements ISosRepository {
  // In-memory persistent cache for Phase 1 MVP
  final Map<String, SosPayloadModel> _cache = {};

  final Duration simulationDelay;

  SosRepositoryImpl({this.simulationDelay = const Duration(milliseconds: 100)});

  // Broadcast stream for real-time status updates
  final StreamController<SosRequest> _statusStreamController =
      StreamController<SosRequest>.broadcast();

  @override
  Future<SosRequest> dispatchSos(SosRequest request) async {
    // 1. Initial State: TRANSMITTING
    final transmittingModel = SosPayloadModel.fromEntity(
      request.copyWith(status: SosStatus.transmitting),
    );
    _cache[request.sosId] = transmittingModel;
    _statusStreamController.add(transmittingModel.toEntity());

    // 2. Simulate network latency & Command Center ACK handshake
    if (simulationDelay > Duration.zero) {
      await Future.delayed(simulationDelay);
    }

    // If request was cancelled during transmission delay, do not overwrite with acknowledged
    if (_cache[request.sosId]?.status == SosStatus.cancelled) {
      return _cache[request.sosId]!.toEntity();
    }

    // 3. Transition to ACKNOWLEDGED BY HQ
    final acknowledgedModel = transmittingModel.copyWith(
      status: SosStatus.acknowledged,
    );
    _cache[request.sosId] = acknowledgedModel;
    _statusStreamController.add(acknowledgedModel.toEntity());

    return acknowledgedModel.toEntity();
  }

  @override
  Future<SosRequest?> getSosStatus(String sosId) async {
    final model = _cache[sosId];
    return model?.toEntity();
  }

  @override
  Future<SosRequest> cancelSos(String sosId) async {
    final existing = _cache[sosId];
    if (existing == null) {
      throw Exception('SOS Beacon not found for ID: $sosId');
    }

    final cancelledModel = existing.copyWith(status: SosStatus.cancelled);
    _cache[sosId] = cancelledModel;
    _statusStreamController.add(cancelledModel.toEntity());

    return cancelledModel.toEntity();
  }

  @override
  Future<void> updateSosStatus(String sosId, SosStatus newStatus) async {
    final existing = _cache[sosId];
    if (existing != null) {
      final updated = existing.copyWith(status: newStatus);
      _cache[sosId] = updated;
      _statusStreamController.add(updated.toEntity());
    }
  }

  @override
  Stream<SosRequest> watchSosStatus(String sosId) async* {
    // Emit initial status if present
    final current = _cache[sosId];
    if (current != null) {
      yield current.toEntity();
    }

    // Stream subsequent updates matching this sosId
    yield* _statusStreamController.stream
        .where((req) => req.sosId == sosId);
  }

  @override
  Stream<List<SosRequest>> watchActiveSosRequests() async* {
    // Emit current non-cancelled snapshot
    yield _cache.values
        .where((m) => m.status != SosStatus.cancelled)
        .map((m) => m.toEntity())
        .toList();

    // Yield updated snapshot on every stream event
    await for (final _ in _statusStreamController.stream) {
      yield _cache.values
          .where((m) => m.status != SosStatus.cancelled)
          .map((m) => m.toEntity())
          .toList();
    }
  }

  @override
  Stream<List<SosRequest>> watchAllSosRequests() async* {
    // Emit current snapshot
    yield _cache.values.map((m) => m.toEntity()).toList();

    // Yield updated snapshot on every stream event
    await for (final _ in _statusStreamController.stream) {
      yield _cache.values.map((m) => m.toEntity()).toList();
    }
  }

  @override
  Stream<List<SosRequest>> watchUserSosRequests(String deviceId) async* {
    yield _cache.values
        .where((m) => m.deviceId == deviceId)
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    await for (final _ in _statusStreamController.stream) {
      yield _cache.values
          .where((m) => m.deviceId == deviceId)
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  @override
  Future<List<SosRequest>> getSosHistory() async {
    return _cache.values.map((model) => model.toEntity()).toList();
  }

  void dispose() {
    _statusStreamController.close();
  }
}
