import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Background & Surfaces
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF161F30);
  static const Color surfaceElevated = Color(0xFF1E293B);
  static const Color surfaceGlass = Color(0xCC161F30);
  static const Color border = Color(0xFF334155);
  static const Color borderGlow = Color(0xFF475569);

  // Tactical Emergency Alerts
  static const Color emergencyRed = Color(0xFFEF4444);
  static const Color emergencyRedDark = Color(0xFF991B1B);
  static const Color emergencyRedGlow = Color(0xFFFF5757);

  // Status & Telemetry
  static const Color statusOnline = Color(0xFF10B981);
  static const Color statusTransmitting = Color(0xFFF59E0B);
  static const Color statusAcknowledged = Color(0xFF10B981);
  static const Color statusError = Color(0xFFEF4444);
  static const Color statusStandby = Color(0xFF06B6D4);

  // Disaster Types Color Tokens
  static const Color disasterMedical = Color(0xFFF43F5E);
  static const Color disasterFlood = Color(0xFF06B6D4);
  static const Color disasterFire = Color(0xFFF97316);
  static const Color disasterEarthquake = Color(0xFFEAB308);
  static const Color disasterOther = Color(0xFFA855F7);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textAlert = Color(0xFFFECACA);
}
