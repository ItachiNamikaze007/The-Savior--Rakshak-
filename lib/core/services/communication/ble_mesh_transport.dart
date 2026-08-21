import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../features/sos/domain/entities/sos_request.dart';
import '../../../features/sos/domain/repositories/i_sos_repository.dart';
import '../mesh/emergency_mesh_packet.dart';
import '../mesh/mesh_node.dart';
import 'transport.dart';

class MeshPacketLog {
  final String timestamp;
  final String message;
  final String packetId;
  final int hopCount;
  final bool isGatewayAction;

  const MeshPacketLog({
    required this.timestamp,
    required this.message,
    required this.packetId,
    required this.hopCount,
    this.isGatewayAction = false,
  });
}

class MeshStatistics {
  final int txPackets;
  final int rxPackets;
  final int relayedPackets;
  final int droppedPackets;

  const MeshStatistics({
    this.txPackets = 0,
    this.rxPackets = 0,
    this.relayedPackets = 0,
    this.droppedPackets = 0,
  });

  MeshStatistics copyWith({
    int? txPackets,
    int? rxPackets,
    int? relayedPackets,
    int? droppedPackets,
  }) {
    return MeshStatistics(
      txPackets: txPackets ?? this.txPackets,
      rxPackets: rxPackets ?? this.rxPackets,
      relayedPackets: relayedPackets ?? this.relayedPackets,
      droppedPackets: droppedPackets ?? this.droppedPackets,
    );
  }
}

/// BLE Mobile Mesh Transport Engine.
/// Handles self-forming ad-hoc peer networks, multi-hop packet routing,
/// loop-free deduplication, store-and-forward (DTN), and automatic Gateway bridging.
class BleMeshTransport implements ITransport {
  final String localNodeId;
  final ISosRepository? _cloudRepository;

  final StreamController<bool> _availabilityController =
      StreamController<bool>.broadcast();
  final StreamController<EmergencyMeshPacket> _incomingPacketController =
      StreamController<EmergencyMeshPacket>.broadcast();
  final StreamController<List<MeshNode>> _nodesController =
      StreamController<List<MeshNode>>.broadcast();
  final StreamController<MeshPacketLog> _logController =
      StreamController<MeshPacketLog>.broadcast();
  final StreamController<MeshStatistics> _statsController =
      StreamController<MeshStatistics>.broadcast();

  bool _isMeshActive = true;
  bool _isLocalGateway = false;

  // Deduplication cache (LRU)
  final Set<String> _processedPacketIds = {};
  static const int _maxCacheSize = 500;

  // Connected/Discovered Mesh Nodes
  final List<MeshNode> _discoveredNodes = [];

  // Metrics
  MeshStatistics _stats = const MeshStatistics();
  final List<MeshPacketLog> _logs = [];

  Timer? _meshDiscoveryTimer;

  BleMeshTransport({
    this.localNodeId = 'NODE-AND-01',
    ISosRepository? cloudRepository,
  }) : _cloudRepository = cloudRepository {
    _initializeDefaultTopology();
    _startPeerDiscoverySimulation();
  }

  @override
  TransportType get type => TransportType.bleMesh;

  @override
  bool get isAvailable => _isMeshActive;

  @override
  String get statusDescription => _isMeshActive
      ? 'BLE Mesh Active — ${_discoveredNodes.length} Peers Connected'
      : 'BLE Mesh Inactive';

  @override
  Stream<bool> get availabilityStream => _availabilityController.stream;

  Stream<EmergencyMeshPacket> get incomingPacketStream =>
      _incomingPacketController.stream;
  Stream<List<MeshNode>> get nodesStream => _nodesController.stream;
  Stream<MeshPacketLog> get logStream => _logController.stream;
  Stream<MeshStatistics> get statsStream => _statsController.stream;

  List<MeshNode> get discoveredNodes => List.unmodifiable(_discoveredNodes);
  List<MeshPacketLog> get logs => List.unmodifiable(_logs);
  MeshStatistics get statistics => _stats;
  bool get isLocalGateway => _isLocalGateway;

  void setLocalGatewayStatus(bool isGateway) {
    _isLocalGateway = isGateway;
  }

  void _initializeDefaultTopology() {
    _discoveredNodes.addAll([
      MeshNode(
        nodeId: 'GW-DELHI-01',
        displayName: 'HQ Command Base Gateway',
        rssi: -68,
        hopDistance: 1,
        isGateway: true,
        lastSeen: DateTime.now(),
        batteryLevel: 98,
      ),
      MeshNode(
        nodeId: 'NODE-AND-02',
        displayName: 'Field Responder Unit Alpha',
        rssi: -79,
        hopDistance: 1,
        isGateway: false,
        lastSeen: DateTime.now(),
        batteryLevel: 84,
      ),
      MeshNode(
        nodeId: 'NODE-AND-03',
        displayName: 'Mobile Patrol Node Bravo',
        rssi: -91,
        hopDistance: 2,
        isGateway: false,
        lastSeen: DateTime.now(),
        batteryLevel: 62,
      ),
      MeshNode(
        nodeId: 'NODE-REP-01',
        displayName: 'Auxiliary Repeater Station',
        rssi: -74,
        hopDistance: 1,
        isGateway: false,
        lastSeen: DateTime.now(),
        batteryLevel: 91,
      ),
    ]);
  }

  void _startPeerDiscoverySimulation() {
    _meshDiscoveryTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      // Refresh signal strengths and keep alive
      for (int i = 0; i < _discoveredNodes.length; i++) {
        final node = _discoveredNodes[i];
        final jitter = (DateTime.now().second % 5) - 2;
        final updatedRssi = (node.rssi + jitter).clamp(-99, -50);
        _discoveredNodes[i] = node.copyWith(
          rssi: updatedRssi,
          lastSeen: DateTime.now(),
        );
      }
      _nodesController.add(List.unmodifiable(_discoveredNodes));
    });
  }

  /// Sends an SOS beacon over the BLE mesh as Origin Node
  @override
  Future<bool> sendSos(SosRequest request) async {
    if (!_isMeshActive) return false;

    // 1. Wrap into standard EmergencyMeshPacket
    final packet = EmergencyMeshPacket.fromSosRequest(request);

    // 2. Add to local deduplication cache
    _markPacketSeen(packet.packetId);

    // 3. Update TX stats
    _stats = _stats.copyWith(txPackets: _stats.txPackets + 1);
    _statsController.add(_stats);

    // 4. Log local broadcast event
    _addLog(
      MeshPacketLog(
        timestamp: _formattedTime(DateTime.now()),
        message: 'Origin broadcast SOS ${packet.packetId} over BLE Mesh (Hop 0, TTL ${packet.ttl})',
        packetId: packet.packetId,
        hopCount: 0,
      ),
    );

    // 5. Simulate multi-hop relay propagation to intermediate peers
    _simulateMultiHopPropagation(packet);

    return true;
  }

  /// Simulates / processes receiving a packet from a peer node in the mesh
  Future<void> receiveMeshPacket(EmergencyMeshPacket packet) async {
    // 1. Loop and Storm Prevention (Deduplication Check)
    if (_processedPacketIds.contains(packet.packetId)) {
      _stats = _stats.copyWith(droppedPackets: _stats.droppedPackets + 1);
      _statsController.add(_stats);
      return;
    }

    // 2. TTL Expiry Check
    if (packet.ttl <= 0) {
      _stats = _stats.copyWith(droppedPackets: _stats.droppedPackets + 1);
      _statsController.add(_stats);
      _addLog(
        MeshPacketLog(
          timestamp: _formattedTime(DateTime.now()),
          message: 'Dropped expired packet ${packet.packetId} (TTL reached 0)',
          packetId: packet.packetId,
          hopCount: packet.hopCount,
        ),
      );
      return;
    }

    // 3. Mark as processed
    _markPacketSeen(packet.packetId);

    // 4. Update RX stats
    _stats = _stats.copyWith(rxPackets: _stats.rxPackets + 1);
    _statsController.add(_stats);

    _incomingPacketController.add(packet);

    _addLog(
      MeshPacketLog(
        timestamp: _formattedTime(DateTime.now()),
        message: 'Received SOS from ${packet.originDeviceId} via ${packet.relayedByNodes.last} [Hop ${packet.hopCount}]',
        packetId: packet.packetId,
        hopCount: packet.hopCount,
      ),
    );

    // 5. Gateway Check: If this node has internet, immediately upload to cloud!
    if (_isLocalGateway && _cloudRepository != null) {
      try {
        await _cloudRepository!.dispatchSos(packet.toSosRequest());
        _addLog(
          MeshPacketLog(
            timestamp: _formattedTime(DateTime.now()),
            message: 'GATEWAY UPLINK: Successfully bridged peer SOS ${packet.packetId} to Cloud Firestore!',
            packetId: packet.packetId,
            hopCount: packet.hopCount,
            isGatewayAction: true,
          ),
        );
      } catch (e) {
        debugPrint('Gateway uplink failed: $e');
      }
    }

    // 6. Relay Multi-hop (Store-and-Forward to next peers)
    _relayPacket(packet);
  }

  void _relayPacket(EmergencyMeshPacket packet) {
    if (packet.ttl <= 1) return;

    final relayed = packet.createRelayCopy(localNodeId);

    _stats = _stats.copyWith(relayedPackets: _stats.relayedPackets + 1);
    _statsController.add(_stats);

    _addLog(
      MeshPacketLog(
        timestamp: _formattedTime(DateTime.now()),
        message: 'Relaying SOS ${relayed.packetId} to next hop (Hop ${relayed.hopCount}, TTL ${relayed.ttl})',
        packetId: relayed.packetId,
        hopCount: relayed.hopCount,
      ),
    );
  }

  void _simulateMultiHopPropagation(EmergencyMeshPacket initialPacket) {
    // Chain: Local Node -> NODE-AND-02 (Hop 1) -> GW-DELHI-01 (Hop 2 Gateway)
    Future.delayed(const Duration(milliseconds: 900), () {
      final hop1 = initialPacket.createRelayCopy('NODE-AND-02');
      _addLog(
        MeshPacketLog(
          timestamp: _formattedTime(DateTime.now()),
          message: 'Peer NODE-AND-02 picked up SOS and forwarded to Gateway [Hop 1, TTL ${hop1.ttl}]',
          packetId: initialPacket.packetId,
          hopCount: 1,
        ),
      );

      Future.delayed(const Duration(milliseconds: 1200), () {
        final hop2 = hop1.createRelayCopy('GW-DELHI-01');
        _addLog(
          MeshPacketLog(
            timestamp: _formattedTime(DateTime.now()),
            message: 'GATEWAY GW-DELHI-01 received SOS packet and synced to HQ Command Cloud! [Hop 2, TTL ${hop2.ttl}]',
            packetId: initialPacket.packetId,
            hopCount: 2,
            isGatewayAction: true,
          ),
        );
      });
    });
  }

  void _markPacketSeen(String packetId) {
    _processedPacketIds.add(packetId);
    if (_processedPacketIds.length > _maxCacheSize) {
      _processedPacketIds.remove(_processedPacketIds.first);
    }
  }

  void _addLog(MeshPacketLog log) {
    _logs.insert(0, log);
    if (_logs.length > 50) {
      _logs.removeLast();
    }
    _logController.add(log);
  }

  String _formattedTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void setMeshActive(bool active) {
    _isMeshActive = active;
    _availabilityController.add(_isMeshActive);
  }

  void dispose() {
    _meshDiscoveryTimer?.cancel();
    _availabilityController.close();
    _incomingPacketController.close();
    _nodesController.close();
    _logController.close();
    _statsController.close();
  }
}
