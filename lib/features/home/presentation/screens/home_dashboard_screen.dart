import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/communication/communication_manager.dart';
import '../../../map/presentation/screens/field_map_screen.dart';
import '../../../sos/presentation/providers/sos_state_notifier.dart';
import '../widgets/app_header.dart';
import '../widgets/beacon_status_card.dart';
import '../widgets/detailed_sos_button.dart';
import '../widgets/live_location_card.dart';
import '../widgets/network_status_card.dart';
import '../widgets/strict_sos_button.dart';

class HomeDashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeDashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final sosNotifier = context.watch<SosStateNotifier>();
    CommunicationManager? commManager;
    try {
      commManager = context.watch<CommunicationManager>();
    } catch (_) {}

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // 1. Top Header
          AppHeader(
            isOnline: commManager?.isInternetAvailable ?? true,
            onAlertsTap: () => onNavigateTab?.call(2), // Navigate to Rescue Tab
          ),

          // 2. Scrollable Emergency Body
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryIndigo,
              onRefresh: () => sosNotifier.fetchLocation(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 6),

                    // 2. Communication Status Card (Simple Offline / Internet)
                    NetworkStatusCard(communicationManager: commManager),

                    // 3. STRICT SOS (Visually Dominant Emergency Hold Button)
                    StrictSosButton(
                      isDispatching: sosNotifier.isDispatching,
                      hasActiveSos: sosNotifier.hasActiveSos,
                      onTrigger: () => sosNotifier.dispatchStrictSos(),
                    ),

                    // 4. DETAILED SOS (Simplified Type + Severity + Voice Note)
                    DetailedSosButton(notifier: sosNotifier),

                    // 5. Live Location Card (Real GPS Telemetry + View on Map)
                    LiveLocationCard(
                      notifier: sosNotifier,
                      onViewOnMap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FieldMapScreen(),
                          ),
                        );
                      },
                    ),

                    // 6. My SOS / Beacon Status (Lifecycle Timeline)
                    if (sosNotifier.hasActiveSos || sosNotifier.activeSos != null) ...[
                      BeaconStatusCard(
                        activeSos: sosNotifier.activeSos,
                        onCancel: () => sosNotifier.cancelActiveSos(),
                        onReset: () => sosNotifier.resetConsole(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
