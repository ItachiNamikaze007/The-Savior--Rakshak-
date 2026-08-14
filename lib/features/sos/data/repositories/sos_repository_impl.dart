import 'dart:async';
import '../../domain/entities/sos_request.dart';
import '../../domain/entities/sos_status.dart';
import '../../domain/repositories/i_sos_repository.dart';
import '../models/sos_payload_model.dart';

class SosRepositoryImpl implements ISosRepository {
  // In-memory persistent cache for Phase 1 MVP
  final Map<String, SosPayloadModel> _cache = {};

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
    await Future.delayed(const Duration(milliseconds: 2200));

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
  Future<List<SosRequest>> getSosHistory() async {
    return _cache.values.map((model) => model.toEntity()).toList();
  }

  void dispose() {
    _statusStreamController.close();
  }
}
