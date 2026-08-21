import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/communication/ble_mesh_transport.dart';
import '../../../../core/services/communication/communication_manager.dart';
import '../../../../core/services/communication/network_connectivity_service.dart';
import '../../../../core/services/mesh/emergency_mesh_packet.dart';
import '../../../../core/services/mesh/mesh_node.dart';
import '../../../sos/domain/entities/emergency_type.dart';

class MeshScreen extends StatelessWidget {
  const MeshScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final commManager = context.watch<CommunicationManager>();
    final bleTransport = commManager.bleMeshTransport;
    final isOnline = commManager.isInternetAvailable;
    final nodes = bleTransport.discoveredNodes;
    final logs = bleTransport.logs;
    final stats = bleTransport.statistics;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // 1. Fixed Top Header with Mode & Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(color: AppColors.lightBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub_rounded, color: AppColors.primaryIndigo, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BLE Mobile Mesh Network',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: AppColors.textDarkPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Autonomous Multi-Hop Data Relay (Zero Internet)',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textDarkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppColors.statusOnline.withOpacity(0.12)
                        : AppColors.statusStandby.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isOnline
                          ? AppColors.statusOnline.withOpacity(0.4)
                          : AppColors.statusStandby.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.cloud_done_rounded : Icons.sensors_rounded,
                        size: 12,
                        color: isOnline ? AppColors.statusOnline : AppColors.statusStandby,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? 'CLOUD ACTIVE' : 'MESH RELAY ACTIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isOnline ? AppColors.statusOnline : AppColors.statusStandby,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner: Auto-Failover Information & Quick Simulator Controls
                  _buildFailoverBanner(context, commManager, isOnline),

                  const SizedBox(height: 16),

                  // 3. Network Overview Metrics Grid
                  const Text(
                    'NETWORK OVERVIEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textDarkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Connected Peers',
                          '${nodes.length} Active',
                          Icons.devices_other_rounded,
                          AppColors.primaryIndigo,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Max Mesh Hops',
                          '7 Max TTL',
                          Icons.alt_route_rounded,
                          AppColors.statusStandby,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Mesh Protocol',
                          'BLE GATT Relay',
                          Icons.bluetooth_audio_rounded,
                          AppColors.statusOnline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Gateway Sync',
                          isOnline ? 'Local Bridge' : 'GW-DELHI-01',
                          Icons.cell_tower_rounded,
                          AppColors.primaryPurple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. Visual Multi-Hop Topology Diagram
                  const Text(
                    'MULTI-HOP ROUTING TOPOLOGY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textDarkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTopologyCard(isOnline),

                  const SizedBox(height: 20),

                  // 5. Connected Mesh Nodes List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DISCOVERED MESH NODES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textDarkMuted,
                        ),
                      ),
                      Text(
                        '${nodes.length} IN RANGE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryIndigo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...nodes.map((node) => _buildNodeItem(node)),

                  const SizedBox(height: 20),

                  // 6. Packet Telemetry & Performance
                  const Text(
                    'PACKET TELEMETRY & TRAFFIC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textDarkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPacketStat('TX Packets', '${stats.txPackets}', AppColors.primaryIndigo),
                        Container(width: 1, height: 28, color: AppColors.lightBorder),
                        _buildPacketStat('RX Packets', '${stats.rxPackets}', AppColors.statusOnline),
                        Container(width: 1, height: 28, color: AppColors.lightBorder),
                        _buildPacketStat('Relayed', '${stats.relayedPackets}', AppColors.statusStandby),
                        Container(width: 1, height: 28, color: AppColors.lightBorder),
                        _buildPacketStat('Drops/Loops', '${stats.droppedPackets}', AppColors.textDarkSecondary),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 7. Live Packet Routing Activity Log
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LIVE PACKET RELAY LOG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textDarkMuted,
                        ),
                      ),
                      if (logs.isNotEmpty)
                        Text(
                          '${logs.length} EVENTS',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDarkMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildLogConsole(logs, bleTransport),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailoverBanner(
    BuildContext context,
    CommunicationManager commManager,
    bool isOnline,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.primaryIndigoLight.withOpacity(0.7)
            : AppColors.statusStandby.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? AppColors.primaryIndigo.withOpacity(0.3)
              : AppColors.statusStandby.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOnline ? Icons.bolt_rounded : Icons.offline_bolt_rounded,
                color: isOnline ? AppColors.primaryIndigo : AppColors.statusStandby,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOnline
                      ? 'Smart Auto-Failover System: Online'
                      : 'Internet Lost — Active BLE Mesh Multi-Hop Mode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isOnline ? AppColors.primaryIndigo : AppColors.textDarkPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isOnline
                ? 'Packets transmit to Cloud. If internet fails, signals automatically route through nearby mobile nodes via BLE.'
                : 'Zero internet detected. Emergency signals are flooding locally across intermediate nodes to reach internet gateways.',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textDarkSecondary,
            ),
          ),
          const SizedBox(height: 10),
          // Interactive Simulation Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InkWell(
                onTap: () {
                  commManager.networkService.setSimulatedStatus(
                    isOnline ? NetworkStatus.offline : NetworkStatus.online,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.emergencyRed.withOpacity(0.1) : AppColors.statusOnline.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOnline ? AppColors.emergencyRed : AppColors.statusOnline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                        size: 14,
                        color: isOnline ? AppColors.emergencyRed : AppColors.statusOnline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? 'Simulate Internet Drop' : 'Restore Internet Connection',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isOnline ? AppColors.emergencyRed : AppColors.statusOnline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  // Simulate receiving a packet from a peer
                  final samplePacket = EmergencyMeshPacket(
                    packetId: 'SIM_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    originDeviceId: 'NODE-AND-03',
                    latitude: 28.6139,
                    longitude: 77.2090,
                    accuracy: 5.0,
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    emergencyType: EmergencyType.medical,
                    peopleCount: 2,
                    injuredCount: 1,
                    hopCount: 1,
                    ttl: 6,
                    relayedByNodes: ['NODE-AND-03', 'NODE-AND-02'],
                  );
                  commManager.bleMeshTransport.receiveMeshPacket(samplePacket);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryIndigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryIndigo),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.forward_to_inbox_rounded, size: 14, color: AppColors.primaryIndigo),
                      SizedBox(width: 4),
                      Text(
                        'Simulate Peer SOS Hop',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryIndigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopologyCard(bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          // Top Node: HQ Cloud Gateway
          _buildTopologyNode(
            'HQ COMMAND CLOUD',
            Icons.cloud_sync_rounded,
            AppColors.primaryPurple,
            'Final Dispatch Destination',
            isHighlighted: isOnline,
          ),
          const SizedBox(height: 8),
          // Connector
          Container(width: 1.5, height: 16, color: AppColors.primaryIndigo.withOpacity(0.5)),
          const SizedBox(height: 8),

          // Intermediate Gateway Node
          _buildTopologyNode(
            'GW-DELHI-01 (GATEWAY NODE)',
            Icons.cell_tower_rounded,
            AppColors.statusOnline,
            'Internet Uplink Bridge',
          ),
          const SizedBox(height: 8),
          // Branching connectors
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 1.5, height: 16, color: AppColors.primaryIndigo.withOpacity(0.5)),
              const SizedBox(width: 80),
              Container(width: 1.5, height: 16, color: AppColors.primaryIndigo.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 8),

          // Intermediate Relay Nodes (Hop 1 & Hop 2)
          Row(
            children: [
              Expanded(
                child: _buildTopologyNode(
                  'NODE-AND-02',
                  Icons.router_rounded,
                  AppColors.statusStandby,
                  'Relay Unit Alpha (Hop 1)',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTopologyNode(
                  'NODE-AND-03',
                  Icons.router_rounded,
                  AppColors.statusStandby,
                  'Patrol Node Bravo (Hop 2)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Connector to Local Node
          Container(width: 1.5, height: 16, color: AppColors.primaryIndigo.withOpacity(0.5)),
          const SizedBox(height: 8),

          // Origin Device
          _buildTopologyNode(
            'YOU (LOCAL NODE-AND-01)',
            Icons.phone_android_rounded,
            AppColors.primaryIndigo,
            'Origin & Mesh Relayer',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTopologyNode(
    String title,
    IconData icon,
    Color color,
    String subtitle, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.12) : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? color : AppColors.lightBorder,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9, color: AppColors.textDarkMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeItem(MeshNode node) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: node.isGateway ? AppColors.primaryPurple : AppColors.statusOnline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      node.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDarkPrimary,
                      ),
                    ),
                    if (node.isGateway) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'GATEWAY',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${node.nodeId} • ${node.signalQualityLabel} • ${node.batteryLevel}% Bat',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppColors.textDarkMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${node.rssi} dBm',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textDarkSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Text(
              node.hopDistance == 1 ? 'Direct' : '${node.hopDistance} Hops',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.textDarkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textDarkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacketStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.textDarkMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLogConsole(List<MeshPacketLog> logs, BleMeshTransport bleTransport) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorder),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Mesh ready. No packet transmissions yet.',
          style: TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: logs.take(6).map((log) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.timestamp,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.message,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      fontWeight: log.isGatewayAction ? FontWeight.w900 : FontWeight.w500,
                      color: log.isGatewayAction
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
