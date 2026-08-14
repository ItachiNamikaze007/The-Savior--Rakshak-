class AppStrings {
  AppStrings._();

  static const String appName = 'SoSquad';
  static const String productName = 'RAKSHAK-NET';
  static const String tagline = 'Hybrid Disaster Response & Rescue Coordination';

  // Screen Titles & Headers
  static const String emergencyConsole = 'TACTICAL EMERGENCY CONSOLE';
  static const String activeDistressBeacon = 'ACTIVE DISTRESS BEACON';
  static const String confirmationTitle = 'CONFIRM DISTRESS SIGNAL';

  // GPS Telemetry
  static const String liveGps = 'LIVE GPS TELEMETRY';
  static const String acquiringGps = 'Acquiring GPS fix...';
  static const String gpsLocked = 'GPS FIX ACQUIRED';
  static const String gpsError = 'LOCATION UNAVAILABLE';
  static const String enableGpsPrompt = 'Please enable location services or grant GPS permission.';
  static const String retryGps = 'RETRY GPS';
  static const String simulatedGpsActive = 'SIMULATED GPS (DEV MODE)';

  // Emergency Types
  static const String emergencyTypeHeader = 'SELECT EMERGENCY CATEGORY';
  static const String typeMedical = 'Medical';
  static const String typeFlood = 'Flood';
  static const String typeFire = 'Fire';
  static const String typeEarthquake = 'Earthquake';
  static const String typeOther = 'Other';

  // Casualty Counters
  static const String affectedPeople = 'People Affected / Stranded';
  static const String injuredPeople = 'Injured Requiring Medical Aid';

  // SOS Action
  static const String triggerSos = 'TRANSMIT SOS';
  static const String tapToTrigger = 'TAP TO TRANSMIT DISTRESS BEACON';
  static const String confirmDispatch = 'DISPATCH DISTRESS BEACON';
  static const String cancelSos = 'CANCEL DISTRESS BEACON';
  static const String backToConsole = 'RETURN TO CONSOLE';

  // Status Strings
  static const String statusPending = 'PENDING';
  static const String statusTransmitting = 'TRANSMITTING';
  static const String statusAcknowledged = 'ACKNOWLEDGED BY HQ';
  static const String statusCancelled = 'CANCELLED';
}
