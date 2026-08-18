import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../sos/domain/entities/emergency_type.dart';
import '../../../sos/domain/entities/sos_request.dart';
import '../../../sos/domain/entities/sos_status.dart';

class HqMapView extends StatefulWidget {
  final List<SosRequest> incidents;
  final String? selectedSosId;
  final ValueChanged<String> onSelectIncident;

  const HqMapView({
    super.key,
    required this.incidents,
    required this.selectedSosId,
    required this.onSelectIncident,
  });

  @override
  State<HqMapView> createState() => _HqMapViewState();
}

class _HqMapViewState extends State<HqMapView>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;

  // Default coordinate center (New Delhi / Central India Coordination Base)
  static const LatLng _defaultCenter = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HqMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If selected incident changed, gently pan to its coordinate
    if (widget.selectedSosId != null &&
        widget.selectedSosId != oldWidget.selectedSosId) {
      final selected = widget.incidents
          .where((i) => i.sosId == widget.selectedSosId)
          .firstOrNull;
      if (selected != null && selected.latitude != 0 && selected.longitude != 0) {
        _mapController.move(
          LatLng(selected.latitude, selected.longitude),
          14.0,
        );
      }
    }
  }

  void _fitAllIncidents() {
    final validCoords = widget.incidents
        .where((i) => i.latitude != 0 && i.longitude != 0)
        .map((i) => LatLng(i.latitude, i.longitude))
        .toList();

    if (validCoords.isEmpty) {
      _mapController.move(_defaultCenter, 5.0);
      return;
    }

    if (validCoords.length == 1) {
      _mapController.move(validCoords.first, 13.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(validCoords);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
        maxZoom: 15.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initial center is selected incident, or first valid incident, or default center
    LatLng initialCenter = _defaultCenter;
    final validIncidents =
        widget.incidents.where((i) => i.latitude != 0 && i.longitude != 0).toList();

    if (widget.selectedSosId != null) {
      final sel = validIncidents
          .where((i) => i.sosId == widget.selectedSosId)
          .firstOrNull;
      if (sel != null) {
        initialCenter = LatLng(sel.latitude, sel.longitude);
      }
    } else if (validIncidents.isNotEmpty) {
      initialCenter =
          LatLng(validIncidents.first.latitude, validIncidents.first.longitude);
    }

    return Stack(
      children: [
        // 1. FlutterMap Tile & Marker Canvas
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: validIncidents.isNotEmpty ? 10.0 : 5.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            // Dark Tactical Basemap (CartoDB Dark Matter / OpenStreetMap Fallback)
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.sosquad.rakshaknet',
              maxZoom: 19,
            ),

            // Real-time Incident Markers Layer
            MarkerLayer(
              markers: validIncidents.map((incident) {
                final isSelected = incident.sosId == widget.selectedSosId;
                final isActive = incident.status == SosStatus.transmitting ||
                    incident.status == SosStatus.pending;

                return Marker(
                  point: LatLng(incident.latitude, incident.longitude),
                  width: isSelected ? 72 : 56,
                  height: isSelected ? 72 : 56,
                  child: GestureDetector(
                    onTap: () => widget.onSelectIncident(incident.sosId),
                    child: _buildMarkerWidget(incident, isSelected, isActive),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // 2. Tactical Overlay Map Control Panel (Top-Right)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  tooltip: 'Zoom In',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.border),
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 20, color: Colors.white),
                  tooltip: 'Zoom Out',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.border),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong_rounded,
                      size: 20, color: AppColors.statusStandby),
                  tooltip: 'Fit All Incidents',
                  onPressed: _fitAllIncidents,
                ),
              ],
            ),
          ),
        ),

        // 3. Tactical Reticle / HUD Info (Top-Left)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gps_fixed_rounded, size: 14, color: AppColors.statusStandby),
                const SizedBox(width: 8),
                Text(
                  'TACTICAL SECTOR MAP • ${validIncidents.length} NODES VISIBLE',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Tactical Map Legend (Bottom-Left)
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem('Medical', EmergencyType.medical.color),
                const SizedBox(width: 12),
                _buildLegendItem('Flood', EmergencyType.flood.color),
                const SizedBox(width: 12),
                _buildLegendItem('Fire', EmergencyType.fire.color),
                const SizedBox(width: 12),
                _buildLegendItem('Quake', EmergencyType.earthquake.color),
                const SizedBox(width: 12),
                _buildLegendItem('Active SOS', AppColors.emergencyRed, isPulsing: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkerWidget(
      SosRequest incident, bool isSelected, bool isActive) {
    final color = incident.emergencyType.color;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing radar animation for active distress signals
        if (isActive)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 32 + (20 * _pulseController.value),
                height: 32 + (20 * _pulseController.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergencyRed
                      .withOpacity(0.4 * (1.0 - _pulseController.value)),
                  border: Border.all(
                    color: AppColors.emergencyRed
                        .withOpacity(1.0 - _pulseController.value),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),

        // Outer glow on selected
        if (isSelected)
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.3),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),

        // Pin Node
        Container(
          width: isSelected ? 34 : 28,
          height: isSelected ? 34 : 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              incident.emergencyType.icon,
              size: isSelected ? 18 : 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isPulsing = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
