class TelemetryStatus {
  final String status;
  final int signalStrengthPercent;
  final int batteryPercent;
  final bool isOnline;

  const TelemetryStatus({
    this.status = 'READY',
    this.signalStrengthPercent = 95,
    this.batteryPercent = 88,
    this.isOnline = true,
  });
}

class TelemetryService {
  TelemetryStatus getTelemetry() {
    return const TelemetryStatus(
      status: 'SYSTEM ACTIVE',
      signalStrengthPercent: 98,
      batteryPercent: 85,
      isOnline: true,
    );
  }
}
