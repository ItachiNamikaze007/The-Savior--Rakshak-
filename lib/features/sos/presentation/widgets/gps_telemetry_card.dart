import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/services/location_service.dart';

class GpsTelemetryCard extends StatelessWidget {
  final LocationData? location;
  final bool isLoading;
  final String? errorMessage;
  final LocationErrorCode? errorCode;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSettings;
  final VoidCallback onEnableSimulated;

  const GpsTelemetryCard({
    super.key,
    required this.location,
    required this.isLoading,
    required this.errorMessage,
    required this.errorCode,
    required this.onRefresh,
    required this.onOpenSettings,
    required this.onEnableSimulated,
  });

  String _formatCoordinate(double val, bool isLat) {
    final dir = isLat ? (val >= 0 ? 'N' : 'S') : (val >= 0 ? 'E' : 'W');
    return '${val.abs().toStringAsFixed(5)}° $dir';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: errorMessage != null ? AppColors.statusError.withOpacity(0.6) : AppColors.border,
          width: errorMessage != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    errorMessage != null
                        ? Icons.location_off_rounded
                        : Icons.my_location_rounded,
                    size: 18,
                    color: errorMessage != null
                        ? AppColors.statusError
                        : AppColors.statusOnline,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    AppStrings.liveGps,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (location?.isSimulated == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.statusTransmitting.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.statusTransmitting.withOpacity(0.6)),
                      ),
                      child: const Text(
                        'SIMULATED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.statusTransmitting,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.statusStandby,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20, color: AppColors.statusStandby),
                onPressed: isLoading ? null : onRefresh,
                tooltip: 'Refresh GPS Fix',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content body
          if (isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.statusStandby,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      AppStrings.acquiringGps,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (errorMessage != null) ...[
            // Error handling state
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusError.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusError.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.statusError),
                      const SizedBox(width: 8),
                      Text(
                        _getErrorTitle(errorCode),
                        style: const TextStyle(
                          color: AppColors.statusError,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.settings, size: 14),
                        label: Text(
                          errorCode == LocationErrorCode.serviceDisabled
                              ? 'ENABLE LOCATION'
                              : 'OPEN PERMISSIONS',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        onPressed: onOpenSettings,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: const BorderSide(color: AppColors.statusTransmitting),
                        ),
                        onPressed: onEnableSimulated,
                        child: const Text(
                          'USE MOCK GPS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.statusTransmitting,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (location != null) ...[
            // Location Available
            Row(
              children: [
                // Latitude
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LATITUDE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCoordinate(location!.latitude, true),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                Container(width: 1, height: 32, color: AppColors.border),
                const SizedBox(width: 16),

                // Longitude
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LONGITUDE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCoordinate(location!.longitude, false),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),

            // Metadata footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded, size: 12, color: AppColors.statusOnline),
                    const SizedBox(width: 4),
                    Text(
                      'Accuracy: ±${location!.accuracy.toStringAsFixed(1)}m',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusOnline,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Updated ${DateFormat('HH:mm:ss').format(location!.timestamp)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ] else ...[
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_searching, size: 16),
                label: const Text('ACQUIRE GPS LOCATION'),
                onPressed: onRefresh,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getErrorTitle(LocationErrorCode? code) {
    switch (code) {
      case LocationErrorCode.serviceDisabled:
        return 'GPS Hardware Disabled';
      case LocationErrorCode.permissionDenied:
        return 'Location Permission Denied';
      case LocationErrorCode.permissionDeniedForever:
        return 'Permission Permanently Blocked';
      case LocationErrorCode.timeout:
        return 'Satellite Lock Timeout';
      default:
        return 'Location Unavailable';
    }
  }
}
