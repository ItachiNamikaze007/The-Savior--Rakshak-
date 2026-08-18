import '../entities/sos_request.dart';
import '../entities/sos_status.dart';

abstract class ISosRepository {
  /// Dispatches the SOS distress beacon to the coordination server / local mock store.
  Future<SosRequest> dispatchSos(SosRequest request);

  /// Retrieves the latest status of a given SOS signal.
  Future<SosRequest?> getSosStatus(String sosId);

  /// Cancels an active SOS distress beacon.
  Future<SosRequest> cancelSos(String sosId);

  /// Updates the status of an SOS incident from HQ command center.
  Future<void> updateSosStatus(String sosId, SosStatus newStatus);

  /// Real-time stream of status updates for a specific SOS request.
  Stream<SosRequest> watchSosStatus(String sosId);

  /// Real-time stream of all active SOS requests (for HQ dashboards / responders).
  Stream<List<SosRequest>> watchActiveSosRequests();

  /// Real-time stream of ALL SOS requests (both active and historical/resolved for HQ).
  Stream<List<SosRequest>> watchAllSosRequests();

  /// Real-time stream of user-scoped SOS requests (for the field user's Rescue screen).
  Stream<List<SosRequest>> watchUserSosRequests(String deviceId);

  /// Retrieves previously dispatched SOS history.
  Future<List<SosRequest>> getSosHistory();
}
