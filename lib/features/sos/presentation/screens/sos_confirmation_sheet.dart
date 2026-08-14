import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/emergency_type.dart';

class SosConfirmationSheet extends StatefulWidget {
  final EmergencyType emergencyType;
  final LocationData? location;
  final int peopleCount;
  final int injuredCount;
  final VoidCallback onConfirm;

  const SosConfirmationSheet({
    super.key,
    required this.emergencyType,
    required this.location,
    required this.peopleCount,
    required this.injuredCount,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required EmergencyType emergencyType,
    required LocationData? location,
    required int peopleCount,
    required int injuredCount,
    required VoidCallback onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SosConfirmationSheet(
        emergencyType: emergencyType,
        location: location,
        peopleCount: peopleCount,
        injuredCount: injuredCount,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<SosConfirmationSheet> createState() => _SosConfirmationSheetState();
}

class _SosConfirmationSheetState extends State<SosConfirmationSheet> {
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        _countdownTimer?.cancel();
        _handleConfirm();
      }
    });
  }

  void _handleConfirm() {
    _countdownTimer?.cancel();
    Navigator.of(context).pop(true);
    widget.onConfirm();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: AppColors.emergencyRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.confirmationTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Confirm details before emergency broadcast dispatch',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Summary Payload Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Emergency Type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Category:',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      Row(
                        children: [
                          Icon(widget.emergencyType.icon, size: 16, color: widget.emergencyType.color),
                          const SizedBox(width: 6),
                          Text(
                            widget.emergencyType.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: widget.emergencyType.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),

                  // GPS Coordinates
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Target GPS:',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      Text(
                        widget.location != null
                            ? '${widget.location!.latitude.toStringAsFixed(4)}, ${widget.location!.longitude.toStringAsFixed(4)}'
                            : 'No Fix (Pending)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),

                  // Casualties Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Casualty Telemetry:',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      Text(
                        '${widget.peopleCount} Affected | ${widget.injuredCount} Injured',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.statusStandby,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Dispatch Button with Auto-trigger Countdown
            ElevatedButton(
              onPressed: _handleConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'TRANSMIT NOW ($_countdownSeconds s)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Cancel Button
            OutlinedButton(
              onPressed: () {
                _countdownTimer?.cancel();
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'ABORT & RETURN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
