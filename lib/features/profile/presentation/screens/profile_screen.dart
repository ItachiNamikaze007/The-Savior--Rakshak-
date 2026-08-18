import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/communication/communication_manager.dart';
import '../../../sos/presentation/providers/sos_state_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _hapticsEnabled = true;
  String _selectedLanguage = 'English (EN)';

  @override
  Widget build(BuildContext context) {
    final sosNotifier = context.watch<SosStateNotifier>();
    CommunicationManager? commManager;
    try {
      commManager = context.watch<CommunicationManager>();
    } catch (_) {}

    final hasGpsFix = sosNotifier.currentLocation != null;
    final isOnline = commManager?.isInternetAvailable ?? true;
    final isLoraAvailable = commManager?.isLoraAvailable ?? false;

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
                Icon(Icons.person_rounded, color: AppColors.primaryIndigo, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'User Profile & Device',
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

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. USER SECTION
                  _buildSectionHeader('USER IDENTITY'),
                  const SizedBox(height: 8),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildDisplayTile(
                          icon: Icons.badge_outlined,
                          iconColor: AppColors.primaryIndigo,
                          title: 'Responder Name',
                          value: 'Inspector Sharma (Field Node)',
                        ),
                        const Divider(height: 1, color: AppColors.lightBorder),
                        _buildDisplayTile(
                          icon: Icons.fingerprint_rounded,
                          iconColor: AppColors.primaryIndigo,
                          title: 'User ID (Read-Only)',
                          value: 'USR-NDRF-8821',
                          isMonospace: true,
                        ),
                        const Divider(height: 1, color: AppColors.lightBorder),
                        _buildDisplayTile(
                          icon: Icons.verified_user_outlined,
                          iconColor: AppColors.statusOnline,
                          title: 'Assigned Role',
                          value: 'Field Responder / Citizen Node',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. DEVICE SECTION
                  _buildSectionHeader('DEVICE INFORMATION'),
                  const SizedBox(height: 8),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildDisplayTile(
                          icon: Icons.perm_device_information_rounded,
                          iconColor: AppColors.primaryPurple,
                          title: 'Device Node ID',
                          value: 'NODE-AND-01',
                          isMonospace: true,
                        ),
                        const Divider(height: 1, color: AppColors.lightBorder),
                        _buildDisplayTile(
                          icon: Icons.battery_charging_full_rounded,
                          iconColor: AppColors.statusOnline,
                          title: 'Battery Level',
                          value: '94% (Healthy)',
                        ),
                        const Divider(height: 1, color: AppColors.lightBorder),
                        _buildDisplayTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: AppColors.textDarkMuted,
                          title: 'Application Version',
                          value: 'SoSquad v2.6.0 (2026 Build)',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. LOCATION STATUS SECTION
                  _buildSectionHeader('LOCATION SERVICES'),
                  const SizedBox(height: 8),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildDisplayTile(
                          icon: Icons.gps_fixed_rounded,
                          iconColor: hasGpsFix ? AppColors.statusOnline : AppColors.emergencyRed,
                          title: 'GPS Status',
                          value: hasGpsFix ? 'Active (High Accuracy Hardware Lock)' : 'Acquiring Satellites...',
                        ),
                        const Divider(height: 1, color: AppColors.lightBorder),
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primaryIndigo),
                          title: const Text('Location Permissions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary)),
                          subtitle: const Text('Manage system GPS accuracy settings', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textDarkMuted),
                          onTap: () => sosNotifier.openSettings(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. COMMUNICATION STATUS SECTION
                  _buildSectionHeader('COMMUNICATION CHANNELS'),
                  const SizedBox(height: 8),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildDisplayTile(
                          icon: Icons.cell_tower_rounded,
                          iconColor: isLoraAvailable ? AppColors.statusOnline : AppColors.statusTransmitting,
                          title: 'Offline Communication',
                          value: isLoraAvailable ? 'Available' : 'Standby / Hardware Pending',
                        ),
                        const Divider(height: 1, color: AppColors.lightBorder),
                        _buildDisplayTile(
                          icon: Icons.cloud_done_outlined,
                          iconColor: isOnline ? AppColors.statusOnline : AppColors.emergencyRed,
                          title: 'Internet / Cloud Sync',
                          value: isOnline ? 'Connected (Cloud Firestore Active)' : 'Disconnected',
                        ),
                        const Divider(height: 1, color: AppColors.lightBorder),
                        _buildDisplayTile(
                          icon: Icons.sync_rounded,
                          iconColor: AppColors.primaryIndigo,
                          title: 'Last Successful Sync',
                          value: 'Just now',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. SETTINGS SECTION
                  _buildSectionHeader('APP PREFERENCES'),
                  const SizedBox(height: 8),
                  _buildCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Distress Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary)),
                          subtitle: const Text('Receive status updates when HQ responds', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                          value: _notificationsEnabled,
                          activeColor: AppColors.primaryIndigo,
                          onChanged: (v) => setState(() => _notificationsEnabled = v),
                        ),
                        const Divider(height: 1, color: AppColors.lightBorder),
                        SwitchListTile(
                          title: const Text('Haptic Emergency Feedback', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary)),
                          subtitle: const Text('Vibrate during 3s hold and SOS confirmation', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                          value: _hapticsEnabled,
                          activeColor: AppColors.primaryIndigo,
                          onChanged: (v) => setState(() => _hapticsEnabled = v),
                        ),
                        const Divider(height: 1, color: AppColors.lightBorder),
                        ListTile(
                          leading: const Icon(Icons.language_rounded, size: 20, color: AppColors.primaryIndigo),
                          title: const Text('Language', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDarkPrimary)),
                          trailing: Text(
                            _selectedLanguage,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDarkSecondary),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedLanguage = _selectedLanguage.contains('English')
                                  ? 'Hindi (हिन्दी)'
                                  : 'English (EN)';
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 6. About Card
                  _buildCard(
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield_rounded, size: 18, color: AppColors.primaryIndigo),
                              SizedBox(width: 8),
                              Text(
                                'SoSquad RAKSHAK-NET',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDarkPrimary),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Mission-critical emergency response and live GPS telemetry platform. Engineered for resilient offline LoRa mesh communication and rapid disaster relief coordination.',
                            style: TextStyle(fontSize: 11, color: AppColors.textDarkMuted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.textDarkMuted,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Material(
      color: AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      child: child,
    );
  }

  Widget _buildDisplayTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDarkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: isMonospace ? 'monospace' : null,
                    color: AppColors.textDarkPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
