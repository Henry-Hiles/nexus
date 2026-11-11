import "dart:async";
import "dart:io";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:location/location.dart";
import "package:latlong2/latlong.dart";
import "package:nexus/controllers/portal.dart";
import "package:nexus/models/location_exception.dart";

class CurrentLocationHelper(final Ref ref) {
  static const _timeLimit = Duration(seconds: 10);

  /// The user's location and its accuracy in meters, or null if [askPermission]
  /// is off and they haven't allowed it.
  Future<(LatLng, double?)?> get({required bool askPermission}) async {
    // location talks to GeoClue directly, which Flatpak's sandbox blocks, so
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

    final location = Location.instance;
    if (!await location.serviceEnabled()) {
      if (!askPermission) return null;
      throw LocationException.servicesOff;
    }

    var permission = await location.hasPermission();
    if (permission == .denied && askPermission) {
      permission = await location.requestPermission();
    }
    if (permission == .denied || permission == .deniedForever) {
      if (!askPermission) return null;
      throw LocationException.denied;
    }

    LocationData? data;
    try {
      data = await location.getLocation().timeout(_timeLimit);
    } on TimeoutException {
      // A fix can take long indoors, but another app may have a recent one
      data = await location.getLastKnownLocation().onError(
        (_, _) => throw LocationException.failed,
      );
    } catch (_) {
      throw LocationException.failed;
    }

    if (data == null) throw LocationException.timedOut;

    return (LatLng(data.latitude, data.longitude), data.accuracy);
  }

  static final provider = Provider<CurrentLocationHelper>(
    CurrentLocationHelper.new,
  );
}
