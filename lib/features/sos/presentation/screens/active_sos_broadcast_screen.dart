import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/sos_status.dart';
import '../providers/sos_state_notifier.dart';
import '../widgets/status_badge.dart';

class ActiveSosBroadcastScreen extends StatefulWidget {
  const ActiveSosBroadcastScreen({super.key});

  @override
  State<ActiveSosBroadcastScreen> createState() => _ActiveSosBroadcastScreenState();
}

class _ActiveSosBroadcastScreenState extends State<ActiveSosBroadcastScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _copySosId(String sosId) {
    Clipboard.setData(ClipboardData(text: sosId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.statusOnline, size: 18),
            const SizedBox(width: 8),
            Text('SOS ID copied: $sosId'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showCancelConfirmation(BuildContext context, SosStateNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.statusError),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.statusError),
            SizedBox(width: 8),
            Text(
              'Cancel SOS Beacon?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this emergency broadcast? This will notify Command HQ that the distress situation has been stood down.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('NO, KEEP ACTIVE', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('CONFIRM CANCEL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.cancelActiveSos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SosStateNotifier>();
    final activeSos = notifier.activeSos;

    if (activeSos == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('No Active SOS')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.backToConsole),
          ),
        ),
      );
    }

    final isAcknowledged = activeSos.status == SosStatus.acknowledged;
    final isCancelled = activeSos.status == SosStatus.cancelled;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.activeDistressBeacon,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Radar Visual Header
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated concentric radar ring
                  if (!isCancelled)
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        return Container(
                          width: 140 * _radarController.value + 40,
                          height: 140 * _radarController.value + 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (isAcknowledged ? AppColors.statusOnline : AppColors.emergencyRed)
                                  .withOpacity(1.0 - _radarController.value),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),

                  // Center icon node
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCancelled
                          ? AppColors.surfaceElevated
                          : (isAcknowledged
                              ? AppColors.statusOnline.withOpacity(0.2)
                              : AppColors.emergencyRed.withOpacity(0.2)),
                      border: Border.all(
                        color: isCancelled
                            ? AppColors.textMuted
                            : (isAcknowledged ? AppColors.statusOnline : AppColors.emergencyRed),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isAcknowledged ? AppColors.statusOnline : AppColors.emergencyRed)
                              .withOpacity(0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      isCancelled
                          ? Icons.cancel_outlined
                          : (isAcknowledged ? Icons.verified_user_rounded : Icons.sensors_rounded),
                      size: 44,
                      color: isCancelled
                          ? AppColors.textMuted
                          : (isAcknowledged ? AppColors.statusOnline : AppColors.emergencyRed),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status Badge Center
            Center(
              child: StatusBadge(status: activeSos.status, isLarge: true),
            ),

            const SizedBox(height: 20),

            // SOS ID Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INCIDENT / SOS ID',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeSos.sosId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColors.statusStandby,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.statusStandby),
                    onPressed: () => _copySosId(activeSos.sosId),
                    tooltip: 'Copy SOS ID',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Incident Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.dashboard_customize_rounded, size: 16, color: AppColors.statusStandby),
                      SizedBox(width: 8),
                      Text(
                        'INCIDENT TELEMETRY PAYLOAD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Row: Emergency Type & Status
                  _buildDetailRow(
                    label: 'Emergency Category',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(activeSos.emergencyType.icon, size: 16, color: activeSos.emergencyType.color),
                        const SizedBox(width: 6),
                        Text(
                          activeSos.emergencyType.displayName.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: activeSos.emergencyType.color,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: AppColors.border, height: 16),

                  // Row: GPS Coordinates
                  _buildDetailRow(
                    label: 'GPS Distress Fix',
                    value: '${activeSos.latitude.toStringAsFixed(5)}, ${activeSos.longitude.toStringAsFixed(5)}',
                    isMonospace: true,
                  ),

                  const Divider(color: AppColors.border, height: 16),

                  // Row: Casualties
                  _buildDetailRow(
                    label: 'Casualty Count',
                    value: '${activeSos.peopleCount} Affected  |  ${activeSos.injuredCount} Injured',
                  ),

                  const Divider(color: AppColors.border, height: 16),

                  // Row: Timestamp
                  _buildDetailRow(
                    label: 'Dispatched Timestamp',
                    value: DateFormat('yyyy-MM-dd HH:mm:ss').format(activeSos.timestamp),
                    isMonospace: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Live Telemetry Event Timeline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRANSMISSION TIMELINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTimelineItem(
                    title: 'Distress Beacon Generated',
                    subtitle: 'Payload encrypted and assigned ID ${activeSos.sosId}',
                    isCompleted: true,
                  ),
                  _buildTimelineItem(
                    title: 'Disaster Network Broadcast',
                    subtitle: 'Transmitting telemetry to emergency mesh...',
                    isCompleted: true,
                  ),
                  _buildTimelineItem(
                    title: 'Command HQ Handshake',
                    subtitle: isAcknowledged
                        ? 'Response acknowledged by emergency coordination dashboard.'
                        : (isCancelled
                            ? 'Beacon transmission cancelled by user.'
                            : 'Awaiting acknowledgment from HQ...'),
                    isCompleted: isAcknowledged,
                    isCurrent: !isAcknowledged && !isCancelled,
                    isFailed: isCancelled,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            if (!isCancelled) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_rounded, color: AppColors.statusError),
                label: const Text(
                  AppStrings.cancelSos,
                  style: TextStyle(
                    color: AppColors.statusError,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.statusError, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _showCancelConfirmation(context, notifier),
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('STAND DOWN & RESET CONSOLE'),
                onPressed: () {
                  notifier.resetConsole();
                  Navigator.of(context).pop();
                },
              ),
            ],

            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                AppStrings.backToConsole,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    String? value,
    Widget? valueWidget,
    bool isMonospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        if (valueWidget != null)
          valueWidget
        else
          Text(
            value ?? '',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isCurrent = false,
    bool isFailed = false,
  }) {
    Color dotColor = AppColors.border;
    if (isFailed) {
      dotColor = AppColors.statusError;
    } else if (isCompleted) {
      dotColor = AppColors.statusOnline;
    } else if (isCurrent) {
      dotColor = AppColors.statusTransmitting;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: (isCompleted || isCurrent)
                  ? [BoxShadow(color: dotColor.withOpacity(0.5), blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
