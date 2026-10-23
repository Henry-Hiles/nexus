import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:timezone/data/latest_10y.dart";
import "package:timezone/timezone.dart";

/// The names of all IANA timezones, e.g. `Europe/London`, alphabetically.
class TimezonesController extends Notifier<IList<String>> {
  @override
  IList<String> build() {
    initializeTimeZones();
    return timeZoneDatabase.locations.keys.toIList().sort();
  }

  static final provider = NotifierProvider<TimezonesController, IList<String>>(
    TimezonesController.new,
  );
}
