import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class AppHeader extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onAlertsTap;

  const AppHeader({
    super.key,
    this.isOnline = true,
    this.onAlertsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 1. SoSquad Logo & Shield Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryIndigo, AppColors.primaryPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryIndigo.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. App & Brand Names (Flexible/Expanded to prevent horizontal overflow)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Flexible(
                      child: Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.textDarkPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryIndigoLight,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        '2026',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryIndigo,
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  AppStrings.productName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textDarkSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 3. Online/Offline Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.statusOnlineLight : AppColors.emergencyRedLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOnline
                    ? AppColors.statusOnline.withOpacity(0.3)
                    : AppColors.emergencyRed.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? AppColors.statusOnline : AppColors.emergencyRed,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isOnline ? AppColors.statusOnline : AppColors.emergencyRed,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // 4. Alerts/Rescue Shortcut Icon
          InkWell(
            onTap: onAlertsTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 18,
                color: AppColors.textDarkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
