import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../sos/domain/entities/sos_status.dart';
import '../providers/hq_dashboard_notifier.dart';

class HqBottomPanel extends StatefulWidget {
  final HqDashboardNotifier notifier;
  final double height;

  const HqBottomPanel({super.key, required this.notifier, this.height = 170});

  @override
  State<HqBottomPanel> createState() => _HqBottomPanelState();
}

class _HqBottomPanelState extends State<HqBottomPanel> {
  int _activeTab = 0;

  static const List<String> _tabs = [
    'TEAM STATUS',
    'RECENT ACTIVITY',
    'CURRENT ASSIGNMENTS',
    'RESPONSE ANALYTICS',
  ];

  @override
  Widget build(BuildContext context) {
    final notifier = widget.notifier;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                ...List.generate(_tabs.length, (index) {
                  final isSelected = _activeTab == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _activeTab = index),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.surface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.statusStandby
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          _tabs[index],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isSelected
                                ? AppColors.statusStandby
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                const Row(
                  children: [
                    Icon(Icons.sensors_rounded, size: 12, color: AppColors.statusOnline),
                    SizedBox(width: 4),
                    Text(
                      'TELEMETRY SYNCED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.statusOnline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Content (Shown when height is sufficient)
          if (widget.height >= 120)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildActiveTabContent(notifier),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(HqDashboardNotifier notifier) {
    switch (_activeTab) {
      case 0:
        return _buildTeamStatusContent(notifier);
      case 1:
        return _buildRecentActivityContent(notifier);
      case 2:
        return _buildCurrentAssignmentsContent(notifier);
      case 3:
      default:
        return _buildResponseAnalyticsContent(notifier);
    }
  }

  // 1. Team Status Tab
  Widget _buildTeamStatusContent(HqDashboardNotifier notifier) {
    final teams = [
      {'name': 'NDRF Alpha (Search & Rescue)', 'status': 'DEPLOYED', 'color': AppColors.statusOnline, 'loc': 'Sector 4'},
      {'name': 'SDRF Quick Response Unit', 'status': 'STANDBY', 'color': AppColors.statusStandby, 'loc': 'Base HQ'},
      {'name': 'Mobile Emergency Medical Squad', 'status': 'EN ROUTE', 'color': AppColors.emergencyRed, 'loc': 'Sector 2'},
      {'name': 'RAKSHAK Drone Recon Unit', 'status': 'AIRBORNE', 'color': AppColors.statusOnline, 'loc': 'Sector 4 Grid B'},
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: teams.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (ctx, index) {
        final t = teams[index];
        final color = t['color'] as Color;

        return Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      t['name'] as String,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(
                      t['status'] as String,
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Location: ${t['loc']}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.radio_button_checked_rounded, size: 12, color: AppColors.statusOnline),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. Recent Activity Tab (Real incident history from notifier)
  Widget _buildRecentActivityContent(HqDashboardNotifier notifier) {
    final incidents = notifier.allIncidents;

    if (incidents.isEmpty) {
      return const Center(
        child: Text(
          'No recent system activity recorded.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: incidents.length > 6 ? 6 : incidents.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (ctx, index) {
        final incident = incidents[index];
        final timeStr = DateFormat('HH:mm:ss').format(incident.timestamp);

        return Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    incident.sosId,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: AppColors.statusStandby),
                  ),
                  Text(timeStr, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
              Text(
                '${incident.emergencyType.displayName.toUpperCase()} • Status: ${incident.status.displayName}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Node: ${incident.deviceId} • ±${incident.accuracy.toStringAsFixed(0)}m accuracy',
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. Current Assignments Tab
  Widget _buildCurrentAssignmentsContent(HqDashboardNotifier notifier) {
    final dispatched = notifier.allIncidents.where((i) => i.status == SosStatus.dispatched).toList();

    if (dispatched.isEmpty) {
      return const Center(
        child: Text(
          'No active rescue squads currently deployed in field.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: dispatched.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (ctx, index) {
        final item = dispatched[index];
        return Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.statusOnline.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ASSIGNED: ${item.sosId}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.statusOnline),
                  ),
                  const Icon(Icons.local_shipping_rounded, size: 14, color: AppColors.statusOnline),
                ],
              ),
              Text(
                'Target Coordinates: ${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textSecondary),
              ),
              Text(
                'Affected: ${item.peopleCount} civilians (${item.injuredCount} injured)',
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. Response Analytics Tab
  Widget _buildResponseAnalyticsContent(HqDashboardNotifier notifier) {
    return Row(
      children: [
        _buildAnalyticsTile('DISASTER TRIAGE RATE', '${notifier.totalCount > 0 ? ((notifier.acknowledgedCount + notifier.dispatchedCount) / notifier.totalCount * 100).toStringAsFixed(0) : '100'}%', AppColors.statusOnline),
        const SizedBox(width: 12),
        _buildAnalyticsTile('AVG RESPONSE TIME', notifier.avgResponseTimeFormatted, AppColors.statusStandby),
        const SizedBox(width: 12),
        _buildAnalyticsTile('CASUALTY EVACUATION', '${notifier.totalPeopleAffected} Total', AppColors.emergencyRed),
        const SizedBox(width: 12),
        _buildAnalyticsTile('COMM CHANNEL INTEGRITY', '100% (LoRa + Mesh)', AppColors.statusOnline),
      ],
    );
  }

  Widget _buildAnalyticsTile(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: color)),
            const Text('Realtime Telemetry Stream', style: TextStyle(fontSize: 8, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
