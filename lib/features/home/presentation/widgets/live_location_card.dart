import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../sos/presentation/providers/sos_state_notifier.dart';

class LiveLocationCard extends StatelessWidget {
  final SosStateNotifier notifier;
  final VoidCallback? onViewOnMap;

  const LiveLocationCard({
    super.key,
    required this.notifier,
    this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final location = notifier.currentLocation;
    final isLoading = notifier.isLoadingLocation;
    final hasError = notifier.locationErrorMessage != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Responsive Header Row: Icon + Title (Expanded) + Status Badge + Refresh Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.statusStandbyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  size: 16,
                  color: AppColors.statusStandby,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'LIVE GPS TELEMETRY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textDarkSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (location != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: location.isSimulated
                        ? AppColors.statusTransmittingLight
                        : AppColors.statusOnlineLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: location.isSimulated
                          ? AppColors.statusTransmitting.withOpacity(0.4)
                          : AppColors.statusOnline.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    location.isSimulated ? 'MOCK GPS' : 'REAL GPS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: location.isSimulated
                          ? AppColors.statusTransmitting
                          : AppColors.statusOnline,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryIndigo),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textDarkSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Refresh GPS Fix',
                onPressed: isLoading ? null : () => notifier.fetchLocation(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Location Grid / Content
          if (location != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCoordinateItem('LATITUDE', '${location.latitude.toStringAsFixed(4)}° N'),
                      ),
                      Expanded(
                        child: _buildCoordinateItem('LONGITUDE', '${location.longitude.toStringAsFixed(4)}° E'),
                      ),
                      Expanded(
                        child: _buildCoordinateItem('ACCURACY', '±${location.accuracy.toStringAsFixed(1)}m'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.lightBorder),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSubTelemetry(
                          Icons.access_time_rounded,
                          'Updated',
                          DateFormat('HH:mm:ss').format(location.timestamp),
                        ),
                      ),
                      Expanded(
                        child: _buildSubTelemetry(
                          Icons.speed_rounded,
                          'Speed',
                          location.speed > 0 ? '${location.speed.toStringAsFixed(1)} m/s' : '0.0 m/s',
                        ),
                      ),
                      Expanded(
                        child: _buildSubTelemetry(
                          Icons.terrain_rounded,
                          'Altitude',
                          location.altitude != 0 ? '${location.altitude.toStringAsFixed(0)}m' : 'Sea level',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // "View on Map" Action Button
            OutlinedButton.icon(
              icon: const Icon(Icons.map_rounded, size: 16),
              label: const Text('VIEW ON LIVE MAP'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryIndigo,
                side: const BorderSide(color: AppColors.primaryIndigo),
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size.fromHeight(38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onViewOnMap,
            ),
          ] else if (hasError) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.emergencyRedLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.emergencyRed.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_off_rounded, color: AppColors.emergencyRed, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notifier.locationErrorMessage!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emergencyRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emergencyRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => notifier.fetchLocation(),
                        child: const Text('RETRY GPS FIX'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDarkPrimary,
                          side: const BorderSide(color: AppColors.lightBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => notifier.openSettings(),
                        child: const Text('SETTINGS'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Acquiring real GPS satellite constellation fix...',
                        style: TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoordinateItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.textDarkMuted,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: AppColors.textDarkPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSubTelemetry(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textDarkMuted),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textDarkPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
