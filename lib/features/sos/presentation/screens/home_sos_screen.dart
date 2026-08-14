import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/sos_state_notifier.dart';
import '../widgets/emergency_type_selector.dart';
import '../widgets/gps_telemetry_card.dart';
import '../widgets/people_counter_card.dart';
import '../widgets/pulsing_sos_button.dart';
import '../widgets/telemetry_header.dart';
import 'active_sos_broadcast_screen.dart';
import 'sos_confirmation_sheet.dart';

class HomeSosScreen extends StatelessWidget {
  const HomeSosScreen({super.key});

  void _handleSosTrigger(BuildContext context) {
    final notifier = context.read<SosStateNotifier>();

    if (notifier.isLoadingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acquiring high-accuracy GPS fix... Please wait a moment.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!notifier.hasLocation && !notifier.isSimulatedMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusError,
          content: const Text(
            'GPS coordinates unavailable. Please enable GPS or switch to Simulated Mode for testing.',
          ),
          action: SnackBarAction(
            label: 'SIMULATE',
            textColor: Colors.white,
            onPressed: () => notifier.toggleSimulatedMode(true),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Show Confirmation Sheet
    SosConfirmationSheet.show(
      context,
      emergencyType: notifier.selectedEmergencyType,
      location: notifier.currentLocation,
      peopleCount: notifier.peopleCount,
      injuredCount: notifier.injuredCount,
      onConfirm: () async {
        try {
          await notifier.dispatchDistressSignal();
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ActiveSosBroadcastScreen(),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.statusError,
                content: Text('Dispatch Failed: $e'),
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SosStateNotifier>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Mission Telemetry Header
              TelemetryHeader(
                isSimulatedMode: notifier.isSimulatedMode,
                onToggleSimulated: (val) => notifier.toggleSimulatedMode(val),
              ),

              const SizedBox(height: 12),

              // 2. Active SOS Persistent Quick Access Banner (if active)
              if (notifier.hasActiveSos) ...[
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ActiveSosBroadcastScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRedDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.emergencyRed),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.emergencyRed,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ACTIVE BEACON BROADCASTING',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emergencyRed,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                '${notifier.activeSos!.sosId} • ${notifier.activeSos!.status.displayName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.emergencyRed,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 3. Live GPS Telemetry Card
              GpsTelemetryCard(
                location: notifier.currentLocation,
                isLoading: notifier.isLoadingLocation,
                errorMessage: notifier.locationErrorMessage,
                errorCode: notifier.locationErrorCode,
                onRefresh: () => notifier.fetchLocation(),
                onOpenSettings: () => notifier.openSettings(),
                onEnableSimulated: () => notifier.toggleSimulatedMode(true),
              ),

              const SizedBox(height: 14),

              // 4. Emergency Type Grid Selector
              EmergencyTypeSelector(
                selectedType: notifier.selectedEmergencyType,
                onSelected: (type) => notifier.setEmergencyType(type),
              ),

              const SizedBox(height: 14),

              // 5. Casualty & Population Counter
              PeopleCounterCard(
                peopleCount: notifier.peopleCount,
                injuredCount: notifier.injuredCount,
                onIncrementPeople: () => notifier.incrementPeople(),
                onDecrementPeople: () => notifier.decrementPeople(),
                onSetPeople: (c) => notifier.setPeopleCount(c),
                onIncrementInjured: () => notifier.incrementInjured(),
                onDecrementInjured: () => notifier.decrementInjured(),
                onSetInjured: (c) => notifier.setInjuredCount(c),
              ),

              const SizedBox(height: 24),

              // 6. Primary Glowing Radar Pulsing SOS Trigger Button
              PulsingSosButton(
                onPressed: () => _handleSosTrigger(context),
                isEnabled: !notifier.isDispatching,
              ),

              const SizedBox(height: 12),

              // Subtext helper
              const Center(
                child: Text(
                  AppStrings.tapToTrigger,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
