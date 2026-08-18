import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/hq_dashboard_notifier.dart';

class HqSidebar extends StatelessWidget {
  final HqDashboardNotifier notifier;
  final VoidCallback onBroadcastSos;

  const HqSidebar({
    super.key,
    required this.notifier,
    required this.onBroadcastSos,
  });

  static const List<_SidebarItemData> _items = [
    _SidebarItemData('Dashboard', Icons.dashboard_rounded),
    _SidebarItemData('Live SOS', Icons.sensors_rounded, showBadge: true),
    _SidebarItemData('Map View', Icons.map_rounded),
    _SidebarItemData('Incidents', Icons.emergency_share_rounded),
    _SidebarItemData('Teams', Icons.group_rounded),
    _SidebarItemData('Units', Icons.local_shipping_rounded),
    _SidebarItemData('Communication', Icons.cell_tower_rounded),
    _SidebarItemData('Analytics', Icons.analytics_rounded),
    _SidebarItemData('History', Icons.history_rounded),
    _SidebarItemData('Settings', Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final active = notifier.activeSidebarSection;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sidebar Top Brand Logo Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.emergencyRed.withOpacity(0.5)),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.emergencyRed,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SOSQUAD HQ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'COMMAND OS 2026',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.statusStandby,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Navigation List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: _items.length,
              itemBuilder: (ctx, index) {
                final item = _items[index];
                final isSelected = item.label == active;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: InkWell(
                    onTap: () => notifier.setActiveSidebarSection(item.label),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surfaceElevated
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.statusStandby.withOpacity(0.6)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 17,
                            color: isSelected
                                ? AppColors.statusStandby
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (item.showBadge && notifier.activeCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.emergencyRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${notifier.activeCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Prominent SOS Broadcast Action Button at bottom
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.emergency_share_rounded, size: 16, color: Colors.white),
              label: const Text(
                'SOS BROADCAST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
                shadowColor: AppColors.emergencyRed.withOpacity(0.5),
              ),
              onPressed: onBroadcastSos,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItemData {
  final String label;
  final IconData icon;
  final bool showBadge;

  const _SidebarItemData(this.label, this.icon, {this.showBadge = false});
}
