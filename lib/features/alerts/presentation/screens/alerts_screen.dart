import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../sos/domain/entities/sos_request.dart';
import '../../../sos/domain/repositories/i_sos_repository.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ISosRepository>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: AppColors.primaryIndigo, size: 20),
            SizedBox(width: 8),
            Text(
              'Emergency Alerts & Logs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textDarkPrimary,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<SosRequest>>(
        stream: repo.watchAllSosRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryIndigo));
          }

          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: AppColors.statusOnline),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Active Emergency Alerts',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDarkPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'System telemetry is operational. No active distress signals.',
                    style: TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (ctx, index) {
              final item = alerts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.emergencyType.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.emergencyType.icon, color: item.emergencyType.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.sosId,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  color: AppColors.textDarkPrimary,
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm:ss').format(item.timestamp),
                                style: const TextStyle(fontSize: 10, color: AppColors.textDarkMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.emergencyType.displayName.toUpperCase()} Emergency Broadcast',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDarkPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status: ${item.status.name.toUpperCase()} • ${item.peopleCount} Affected • Lat: ${item.latitude.toStringAsFixed(4)}, Lon: ${item.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
