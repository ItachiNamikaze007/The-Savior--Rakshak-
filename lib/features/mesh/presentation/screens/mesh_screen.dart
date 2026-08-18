import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MeshScreen extends StatelessWidget {
  const MeshScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Fixed Top Header
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
                const Icon(Icons.hub_rounded, color: AppColors.primaryIndigo, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'LoRa Mesh Network',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: AppColors.textDarkPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.statusTransmittingLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.statusTransmitting.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.developer_board_rounded, size: 12, color: AppColors.statusTransmitting),
                      SizedBox(width: 4),
                      Text(
                        'READY FOR HARDWARE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.statusTransmitting,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // 1. Hardware Integration Pending Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryIndigoLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryIndigo.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primaryIndigo, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mesh Protocol Architecture Ready',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryIndigo,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'LoRa radio UART/BLE driver slot reserved. Demo topology active until hardware transceiver is connected.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Network Overview Metrics Grid
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
                  child: _buildMetricTile('Connected Nodes', '5 Ready', Icons.devices_other_rounded, AppColors.primaryIndigo),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile('Average Hops', '1.8 Hops', Icons.alt_route_rounded, AppColors.statusStandby),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile('Network Health', '98% Signal', Icons.wifi_tethering_rounded, AppColors.statusOnline),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile('HQ Gateway', 'Standby', Icons.cell_tower_rounded, AppColors.primaryPurple),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. Network Topology Visual Canvas
            const Text(
              'NETWORK TOPOLOGY DIAGRAM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textDarkMuted,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  // Top Node: HQ Gateway
                  _buildTopologyNode('HQ GATEWAY', Icons.cell_tower_rounded, AppColors.primaryPurple, 'Root Base'),
                  const SizedBox(height: 10),
                  // Connectors
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 1, height: 16, color: AppColors.primaryIndigo.withOpacity(0.5)),
                      const SizedBox(width: 60),
                      Container(width: 1, height: 16, color: AppColors.primaryIndigo.withOpacity(0.5)),
                    ],
                  ),
                  // Intermediate Nodes
                  Row(
                    children: [
                      Expanded(
                        child: _buildTopologyNode('NODE 01', Icons.router_rounded, AppColors.statusStandby, 'Rescue Alpha'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTopologyNode('NODE 02', Icons.router_rounded, AppColors.statusStandby, 'Station Bravo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Connectors
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 1, height: 16, color: AppColors.primaryIndigo.withOpacity(0.5)),
                      const SizedBox(width: 60),
                      Container(width: 1, height: 16, color: AppColors.primaryIndigo.withOpacity(0.5)),
                    ],
                  ),
                  // Bottom Node: YOU
                  _buildTopologyNode('YOU (LOCAL NODE)', Icons.phone_android_rounded, AppColors.primaryIndigo, 'NODE-AND-01', isHighlighted: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Connected Nodes List
            const Text(
              'CONNECTED MESH NODES (DEMO / SLOTS)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textDarkMuted,
              ),
            ),
            const SizedBox(height: 8),
            _buildNodeItem('HQ Command Base Gateway', 'GW-DELHI-01', '-68 dBm', 'Direct', AppColors.primaryPurple, true),
            _buildNodeItem('Field Responder Unit Alpha', 'NODE-AND-02', '-82 dBm', '1 Hop', AppColors.primaryIndigo, true),
            _buildNodeItem('Mobile Patrol Node Bravo', 'NODE-AND-03', '-95 dBm', '2 Hops', AppColors.statusStandby, true),
            _buildNodeItem('Auxiliary Repeater Station', 'NODE-REP-01', '-74 dBm', '1 Hop', AppColors.statusOnline, true),

            const SizedBox(height: 20),

            // 5. Packet Telemetry Metrics Strip
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
                  _buildPacketStat('TX Packets', '1,420', AppColors.primaryIndigo),
                  Container(width: 1, height: 28, color: AppColors.lightBorder),
                  _buildPacketStat('RX Packets', '1,398', AppColors.statusOnline),
                  Container(width: 1, height: 28, color: AppColors.lightBorder),
                  _buildPacketStat('Packet Loss', '1.5%', AppColors.textDarkSecondary),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textDarkMuted, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopologyNode(String title, IconData icon, Color color, String subtitle, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.1) : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isHighlighted ? color : AppColors.lightBorder, width: isHighlighted ? 1.5 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color), overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(fontSize: 8, color: AppColors.textDarkMuted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeItem(String name, String id, String rssi, String hops, Color color, bool isConnected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isConnected ? AppColors.statusOnline : Colors.grey),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDarkPrimary)),
                Text(id, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textDarkMuted)),
              ],
            ),
          ),
          Text(rssi, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDarkSecondary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Text(hops, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textDarkMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildPacketStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textDarkMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: color)),
      ],
    );
  }
}
