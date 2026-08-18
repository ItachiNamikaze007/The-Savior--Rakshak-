import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // 2026 Light Theme Surfaces (Primary Mobile UI)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);

  // Dark Theme & Tactical Surfaces (HQ Command Center)
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF161F30);
  static const Color surfaceElevated = Color(0xFF1E293B);
  static const Color surfaceGlass = Color(0xCC161F30);
  static const Color border = Color(0xFF334155);
  static const Color borderGlow = Color(0xFF475569);

  // Modern Primary Accents
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color primaryIndigoLight = Color(0xFFEEF2FF);
  static const Color primaryPurple = Color(0xFF7C3AED);

  // Tactical Emergency Alerts
  static const Color emergencyRed = Color(0xFFDC2626);
  static const Color emergencyRedDark = Color(0xFF991B1B);
  static const Color emergencyRedLight = Color(0xFFFEF2F2);
  static const Color emergencyRedGlow = Color(0xFFFF5757);

  // Status & Telemetry
  static const Color statusOnline = Color(0xFF16A34A);
  static const Color statusOnlineLight = Color(0xFFF0FDF4);
  static const Color statusTransmitting = Color(0xFFD97706);
  static const Color statusTransmittingLight = Color(0xFFFFFBEB);
  static const Color statusAcknowledged = Color(0xFF0D9488);
  static const Color statusError = Color(0xFFDC2626);
  static const Color statusStandby = Color(0xFF0284C7);
  static const Color statusStandbyLight = Color(0xFFF0F9FF);

  // Disaster Types Color Tokens
  static const Color disasterMedical = Color(0xFFE11D48);
  static const Color disasterFlood = Color(0xFF0284C7);
  static const Color disasterFire = Color(0xFFEA580C);
  static const Color disasterEarthquake = Color(0xFFCA8A04);
  static const Color disasterAccident = Color(0xFFD97706);
  static const Color disasterOther = Color(0xFF7C3AED);

  // Typography Colors (Light Mode)
  static const Color textDarkPrimary = Color(0xFF0F172A);
  static const Color textDarkSecondary = Color(0xFF475569);
  static const Color textDarkMuted = Color(0xFF94A3B8);

  // Typography Colors (Dark Mode)
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textAlert = Color(0xFFFECACA);
}
