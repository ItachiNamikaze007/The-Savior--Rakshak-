import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum EmergencyType {
  medical,
  flood,
  fire,
  earthquake,
  other;

  String get displayName {
    switch (this) {
      case EmergencyType.medical:
        return 'Medical';
      case EmergencyType.flood:
        return 'Flood';
      case EmergencyType.fire:
        return 'Fire';
      case EmergencyType.earthquake:
        return 'Earthquake';
      case EmergencyType.other:
        return 'Other';
    }
  }

  String get code {
    switch (this) {
      case EmergencyType.medical:
        return 'MED';
      case EmergencyType.flood:
        return 'FLD';
      case EmergencyType.fire:
        return 'FIR';
      case EmergencyType.earthquake:
        return 'EQK';
      case EmergencyType.other:
        return 'OTH';
    }
  }

  IconData get icon {
    switch (this) {
      case EmergencyType.medical:
        return Icons.medical_services_rounded;
      case EmergencyType.flood:
        return Icons.tsunami_rounded;
      case EmergencyType.fire:
        return Icons.local_fire_department_rounded;
      case EmergencyType.earthquake:
        return Icons.broken_image_rounded;
      case EmergencyType.other:
        return Icons.warning_amber_rounded;
    }
  }

  Color get color {
    switch (this) {
      case EmergencyType.medical:
        return AppColors.disasterMedical;
      case EmergencyType.flood:
        return AppColors.disasterFlood;
      case EmergencyType.fire:
        return AppColors.disasterFire;
      case EmergencyType.earthquake:
        return AppColors.disasterEarthquake;
      case EmergencyType.other:
        return AppColors.disasterOther;
    }
  }

  static EmergencyType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'medical':
      case 'med':
        return EmergencyType.medical;
      case 'flood':
      case 'fld':
        return EmergencyType.flood;
      case 'fire':
      case 'fir':
        return EmergencyType.fire;
      case 'earthquake':
      case 'eqk':
        return EmergencyType.earthquake;
      default:
        return EmergencyType.other;
    }
  }
}
