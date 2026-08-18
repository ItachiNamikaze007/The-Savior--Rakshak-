import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class TelemetryHeader extends StatelessWidget {
  final bool isSimulatedMode;
  final ValueChanged<bool> onToggleSimulated;

  const TelemetryHeader({
    super.key,
    required this.isSimulatedMode,
    required this.onToggleSimulated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & App Name
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRedDark.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.emergencyRed, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.emergencyRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        AppStrings.productName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: AppColors.statusStandby,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // System status badge & HQ switcher
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pushNamed('/hq'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusStandby.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.statusStandby.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.dashboard_rounded, size: 12, color: AppColors.statusStandby),
                          SizedBox(width: 4),
                          Text(
                            'HQ DASHBOARD',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.statusStandby,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.statusOnline.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.statusOnline.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.statusOnline,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ONLINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusOnline,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 6),

          // Sub-bar: Simulated Mode Toggle for Emulator/Demo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.developer_mode_rounded,
                    size: 14,
                    color: isSimulatedMode ? AppColors.statusTransmitting : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Simulated GPS (Dev/Demo Mode)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSimulatedMode ? AppColors.statusTransmitting : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: isSimulatedMode,
                  activeTrackColor: AppColors.statusTransmitting,
                  onChanged: onToggleSimulated,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
