import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum SosStatus {
  pending,
  transmitting,
  acknowledged,
  dispatched,
  cancelled;

  String get displayName {
    switch (this) {
      case SosStatus.pending:
        return 'PENDING';
      case SosStatus.transmitting:
        return 'TRANSMITTING BEACON';
      case SosStatus.acknowledged:
        return 'ACKNOWLEDGED BY HQ';
      case SosStatus.dispatched:
        return 'RESCUE TEAM DISPATCHED';
      case SosStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color get color {
    switch (this) {
      case SosStatus.pending:
        return AppColors.textMuted;
      case SosStatus.transmitting:
        return AppColors.statusTransmitting;
      case SosStatus.acknowledged:
        return AppColors.statusAcknowledged;
      case SosStatus.dispatched:
        return AppColors.statusOnline;
      case SosStatus.cancelled:
        return AppColors.statusError;
    }
  }

  static SosStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'transmitting':
        return SosStatus.transmitting;
      case 'acknowledged':
        return SosStatus.acknowledged;
      case 'dispatched':
        return SosStatus.dispatched;
      case 'cancelled':
        return SosStatus.cancelled;
      default:
        return SosStatus.pending;
    }
  }
}
