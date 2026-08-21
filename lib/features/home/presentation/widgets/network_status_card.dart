import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/communication/communication_manager.dart';

class NetworkStatusCard extends StatelessWidget {
  final CommunicationManager? communicationManager;

  const NetworkStatusCard({super.key, this.communicationManager});

  @override
  Widget build(BuildContext context) {
    final isOnline = communicationManager?.isInternetAvailable ?? true;
    final isBleMeshActive = communicationManager?.isBleMeshAvailable ?? true;
    final peerCount = communicationManager?.bleMeshTransport.discoveredNodes.length ?? 4;
    final queuedCount = communicationManager?.queuedMessagesCount ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Label + Mode Pill
          Row(
            children: [
              const Icon(Icons.cell_tower_rounded, size: 16, color: AppColors.primaryIndigo),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'COMMUNICATION STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.textDarkMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.statusOnline.withOpacity(0.12) : AppColors.statusStandby.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOnline ? 'CLOUD ACTIVE' : 'MESH FAILOVER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isOnline ? AppColors.statusOnline : AppColors.statusStandby,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              // 1. BLE Mesh Multi-Hop (Offline Ready)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BLE MOBILE MESH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDarkMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isBleMeshActive
                                  ? AppColors.statusOnline
                                  : AppColors.statusTransmitting,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isBleMeshActive ? '$peerCount Peers Ready' : 'Mesh Standby',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isBleMeshActive
                                    ? AppColors.statusOnline
                                    : AppColors.statusTransmitting,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 2. Internet / Cloud Connection
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INTERNET / CLOUD',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDarkMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? AppColors.statusOnline : AppColors.emergencyRed,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isOnline
                                  ? 'Connected'
                                  : queuedCount > 0
                                      ? '$queuedCount In Queue'
                                      : 'Disconnected',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isOnline ? AppColors.statusOnline : AppColors.emergencyRed,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Dynamic Relayed Packet Indicator (if any activity)
          if (communicationManager != null &&
              communicationManager!.activeRelayStatus.isNotEmpty &&
              communicationManager!.activeRelayStatus != 'System Ready') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryIndigoLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alt_route_rounded, size: 14, color: AppColors.primaryIndigo),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      communicationManager!.activeRelayStatus,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryIndigo,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
