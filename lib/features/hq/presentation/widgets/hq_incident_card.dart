import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../sos/domain/entities/sos_request.dart';
import '../../../sos/domain/entities/sos_status.dart';
import '../../../sos/presentation/widgets/status_badge.dart';

class HqIncidentCard extends StatelessWidget {
  final SosRequest incident;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<SosStatus> onUpdateStatus;

  const HqIncidentCard({
    super.key,
    required this.incident,
    required this.isSelected,
    required this.onTap,
    required this.onUpdateStatus,
  });

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM, HH:mm').format(dt);
  }

  void _copySosId(BuildContext context, String sosId) {
    Clipboard.setData(ClipboardData(text: sosId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.statusOnline, size: 16),
            const SizedBox(width: 8),
            Text('Copied SOS ID: $sosId'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = incident.status == SosStatus.transmitting ||
        incident.status == SosStatus.pending;
    final type = incident.emergencyType;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isSelected ? 4 : 0,
      color: isSelected
          ? AppColors.surfaceElevated
          : (isActive
              ? AppColors.emergencyRed.withOpacity(0.06)
              : AppColors.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AppColors.statusStandby
              : (isActive
                  ? AppColors.emergencyRed.withOpacity(0.7)
                  : AppColors.border),
          width: isSelected ? 2 : (isActive ? 1.5 : 1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Emergency Type, Relative Time & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Emergency Type Tag
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: type.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: type.color.withOpacity(0.4)),
                          ),
                          child: Icon(type.icon, size: 14, color: type.color),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            type.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: type.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Status Badge
                  StatusBadge(status: incident.status),
                ],
              ),

              const SizedBox(height: 10),

              // SOS ID and Timestamp Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        incident.sosId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Copy ID',
                        onPressed: () => _copySosId(context, incident.sosId),
                      ),
                    ],
                  ),
                  Text(
                    _formatRelativeTime(incident.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Location & Accuracy Row
              Row(
                children: [
                  const Icon(Icons.my_location_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${incident.latitude.toStringAsFixed(4)}, ${incident.longitude.toStringAsFixed(4)} (±${incident.accuracy.toStringAsFixed(1)}m)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Real / Mock GPS Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: incident.isSimulatedGps
                          ? AppColors.statusTransmitting.withOpacity(0.15)
                          : AppColors.statusOnline.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: incident.isSimulatedGps
                            ? AppColors.statusTransmitting.withOpacity(0.4)
                            : AppColors.statusOnline.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      incident.isSimulatedGps ? 'MOCK GPS' : 'REAL GPS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: incident.isSimulatedGps
                            ? AppColors.statusTransmitting
                            : AppColors.statusOnline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),

              // Bottom Row: Casualties & Quick Status Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Casualties
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.group_rounded, size: 14, color: AppColors.statusStandby),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            incident.injuredCount > 0
                                ? '${incident.peopleCount} Affected • ${incident.injuredCount} Injured'
                                : '${incident.peopleCount} Affected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: incident.injuredCount > 0 ? FontWeight.w800 : FontWeight.w700,
                              color: incident.injuredCount > 0 ? AppColors.emergencyRed : AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (incident.status == SosStatus.transmitting ||
                          incident.status == SosStatus.pending) ...[
                        _buildQuickActionBtn(
                          label: 'ACK',
                          color: AppColors.statusAcknowledged,
                          onPressed: () => onUpdateStatus(SosStatus.acknowledged),
                        ),
                        const SizedBox(width: 6),
                        _buildQuickActionBtn(
                          label: 'DISPATCH',
                          color: AppColors.statusOnline,
                          onPressed: () => onUpdateStatus(SosStatus.dispatched),
                        ),
                      ] else if (incident.status == SosStatus.acknowledged) ...[
                        _buildQuickActionBtn(
                          label: 'DISPATCH',
                          color: AppColors.statusOnline,
                          onPressed: () => onUpdateStatus(SosStatus.dispatched),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ),
    );
  }
}
