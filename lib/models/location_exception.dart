enum LocationException(final String message) implements Exception {
  servicesOff("Location services are turned off."),
  denied("Nexus doesn't have permission to see your location."),
  timedOut("Couldn't get your location in time."),
  failed(
    "Couldn't get your location. Check that location services are on, and that Nexus is allowed to use them.",
  );

  @override
  String toString() => message;
}
