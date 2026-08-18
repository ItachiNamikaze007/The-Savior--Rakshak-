import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../sos/domain/entities/sos_request.dart';
import '../../../sos/domain/entities/sos_status.dart';

class BeaconStatusCard extends StatelessWidget {
  final SosRequest? activeSos;
  final VoidCallback onCancel;
  final VoidCallback onReset;

  const BeaconStatusCard({
    super.key,
    required this.activeSos,
    required this.onCancel,
    required this.onReset,
  });

  void _copySosId(BuildContext context, String id) {
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied Beacon ID: $id'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (activeSos == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.statusOnline, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BEACON STATUS: STANDBY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDarkPrimary,
                    ),
                  ),
                  Text(
                    'No active distress broadcast. Node ready for emergency.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textDarkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final sos = activeSos!;
    final isCancelled = sos.status == SosStatus.cancelled;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCancelled ? AppColors.lightSurface : AppColors.emergencyRedLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled
              ? AppColors.lightBorder
              : AppColors.emergencyRed.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCancelled ? Colors.black : AppColors.emergencyRed)
                .withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive Beacon ID Row (Expanded to prevent overflow)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? AppColors.textDarkMuted.withOpacity(0.1)
                      : AppColors.emergencyRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.radar_rounded,
                  size: 16,
                  color: isCancelled ? AppColors.textDarkMuted : AppColors.emergencyRed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BEACON ID',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDarkMuted,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sos.sosId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              color: AppColors.textDarkPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          padding: const EdgeInsets.only(left: 4),
                          constraints: const BoxConstraints(),
                          onPressed: () => _copySosId(context, sos.sosId),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? AppColors.lightSurfaceElevated
                      : AppColors.emergencyRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sos.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isCancelled ? AppColors.textDarkSecondary : Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lifecycle Step Timeline (Responsive)
          _buildLifecycleTimeline(sos.status),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              if (!isCancelled)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('STAND DOWN / CANCEL SOS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emergencyRed,
                      side: const BorderSide(color: AppColors.emergencyRed),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onCancel,
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('RESET CONSOLE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryIndigo,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onReset,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleTimeline(SosStatus currentStatus) {
    final steps = [
      {'label': 'Sent', 'status': SosStatus.pending},
      {'label': 'Transmitted', 'status': SosStatus.transmitting},
      {'label': 'Acknowledged', 'status': SosStatus.acknowledged},
      {'label': 'Dispatched', 'status': SosStatus.dispatched},
    ];

    int activeIndex = 0;
    if (currentStatus == SosStatus.transmitting) activeIndex = 1;
    if (currentStatus == SosStatus.acknowledged) activeIndex = 2;
    if (currentStatus == SosStatus.dispatched) activeIndex = 3;
    if (currentStatus == SosStatus.cancelled) activeIndex = -1;

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector Line
          final stepBefore = index ~/ 2;
          final isPassed = activeIndex > stepBefore;
          return Expanded(
            child: Container(
              height: 2,
              color: isPassed ? AppColors.statusOnline : AppColors.lightBorder,
            ),
          );
        } else {
          // Step Node
          final stepIndex = index ~/ 2;
          final isDone = activeIndex >= stepIndex;
          final isCurrent = activeIndex == stepIndex;

          return SizedBox(
            width: 48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.statusOnline : AppColors.lightSurfaceElevated,
                    border: Border.all(
                      color: isDone ? AppColors.statusOnline : AppColors.lightBorder,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : Text(
                            '${stepIndex + 1}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDarkMuted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  steps[stepIndex]['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    color: isDone ? AppColors.textDarkPrimary : AppColors.textDarkMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }
      }),
    );
  }
}
