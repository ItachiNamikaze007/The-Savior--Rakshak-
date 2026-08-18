import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../sos/domain/entities/sos_request.dart';
import '../../../sos/domain/entities/sos_status.dart';
import '../../../sos/domain/repositories/i_sos_repository.dart';
import '../../../sos/presentation/providers/sos_state_notifier.dart';

class RescueScreen extends StatelessWidget {
  const RescueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sosNotifier = context.watch<SosStateNotifier>();
    final repo = context.read<ISosRepository>();
    final activeSos = sosNotifier.activeSos;
    final userDeviceId = activeSos?.deviceId ?? 'NODE-AND-01';

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
            child: const Row(
              children: [
                Icon(Icons.emergency_rounded, color: AppColors.primaryIndigo, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'My Rescue Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDarkPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable StreamBuilder Body
          Expanded(
            child: StreamBuilder<List<SosRequest>>(
              stream: repo.watchUserSosRequests(userDeviceId),
              builder: (context, snapshot) {
                final userRequests = snapshot.data ?? (activeSos != null ? [activeSos] : []);

                if (userRequests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.lightSurface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.lightBorder),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 44,
                              color: AppColors.statusOnline,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Active Distress Beacon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDarkPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your node is currently safe and on standby. If you face an emergency, hold STRICT SOS on Home.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDarkMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final latestRequest = userRequests.first;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Prominent Live Lifecycle Card
                      _buildLiveRescueCard(context, latestRequest, sosNotifier),

                      const SizedBox(height: 20),

                      // 2. Previous SOS Requests History (User-Scoped Only)
                      if (userRequests.length > 1) ...[
                        const Text(
                          'MY PAST SOS BEACONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.textDarkMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...userRequests.skip(1).map((req) => _buildPastSosTile(req)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRescueCard(
      BuildContext context, SosRequest request, SosStateNotifier notifier) {
    final isCancelled = request.status == SosStatus.cancelled;
    final statusColor = isCancelled ? AppColors.textDarkMuted : _getStatusColor(request.status);
    final humanMessage = _getHumanReadableMessage(request.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCancelled ? AppColors.lightBorder : AppColors.primaryIndigo.withOpacity(0.3),
          width: isCancelled ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Beacon ID & Type Badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE BEACON ID',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.sosId,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: AppColors.textDarkPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  _getStatusBadgeText(request.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Big Human Reassurance Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCancelled ? AppColors.lightSurfaceElevated : AppColors.primaryIndigoLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  isCancelled ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                  color: isCancelled ? AppColors.textDarkMuted : AppColors.primaryIndigo,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCancelled ? 'Emergency Stand Down' : 'Response Progress',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isCancelled ? AppColors.textDarkSecondary : AppColors.primaryIndigo,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        humanMessage,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCancelled ? AppColors.textDarkMuted : AppColors.textDarkPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Lifecycle Stepper
          _buildRescueTimeline(request.status),

          const SizedBox(height: 20),

          // Telemetry Summary Strip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTelemetryItem('COORDINATES', '${request.latitude.toStringAsFixed(4)}, ${request.longitude.toStringAsFixed(4)}'),
                _buildTelemetryItem('ACCURACY', '±${request.accuracy.toStringAsFixed(1)}m'),
                _buildTelemetryItem('TIME', DateFormat('HH:mm:ss').format(request.timestamp)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cancel / Stand Down Action Button
          if (!isCancelled)
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('STAND DOWN / CANCEL SOS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emergencyRed,
                side: const BorderSide(color: AppColors.emergencyRed),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => notifier.cancelActiveSos(),
            ),
        ],
      ),
    );
  }

  Widget _buildRescueTimeline(SosStatus status) {
    final steps = [
      {'title': 'Request Sent', 'desc': 'Beacon broadcasted from phone'},
      {'title': 'Request Seen', 'desc': 'Response center acknowledged beacon'},
      {'title': 'Team Dispatched', 'desc': 'Rescue squad deployed to location'},
      {'title': 'Team Approaching', 'desc': 'Responders nearing GPS coordinate'},
    ];

    int currentStep = 0;
    if (status == SosStatus.transmitting) currentStep = 0;
    if (status == SosStatus.acknowledged) currentStep = 1;
    if (status == SosStatus.dispatched) currentStep = 2;

    return Column(
      children: List.generate(steps.length, (index) {
        final isDone = currentStep >= index;
        final isCurrent = currentStep == index;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
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
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDarkMuted),
                          ),
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 24,
                    color: isDone ? AppColors.statusOnline : AppColors.lightBorder,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index]['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                        color: isDone ? AppColors.textDarkPrimary : AppColors.textDarkMuted,
                      ),
                    ),
                    Text(
                      steps[index]['desc'] as String,
                      style: const TextStyle(fontSize: 10, color: AppColors.textDarkMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTelemetryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textDarkMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: AppColors.textDarkPrimary)),
      ],
    );
  }

  Widget _buildPastSosTile(SosRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(req.emergencyType.icon, color: req.emergencyType.color, size: 18),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(req.sosId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                  Text(DateFormat('dd MMM yyyy, HH:mm').format(req.timestamp), style: const TextStyle(fontSize: 10, color: AppColors.textDarkMuted)),
                ],
              ),
            ],
          ),
          Text(req.status.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textDarkSecondary)),
        ],
      ),
    );
  }

  Color _getStatusColor(SosStatus status) {
    switch (status) {
      case SosStatus.pending:
      case SosStatus.transmitting:
        return AppColors.emergencyRed;
      case SosStatus.acknowledged:
        return AppColors.statusTransmitting;
      case SosStatus.dispatched:
        return AppColors.statusOnline;
      case SosStatus.cancelled:
        return AppColors.textDarkMuted;
    }
  }

  String _getStatusBadgeText(SosStatus status) {
    switch (status) {
      case SosStatus.pending:
      case SosStatus.transmitting:
        return 'TRANSMITTING';
      case SosStatus.acknowledged:
        return 'SEEN BY HQ';
      case SosStatus.dispatched:
        return 'RESCUE DISPATCHED';
      case SosStatus.cancelled:
        return 'STAND DOWN';
    }
  }

  String _getHumanReadableMessage(SosStatus status) {
    switch (status) {
      case SosStatus.pending:
      case SosStatus.transmitting:
        return 'Your emergency beacon has been broadcasted and is reaching nearby responders.';
      case SosStatus.acknowledged:
        return 'Your distress signal has been seen by the response coordination center.';
      case SosStatus.dispatched:
        return 'A rescue squad has been assigned and dispatched to your GPS location.';
      case SosStatus.cancelled:
        return 'This distress beacon was stood down / resolved.';
    }
  }
}
