import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/hq_dashboard_notifier.dart';

class HqMetricsBar extends StatelessWidget {
  final HqDashboardNotifier notifier;

  const HqMetricsBar({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withOpacity(0.5),
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMetricCard(
              title: 'TOTAL SOS',
              value: notifier.totalCount.toString(),
              icon: Icons.list_alt_rounded,
              color: AppColors.statusStandby,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              title: 'ACTIVE INCIDENTS',
              value: notifier.activeCount.toString(),
              icon: Icons.warning_rounded,
              color: AppColors.emergencyRed,
              isPulsing: notifier.activeCount > 0,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              title: 'DISPATCHED',
              value: notifier.dispatchedCount.toString(),
              icon: Icons.local_shipping_rounded,
              color: AppColors.statusOnline,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              title: 'RESOLVED',
              value: notifier.resolvedCount.toString(),
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.statusAcknowledged,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              title: 'AVG RESPONSE TIME',
              value: notifier.avgResponseTimeFormatted,
              icon: Icons.timer_rounded,
              color: AppColors.primaryIndigo,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              title: 'ONLINE UNITS',
              value: '${notifier.onlineUnitsCount} Units',
              icon: Icons.cell_tower_rounded,
              color: AppColors.statusOnline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isPulsing = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPulsing ? color.withOpacity(0.7) : AppColors.border,
          width: isPulsing ? 1.5 : 1,
        ),
        boxShadow: [
          if (isPulsing)
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
