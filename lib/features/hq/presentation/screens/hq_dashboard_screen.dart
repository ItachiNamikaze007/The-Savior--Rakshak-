import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../sos/domain/entities/emergency_type.dart';
import '../../../sos/domain/repositories/i_sos_repository.dart';
import '../providers/hq_dashboard_notifier.dart';
import '../widgets/hq_bottom_panel.dart';
import '../widgets/hq_header.dart';
import '../widgets/hq_incident_card.dart';
import '../widgets/hq_incident_detail_panel.dart';
import '../widgets/hq_map_view.dart';
import '../widgets/hq_metrics_bar.dart';
import '../widgets/hq_sidebar.dart';

class HqDashboardScreen extends StatelessWidget {
  const HqDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HqDashboardNotifier>(
      create: (ctx) => HqDashboardNotifier(
        sosRepository: ctx.read<ISosRepository>(),
      ),
      child: const _HqDashboardContent(),
    );
  }
}

class _HqDashboardContent extends StatefulWidget {
  const _HqDashboardContent();

  @override
  State<_HqDashboardContent> createState() => _HqDashboardContentState();
}

class _HqDashboardContentState extends State<_HqDashboardContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBroadcastSos(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlgCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: const Row(
            children: [
              Icon(Icons.emergency_share_rounded, color: AppColors.emergencyRed, size: 20),
              SizedBox(width: 8),
              Text('EMERGENCY SOS BROADCAST', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            ],
          ),
          content: const Text(
            'Broadcast emergency alert to all connected LoRa mesh nodes and field rescue squads?',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
              onPressed: () {
                Navigator.pop(dlgCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.emergencyRed,
                    content: Text('BROADCAST TRANSMITTED: High-priority distress sync sent across all mesh frequencies.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('TRANSMIT BROADCAST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<HqDashboardNotifier>();
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final selectedIncident = notifier.selectedIncident;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 2026 Left Navigation Sidebar
            HqSidebar(
              notifier: notifier,
              onBroadcastSos: () => _handleBroadcastSos(context),
            ),

            // 2. Main Command Center Operations Area
            Expanded(
              child: Column(
                children: [
                  // Top Header
                  HqHeader(notifier: notifier),

                  // KPI Row
                  HqMetricsBar(notifier: notifier),

                  // Filter Toolstrip
                  _buildFilterToolstrip(context, notifier),

                  // 3-Pane Center Workspace (Left: Alerts Queue, Center: Tactical Map, Right: Active Incident)
                  Expanded(
                    child: isDesktop
                        ? _buildDesktopLayout(context, notifier, selectedIncident)
                        : _buildTabletLayout(context, notifier, selectedIncident),
                  ),

                  // Bottom Telemetry & Activity Panel
                  HqBottomPanel(notifier: notifier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToolstrip(
      BuildContext context, HqDashboardNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by SOS ID, Node or Category...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            notifier.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.statusStandby),
                  ),
                ),
                onChanged: (val) => notifier.setSearchQuery(val),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Status Filter Dropdown / Chips
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: HqStatusFilter.values.map((filter) {
                  final isSelected = notifier.statusFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        filter.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.statusStandby,
                      backgroundColor: AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.statusStandby : AppColors.border,
                      ),
                      onSelected: (selected) {
                        if (selected) notifier.setStatusFilter(filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Emergency Category Filter Dropdown
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EmergencyType?>(
                value: notifier.emergencyTypeFilter,
                dropdownColor: AppColors.surfaceElevated,
                hint: const Text('ALL CATEGORIES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textMuted),
                items: [
                  const DropdownMenuItem<EmergencyType?>(
                    value: null,
                    child: Text('ALL CATEGORIES',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  ...EmergencyType.values.map((type) {
                    return DropdownMenuItem<EmergencyType?>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, size: 14, color: type.color),
                          const SizedBox(width: 6),
                          Text(type.displayName.toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: type.color)),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (val) => notifier.setEmergencyTypeFilter(val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3-Pane Desktop Layout
  Widget _buildDesktopLayout(BuildContext context, HqDashboardNotifier notifier,
      dynamic selectedIncident) {
    final filtered = notifier.filteredIncidents;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Pane: Real-time Incidents Feed
        SizedBox(
          width: 390,
          child: _buildIncidentsFeed(context, notifier, filtered),
        ),

        // Center Pane: Tactical Live Map
        Expanded(
          child: HqMapView(
            incidents: filtered,
            selectedSosId: notifier.selectedSosId,
            onSelectIncident: (id) => notifier.selectIncident(id),
          ),
        ),

        // Right Pane: Incident Dossier / Detail Panel
        if (selectedIncident != null)
          HqIncidentDetailPanel(
            incident: selectedIncident,
            onClose: () => notifier.selectIncident(null),
            onUpdateStatus: (newStatus) {
              notifier.updateIncidentStatus(selectedIncident.sosId, newStatus);
            },
          ),
      ],
    );
  }

  // 2-Pane / Tabbed Tablet Layout
  Widget _buildTabletLayout(BuildContext context, HqDashboardNotifier notifier,
      dynamic selectedIncident) {
    final filtered = notifier.filteredIncidents;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: const TabBar(
              indicatorColor: AppColors.statusStandby,
              labelColor: AppColors.statusStandby,
              unselectedLabelColor: AppColors.textMuted,
              tabs: [
                Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'TACTICAL MAP'),
                Tab(icon: Icon(Icons.emergency_share_rounded, size: 18), text: 'INCIDENTS FEED'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Map View
                HqMapView(
                  incidents: filtered,
                  selectedSosId: notifier.selectedSosId,
                  onSelectIncident: (id) => notifier.selectIncident(id),
                ),

                // Tab 2: Incidents List
                _buildIncidentsFeed(context, notifier, filtered),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsFeed(BuildContext context,
      HqDashboardNotifier notifier, List<dynamic> filtered) {
    if (notifier.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.statusStandby),
            SizedBox(height: 12),
            Text(
              'Connecting to Firestore SOS Stream...',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (notifier.errorMessage != null && filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.statusError),
              const SizedBox(height: 12),
              Text(
                notifier.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.statusError),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('RETRY CONNECTION'),
                onPressed: () => notifier.retryConnection(),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 40,
                color: AppColors.statusOnline,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'NO ACTIVE INCIDENTS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'All monitored sectors are currently operational and clear.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Feed Header Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'LIVE DISTRESS QUEUE (${filtered.length})',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sensors_rounded, size: 12, color: AppColors.emergencyRed),
                  SizedBox(width: 4),
                  Text(
                    'STREAM ACTIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emergencyRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List View of Incidents
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemBuilder: (ctx, index) {
              final incident = filtered[index];
              return HqIncidentCard(
                incident: incident,
                isSelected: incident.sosId == notifier.selectedSosId,
                onTap: () => notifier.selectIncident(incident.sosId),
                onUpdateStatus: (newStatus) {
                  notifier.updateIncidentStatus(incident.sosId, newStatus);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
