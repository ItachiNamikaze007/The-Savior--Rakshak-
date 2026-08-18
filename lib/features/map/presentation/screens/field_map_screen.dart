import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../../../sos/presentation/providers/sos_state_notifier.dart';

class PoliceStationInfo {
  final String name;
  final String address;
  final LatLng position;
  final String phone;

  const PoliceStationInfo({
    required this.name,
    required this.address,
    required this.position,
    required this.phone,
  });
}

class FieldMapScreen extends StatefulWidget {
  const FieldMapScreen({super.key});

  @override
  State<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends State<FieldMapScreen> {
  late final MapController _mapController;
  StreamSubscription<LocationData>? _positionStreamSub;

  // Real-time GPS movement tracking
  LocationData? _liveLocation;
  final List<LatLng> _movementTrail = [];
  bool _followUser = true;

  // Selected Marker Info
  PoliceStationInfo? _selectedStation;
  bool _selectedHq = false;

  // National Disaster Response Coordination HQ
  static const LatLng _hqLocation = LatLng(28.6139, 77.2090);
  static const String _hqName = 'NDRF Emergency Coordination Base';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final locationService = context.read<LocationService>();
    final sosNotifier = context.read<SosStateNotifier>();

    // Initial location from notifier
    if (sosNotifier.currentLocation != null) {
      _liveLocation = sosNotifier.currentLocation;
      _movementTrail.add(LatLng(_liveLocation!.latitude, _liveLocation!.longitude));
    }

    // Subscribe to continuous live position stream for Google Maps-like dynamic navigation
    _positionStreamSub = locationService.getPositionStream().listen((pos) {
      if (mounted) {
        setState(() {
          _liveLocation = pos;
          final point = LatLng(pos.latitude, pos.longitude);
          if (_movementTrail.isEmpty ||
              const Distance().as(LengthUnit.Meter, _movementTrail.last, point) > 3) {
            _movementTrail.add(point);
            if (_movementTrail.length > 50) _movementTrail.removeAt(0);
          }
        });

        if (_followUser) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom);
        }
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _recenterOnUser() {
    if (_liveLocation != null) {
      setState(() => _followUser = true);
      _mapController.move(
        LatLng(_liveLocation!.latitude, _liveLocation!.longitude),
        16.0,
      );
    }
  }

  List<PoliceStationInfo> _getNearbyPoliceStations(LatLng userPos) {
    // Generate realistic police stations around the active user coordinate
    const dist = Distance();
    return [
      PoliceStationInfo(
        name: 'District Central Police Station',
        address: 'Sector Emergency Unit • 24/7 Control',
        position: LatLng(userPos.latitude + 0.006, userPos.longitude + 0.005),
        phone: '112 / 100',
      ),
      PoliceStationInfo(
        name: 'City Rapid Response & Traffic Division',
        address: 'Civil Lines Road • First Responders',
        position: LatLng(userPos.latitude - 0.007, userPos.longitude + 0.004),
        phone: '112 / 108',
      ),
      PoliceStationInfo(
        name: 'Sub-Divisional Police Outpost',
        address: 'Highway Patrol Post #4',
        position: LatLng(userPos.latitude + 0.003, userPos.longitude - 0.008),
        phone: '112',
      ),
    ]..sort((a, b) => dist.as(LengthUnit.Meter, userPos, a.position).compareTo(
          dist.as(LengthUnit.Meter, userPos, b.position),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final sosNotifier = context.watch<SosStateNotifier>();
    final loc = _liveLocation ?? sosNotifier.currentLocation;
    final userPos = loc != null ? LatLng(loc.latitude, loc.longitude) : _hqLocation;

    final distanceToHq = loc != null
        ? (const Distance().as(LengthUnit.Kilometer, userPos, _hqLocation))
        : 0.0;

    final nearbyStations = loc != null ? _getNearbyPoliceStations(userPos) : <PoliceStationInfo>[];

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.navigation_rounded, color: AppColors.primaryIndigo, size: 22),
            SizedBox(width: 8),
            Text(
              'Live Tactical Map',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textDarkPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Follow Mode Toggle
          IconButton(
            icon: Icon(
              _followUser ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
              color: _followUser ? AppColors.primaryIndigo : AppColors.textDarkMuted,
            ),
            tooltip: _followUser ? 'Camera Following User' : 'Free Camera',
            onPressed: () {
              setState(() => _followUser = !_followUser);
              if (_followUser) _recenterOnUser();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. FlutterMap Tile Canvas
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPos,
              initialZoom: loc != null ? 15.0 : 6.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _followUser) {
                  setState(() => _followUser = false);
                }
              },
            ),
            children: [
              // Clean CartoDB Voyager Basemap Tiles
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.sosquad.rakshaknet',
                maxZoom: 19,
              ),

              // Movement Trail (Breadcrumb line)
              if (_movementTrail.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _movementTrail,
                      color: AppColors.primaryIndigo.withOpacity(0.4),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),

              // GPS Accuracy Circle
              if (loc != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: userPos,
                      color: AppColors.primaryIndigo.withOpacity(0.12),
                      borderColor: AppColors.primaryIndigo.withOpacity(0.5),
                      borderStrokeWidth: 1.5,
                      useRadiusInMeter: true,
                      radius: loc.accuracy.clamp(8.0, 250.0),
                    ),
                  ],
                ),

              // Markers Layer: Current User 📍, HQ 🏢, Nearby Police Stations 🚔
              MarkerLayer(
                markers: [
                  // 🏢 HQ Marker
                  Marker(
                    point: _hqLocation,
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedHq = true;
                          _selectedStation = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryPurple,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: AppColors.primaryPurple.withOpacity(0.4), blurRadius: 8),
                          ],
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),

                  // 🚔 Nearby Police Stations Markers
                  ...nearbyStations.map((station) {
                    return Marker(
                      point: station.position,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStation = station;
                            _selectedHq = false;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.statusStandby,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: AppColors.statusStandby.withOpacity(0.4), blurRadius: 8),
                            ],
                          ),
                          child: const Icon(Icons.local_police_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    );
                  }),

                  // 📍 Real-Time User Marker (Google Maps-like live navigation icon)
                  if (loc != null)
                    Marker(
                      point: userPos,
                      width: 54,
                      height: 54,
                      child: Transform.rotate(
                        angle: loc.heading * (3.1415926535 / 180),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryIndigo.withOpacity(0.2),
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryIndigo,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryIndigo.withOpacity(0.6),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.navigation_rounded, size: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Map Floating Controls (Recenter Button)
          Positioned(
            bottom: (_selectedStation != null || _selectedHq) ? 140 : 20,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: AppColors.lightSurface,
              foregroundColor: AppColors.primaryIndigo,
              tooltip: 'Recenter My GPS Location',
              onPressed: _recenterOnUser,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // 3. Floating Detail Card (HQ or Police Station)
          if (_selectedHq)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_rounded, color: AppColors.primaryPurple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            _hqName,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDarkPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Distance: ${distanceToHq.toStringAsFixed(1)} km away from you',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDarkSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _selectedHq = false),
                    ),
                  ],
                ),
              ),
            )
          else if (_selectedStation != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.statusStandbyLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_police_rounded, color: AppColors.statusStandby, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedStation!.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDarkPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedStation!.address} • Helpline: ${_selectedStation!.phone}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDarkSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _selectedStation = null),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
