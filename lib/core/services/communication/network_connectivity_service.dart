import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum NetworkStatus {
  online('Online (Internet Reachable)'),
  offline('Offline (Zero Internet)'),
  degraded('Degraded Connection');

  final String label;
  const NetworkStatus(this.label);
}

/// Service that monitors actual socket reachability to reliably detect network failures,
/// ISP dropouts, and trigger immediate mesh network failover.
class NetworkConnectivityService {
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  Stream<NetworkStatus> get onStatusChange => _statusController.stream;

  NetworkStatus _currentStatus = NetworkStatus.online;
  NetworkStatus get currentStatus => _currentStatus;
  bool get isOnline => _currentStatus == NetworkStatus.online;

  Timer? _heartbeatTimer;
  bool _isDisposed = false;

  NetworkConnectivityService({bool autoStart = true}) {
    if (autoStart) {
      startMonitoring();
    }
  }

  void startMonitoring() {
    _heartbeatTimer?.cancel();
    _checkReachability();

    // Check reachability periodically every 8 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _checkReachability();
    });
  }

  /// Manually force a connection state (useful for test simulations and UI toggles)
  void setSimulatedStatus(NetworkStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      if (!_isDisposed) {
        _statusController.add(_currentStatus);
      }
    }
  }

  Future<void> _checkReachability() async {
    if (kIsWeb) {
      // In web environment, default to online
      _updateStatus(NetworkStatus.online);
      return;
    }

    try {
      // Perform a low-overhead socket connection check to Public DNS (Google/Cloudflare)
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      socket.destroy();
      _updateStatus(NetworkStatus.online);
    } catch (_) {
      // Fallback secondary check
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          _updateStatus(NetworkStatus.online);
        } else {
          _updateStatus(NetworkStatus.offline);
        }
      } catch (_) {
        _updateStatus(NetworkStatus.offline);
      }
    }
  }

  void _updateStatus(NetworkStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      if (!_isDisposed) {
        _statusController.add(_currentStatus);
      }
    }
  }

  void dispose() {
    _isDisposed = true;
    _heartbeatTimer?.cancel();
    _statusController.close();
  }
}
