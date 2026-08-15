import '../entities/sos_request.dart';

abstract class ISosRepository {
  /// Dispatches the SOS distress beacon to the coordination server / local mock store.
  Future<SosRequest> dispatchSos(SosRequest request);

  /// Retrieves the latest status of a given SOS signal.
  Future<SosRequest?> getSosStatus(String sosId);

  /// Cancels an active SOS distress beacon.
  Future<SosRequest> cancelSos(String sosId);

  /// Real-time stream of status updates for a specific SOS request.
  Stream<SosRequest> watchSosStatus(String sosId);

  /// Real-time stream of all active SOS requests (for HQ dashboards / responders).
  Stream<List<SosRequest>> watchActiveSosRequests();

  /// Retrieves previously dispatched SOS history.
  Future<List<SosRequest>> getSosHistory();
}
