enum LocationErrorCode {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationException implements Exception {
  final String message;
  final LocationErrorCode code;

  const LocationException(this.message, {this.code = LocationErrorCode.unknown});

  @override
  String toString() => 'LocationException: [$code] $message';
}

class SosException implements Exception {
  final String message;

  const SosException(this.message);

  @override
  String toString() => 'SosException: $message';
}
