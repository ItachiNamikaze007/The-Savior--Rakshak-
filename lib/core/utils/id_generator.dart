import 'dart:math';
import 'package:intl/intl.dart';

class IdGenerator {
  IdGenerator._();

  static final Random _random = Random();

  /// Generates an emergency distress identifier in standard format: RAK-YYYYMMDD-XXXX
  static String generateSosId({DateTime? timestamp}) {
    final now = timestamp ?? DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final randomHex = _random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase();
    return 'RAK-$dateStr-$randomHex';
  }
}
