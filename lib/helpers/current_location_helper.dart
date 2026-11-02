import "dart:async";
import "dart:io";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:geolocator/geolocator.dart";
import "package:latlong2/latlong.dart";
import "package:nexus/controllers/portal.dart";
import "package:nexus/models/location_exception.dart";

class CurrentLocationHelper(final Ref ref) {
  static const _timeLimit = Duration(seconds: 10);

  /// The user's location and its accuracy in meters, or null if [askPermission]
  /// is off and they haven't allowed it.
  Future<(LatLng, double?)?> get({required bool askPermission}) async {
    // geolocator talks to GeoClue directly, which Flatpak's sandbox blocks, so
    // Linux uses the location portal, which also asks the user for permission
    if (Platform.isLinux) {
      // The portal can't say whether it's allowed without asking
      if (!askPermission) return null;

      try {
        final portal = await ref.read(PortalController.provider.future);
        final location = await portal.location
            .createSession(accuracy: .exact)
            .first
            .timeout(_timeLimit);

        return switch ((location.latitude, location.longitude)) {
          (final latitude?, final longitude?) => (
            LatLng(latitude, longitude),
            location.accuracy,
          ),
          _ => throw LocationException.failed,
        };
      } on TimeoutException {
        throw LocationException.timedOut;
      } catch (_) {
        throw LocationException.failed;
      }
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!askPermission) return null;
      throw LocationException.servicesOff;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == .denied && askPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == .denied || permission == .deniedForever) {
      if (!askPermission) return null;
      throw LocationException.denied;
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: Platform.isAndroid
            // Play services' location can hang without Google, like on microG,
            // so this uses Android's own, as other apps do
            ? AndroidSettings(forceLocationManager: true, timeLimit: _timeLimit)
            : const LocationSettings(timeLimit: _timeLimit),
      );
    } on TimeoutException {
      // A fix can take long indoors, but another app may have a recent one
      position = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: true,
      );
    } catch (_) {
      throw LocationException.failed;
    }
    if (position == null) throw LocationException.timedOut;

    return (LatLng(position.latitude, position.longitude), position.accuracy);
  }

  static final provider = Provider<CurrentLocationHelper>(
    CurrentLocationHelper.new,
  );
}
