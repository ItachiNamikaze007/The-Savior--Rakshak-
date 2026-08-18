import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../sos/domain/entities/sos_request.dart';
import '../../../sos/domain/entities/sos_status.dart';
import '../../../sos/presentation/widgets/status_badge.dart';

class HqIncidentDetailPanel extends StatelessWidget {
  final SosRequest incident;
  final VoidCallback onClose;
  final ValueChanged<SosStatus> onUpdateStatus;

  const HqIncidentDetailPanel({
    super.key,
    required this.incident,
    required this.onClose,
    required this.onUpdateStatus,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.statusOnline, size: 16),
            const SizedBox(width: 8),
            Text('Copied $label: $text'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = incident.emergencyType;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          left: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Panel Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.dvr_rounded, size: 18, color: AppColors.statusStandby),
                const SizedBox(width: 8),
                const Text(
                  'INCIDENT DOSSIER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                  onPressed: onClose,
                  tooltip: 'Close Details Panel',
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
                  // Emergency Type & Status Big Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: type.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: type.color.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: type.color.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(type.icon, size: 24, color: type.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.displayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: type.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              StatusBadge(status: incident.status, isLarge: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SOS ID Quick Tile
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SOS INCIDENT ID',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              incident.sosId,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: AppColors.statusStandby,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                          onPressed: () => _copyToClipboard(context, incident.sosId, 'SOS ID'),
                          tooltip: 'Copy SOS ID',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lifecycle Status Stepper
                  _buildSectionHeader('RESPONSE LIFECYCLE', Icons.timeline_rounded),
                  const SizedBox(height: 8),
                  _buildLifecycleStepper(),

                  const SizedBox(height: 16),

                  // 1. Core Incident Attributes Card
                  _buildSectionHeader('INCIDENT DETAILS & CONTACT', Icons.info_outline_rounded),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildDataRow('Category', type.displayName.toUpperCase(), valueColor: type.color),
                        const Divider(height: 12, color: AppColors.border),
                        _buildDataRow('Severity', incident.injuredCount > 0 ? 'CRITICAL (Priority 1)' : 'HIGH (Priority 2)',
                            valueColor: incident.injuredCount > 0 ? AppColors.emergencyRed : AppColors.statusStandby),
                        const Divider(height: 12, color: AppColors.border),
                        _buildDataRow('Reported User', 'Field Node (${incident.deviceId})', isMonospace: true),
                        const Divider(height: 12, color: AppColors.border),
                        _buildDataRow('Phone / Contact', 'Authorized Mesh Audio/Data', isMonospace: true, valueColor: AppColors.statusOnline),
                        const Divider(height: 12, color: AppColors.border),
                        _buildDataRow('Time', DateFormat('HH:mm:ss').format(incident.timestamp), isMonospace: true),
                        const Divider(height: 12, color: AppColors.border),
                        _buildDataRow('Elapsed', '${DateTime.now().difference(incident.timestamp).inMinutes} min ago'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Geographic Telemetry & Live GPS Tracking
                  _buildSectionHeader('LIVE GPS TRACKING', Icons.explore_rounded),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildDataRow('Latitude', '${incident.latitude.toStringAsFixed(6)}° N', isMonospace: true),
                        const Divider(height: 12, color: AppColors.border),
                        _buildDataRow('Longitude', '${incident.longitude.toStringAsFixed(6)}° E', isMonospace: true),
                        const Divider(height: 12, color: AppColors.border),
                        _buildDataRow('Accuracy Fix', '±${incident.accuracy.toStringAsFixed(1)} meters'),
                        const Divider(height: 12, color: AppColors.border),
                        _buildDataRow(
                          'GPS Lock Source',
                          incident.isSimulatedGps ? 'MOCK SIMULATION' : 'AUTHENTIC HARDWARE GPS',
                          valueColor: incident.isSimulatedGps ? AppColors.statusTransmitting : AppColors.statusOnline,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Casualty Assessment
                  _buildSectionHeader('CASUALTY ASSESSMENT', Icons.emergency_rounded),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL AFFECTED',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text('${incident.peopleCount}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32, color: AppColors.border),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('INJURED CASUALTIES',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                '${incident.injuredCount}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: incident.injuredCount > 0 ? AppColors.emergencyRed : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Quick Actions Grid (6 actions)
                  _buildSectionHeader('TACTICAL QUICK ACTIONS', Icons.bolt_rounded),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // 1. Acknowledge
                      _buildActionButton(
                        icon: Icons.verified_user_rounded,
                        label: 'Acknowledge',
                        color: AppColors.statusAcknowledged,
                        onPressed: () => onUpdateStatus(SosStatus.acknowledged),
                      ),
                      // 2. Assign Team
                      _buildActionButton(
                        icon: Icons.group_add_rounded,
                        label: 'Assign Team',
                        color: AppColors.primaryIndigo,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Assigned NDRF Alpha squad to incident ${incident.sosId}')),
                          );
                        },
                      ),
                      // 3. Dispatch Unit
                      _buildActionButton(
                        icon: Icons.local_shipping_rounded,
                        label: 'Dispatch Unit',
                        color: AppColors.statusOnline,
                        onPressed: () => onUpdateStatus(SosStatus.dispatched),
                      ),
                      // 4. Contact User
                      _buildActionButton(
                        icon: Icons.phone_in_talk_rounded,
                        label: 'Contact User',
                        color: AppColors.statusStandby,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening secure LoRa voice channel to node ${incident.deviceId}')),
                          );
                        },
                      ),
                      // 5. Navigate
                      _buildActionButton(
                        icon: Icons.navigation_rounded,
                        label: 'Navigate',
                        color: AppColors.primaryIndigo,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Target vector: ${incident.latitude.toStringAsFixed(4)}N, ${incident.longitude.toStringAsFixed(4)}E')),
                          );
                        },
                      ),
                      // 6. Escalate
                      _buildActionButton(
                        icon: Icons.priority_high_rounded,
                        label: 'Escalate',
                        color: AppColors.emergencyRed,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Incident ${incident.sosId} escalated to National Command Level')),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Stand down button
                  if (incident.status != SosStatus.cancelled)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.statusError),
                      label: const Text(
                        'STAND DOWN / CANCEL INCIDENT',
                        style: TextStyle(color: AppColors.statusError, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.statusError),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => onUpdateStatus(SosStatus.cancelled),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleStepper() {
    final status = incident.status;
    const isSent = true;
    final isAck = status == SosStatus.acknowledged || status == SosStatus.dispatched;
    final isDispatched = status == SosStatus.dispatched;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepItem('Reported', isSent, AppColors.emergencyRed),
          _buildStepLine(isAck),
          _buildStepItem('Ack', isAck, AppColors.statusAcknowledged),
          _buildStepLine(isDispatched),
          _buildStepItem('Dispatched', isDispatched, AppColors.statusOnline),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, bool isDone, Color activeColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? activeColor.withOpacity(0.2) : AppColors.surface,
            border: Border.all(
              color: isDone ? activeColor : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Icon(
            isDone ? Icons.check : Icons.circle,
            size: isDone ? 12 : 6,
            color: isDone ? activeColor : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isDone ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        color: isDone ? AppColors.statusOnline : AppColors.border,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.statusStandby),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value, {bool isMonospace = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: isMonospace ? 'monospace' : null,
              color: valueColor ?? AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
