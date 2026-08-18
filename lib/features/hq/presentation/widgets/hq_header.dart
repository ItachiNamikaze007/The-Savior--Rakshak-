import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../sos/presentation/screens/home_sos_screen.dart';
import '../providers/hq_dashboard_notifier.dart';

class HqHeader extends StatefulWidget {
  final HqDashboardNotifier notifier;
  final VoidCallback? onToggleFieldView;

  const HqHeader({
    super.key,
    required this.notifier,
    this.onToggleFieldView,
  });

  @override
  State<HqHeader> createState() => _HqHeaderState();
}

class _HqHeaderState extends State<HqHeader> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = widget.notifier;
    final isConnected = notifier.isFirebaseConnected;
    final utcTime = _currentTime.toUtc();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Branding & Tactical Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.emergencyRed, AppColors.emergencyRedDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emergencyRed.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    const Text(
                      'SoSquad HQ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.statusStandby.withOpacity(0.5)),
                      ),
                      child: const Text(
                        '2026',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppColors.statusStandby,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.statusOnline.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.statusOnline.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'Live Emergency Operations',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.statusOnline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'RAKSHAK-NET Command Center • Hybrid Disaster Response Coordination',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // 2. System Online Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.statusOnline.withOpacity(0.12)
                  : AppColors.statusError.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConnected
                    ? AppColors.statusOnline.withOpacity(0.4)
                    : AppColors.statusError.withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected
                        ? AppColors.statusOnline
                        : AppColors.statusError,
                    boxShadow: [
                      BoxShadow(
                        color: (isConnected
                                ? AppColors.statusOnline
                                : AppColors.statusError)
                            .withOpacity(0.8),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? 'System Online' : 'System Offline',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isConnected
                        ? AppColors.statusOnline
                        : AppColors.statusError,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 3. Notifications Bell
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.textPrimary),
                  tooltip: 'Notifications',
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications: All telemetry channels operating at peak efficiency.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                if (notifier.activeCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.emergencyRed,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 4. HQ Operator Profile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.statusStandby,
                  child: Icon(Icons.person_rounded, size: 14, color: Colors.black),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HQ Operator',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      'Cdr. S. Sharma',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 5. Mission UTC & Local Dual Clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: AppColors.statusStandby),
                const SizedBox(width: 5),
                Text(
                  DateFormat('HH:mm:ss').format(_currentTime),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 3),
                const Text(
                  'LOC',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Container(width: 1, height: 10, color: AppColors.border),
                const SizedBox(width: 6),
                Text(
                  DateFormat('HH:mm:ss').format(utcTime),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 3),
                const Text(
                  'UTC',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // 4. Switch to Field App Console Button
          OutlinedButton.icon(
            icon: const Icon(Icons.phone_android_rounded, size: 16),
            label: const Text('FIELD CONSOLE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: widget.onToggleFieldView ??
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HomeSosScreen(),
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }
}
