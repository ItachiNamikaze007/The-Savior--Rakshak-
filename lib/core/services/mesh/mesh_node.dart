class MeshNode {
  final String nodeId;
  final String displayName;
  final int rssi; // e.g. -68 dBm
  final int hopDistance; // 1 = Direct neighbor, 2 = 2 Hops away, etc.
  final bool isGateway; // true if this node has active internet bridge
  final DateTime lastSeen;
  final int batteryLevel; // 0 - 100%

  const MeshNode({
    required this.nodeId,
    required this.displayName,
    required this.rssi,
    required this.hopDistance,
    this.isGateway = false,
    required this.lastSeen,
    this.batteryLevel = 100,
  });

  String get signalQualityLabel {
    if (rssi >= -60) return 'Excellent';
    if (rssi >= -75) return 'Good';
    if (rssi >= -85) return 'Fair';
    return 'Weak';
  }

  MeshNode copyWith({
    String? nodeId,
    String? displayName,
    int? rssi,
    int? hopDistance,
    bool? isGateway,
    DateTime? lastSeen,
    int? batteryLevel,
  }) {
    return MeshNode(
      nodeId: nodeId ?? this.nodeId,
      displayName: displayName ?? this.displayName,
      rssi: rssi ?? this.rssi,
      hopDistance: hopDistance ?? this.hopDistance,
      isGateway: isGateway ?? this.isGateway,
      lastSeen: lastSeen ?? this.lastSeen,
      batteryLevel: batteryLevel ?? this.batteryLevel,
    );
  }
}
