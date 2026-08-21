import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../features/sos/domain/entities/emergency_type.dart';
import '../../../features/sos/domain/entities/sos_request.dart';
import '../../../features/sos/domain/entities/sos_status.dart';

/// Compact, serialized packet designed for peer-to-peer BLE Mesh routing.
/// Supports Time-To-Live (TTL), multi-hop tracking, deduplication, and Gateway bridging.
class EmergencyMeshPacket {
  final String packetId;        // 16-character SHA-256 unique packet hash
  final String originDeviceId;  // Origin device identifier (e.g. NODE-AND-01)
  final double latitude;
  final double longitude;
  final double accuracy;
  final int timestamp;          // Epoch milliseconds
  final EmergencyType emergencyType;
  final int peopleCount;
  final int injuredCount;
  final SosStatus status;
  final int hopCount;           // Number of hops traversed
  final int ttl;                // Decremented at each hop to prevent broadcast storm
  final List<String> relayedByNodes; // Routing path audit trail
  final String signature;       // Cryptographic signature or hash

  const EmergencyMeshPacket({
    required this.packetId,
    required this.originDeviceId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.emergencyType,
    required this.peopleCount,
    required this.injuredCount,
    this.status = SosStatus.transmitting,
    this.hopCount = 0,
    this.ttl = 7,
    this.relayedByNodes = const [],
    this.signature = '',
  });

  /// Factory to construct a new packet from a user's SOS request
  factory EmergencyMeshPacket.fromSosRequest(
    SosRequest request, {
    int maxTtl = 7,
  }) {
    final now = request.timestamp.millisecondsSinceEpoch;
    final rawHashInput = '${request.sosId}_${request.deviceId}_$now';
    final packetId = sha256.convert(utf8.encode(rawHashInput)).toString().substring(0, 16);

    return EmergencyMeshPacket(
      packetId: packetId,
      originDeviceId: request.deviceId,
      latitude: request.latitude,
      longitude: request.longitude,
      accuracy: request.accuracy,
      timestamp: now,
      emergencyType: request.emergencyType,
      peopleCount: request.peopleCount,
      injuredCount: request.injuredCount,
      status: request.status,
      hopCount: 0,
      ttl: maxTtl,
      relayedByNodes: [request.deviceId],
      signature: 'SIG_${packetId.toUpperCase()}',
    );
  }

  /// Converts this mesh packet into an application [SosRequest]
  SosRequest toSosRequest() {
    return SosRequest(
      sosId: 'SOS_$packetId',
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      emergencyType: emergencyType,
      peopleCount: peopleCount,
      injuredCount: injuredCount,
      status: status,
      deviceId: originDeviceId,
    );
  }

  /// Creates a forwarded copy of the packet incrementing hops and decrementing TTL
  EmergencyMeshPacket createRelayCopy(String relayingNodeId) {
    return EmergencyMeshPacket(
      packetId: packetId,
      originDeviceId: originDeviceId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: timestamp,
      emergencyType: emergencyType,
      peopleCount: peopleCount,
      injuredCount: injuredCount,
      status: status,
      hopCount: hopCount + 1,
      ttl: ttl - 1,
      relayedByNodes: [...relayedByNodes, relayingNodeId],
      signature: signature,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': packetId,
    'src': originDeviceId,
    'lat': latitude,
    'lng': longitude,
    'acc': accuracy,
    'ts': timestamp,
    'type': emergencyType.name,
    'ppl': peopleCount,
    'inj': injuredCount,
    'st': status.name,
    'hop': hopCount,
    'ttl': ttl,
    'rel': relayedByNodes,
    'sig': signature,
  };

  factory EmergencyMeshPacket.fromMap(Map<String, dynamic> map) {
    return EmergencyMeshPacket(
      packetId: map['id'] as String,
      originDeviceId: map['src'] as String,
      latitude: (map['lat'] as num).toDouble(),
      longitude: (map['lng'] as num).toDouble(),
      accuracy: (map['acc'] as num).toDouble(),
      timestamp: map['ts'] as int,
      emergencyType: EmergencyType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EmergencyType.other,
      ),
      peopleCount: map['ppl'] as int? ?? 1,
      injuredCount: map['inj'] as int? ?? 0,
      status: SosStatus.values.firstWhere(
        (s) => s.name == map['st'],
        orElse: () => SosStatus.transmitting,
      ),
      hopCount: map['hop'] as int? ?? 0,
      ttl: map['ttl'] as int? ?? 7,
      relayedByNodes: (map['rel'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      signature: map['sig'] as String? ?? '',
    );
  }

  String encode() => jsonEncode(toMap());

  factory EmergencyMeshPacket.decode(String jsonString) =>
      EmergencyMeshPacket.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);
}
