import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_map/flutter_map.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:latlong2/latlong.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/helpers/current_location_helper.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/location.dart";
import "package:nexus/widgets/location_map.dart";

/// Chooses a location to share, either the user's own or a pin dropped on the
/// map.
class const LocationPickerSheet({
  required final void Function(LocationMessageContent location) onPick,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapController = useMemoized(MapController.new);
    useEffect(() => mapController.dispose, [mapController]);

    // Not state, as it changes every frame while the map moves
    final center = useRef(const LatLng(0, 0));

    // Until the map is moved or the user is located, it's an arbitrary spot
    final placed = useState(false);
    // Whether the map is on the user's location, and its accuracy in meters
    final own = useState<({double? accuracy})?>(null);
    final locating = useState(false);
    final error = useState<String?>(null);
    final descriptionController = useTextEditingController();

    Future<void> locate({bool askPermission = true}) async {
      locating.value = true;
      error.value = null;
      try {
        final found = await ref
            .read(CurrentLocationHelper.provider)
            .get(askPermission: askPermission);
        // Doesn't move away from a spot the user chose while it was finding them
        if (found == null ||
            !context.mounted ||
            (!askPermission && placed.value)) {
          return;
        }

        final (point, accuracy) = found;
        center.value = point;
        mapController.move(point, 16);
        own.value = (accuracy: accuracy);
        placed.value = true;
      } catch (caught) {
        if (context.mounted && askPermission) error.value = caught.toString();
      } finally {
        if (context.mounted) locating.value = false;
      }
    }

    // Starts at the user's location if they've already allowed it, except on
    // Linux, where checking would ask
    useEffect(() {
      locate(askPermission: false);
      return null;
    }, []);

    void share() {
      final description = descriptionController.text.trim();
      final self = own.value != null;
      final geoUri = GeoUri.fromLatLng(
        center.value,
        uncertainty: own.value?.accuracy,
      );

      onPick(
        .new(
          body:
              "${description.isEmpty ? (self ? "My location" : "Location") : description}: $geoUri",
          geoUri: geoUri,
          location: .new(
            uri: geoUri,
            description: description.isEmpty ? null : description,
          ),
          asset: .new(type: self ? .self : .pin),
        ),
      );
    }

    return SheetLayout(
      title: const Text("Share Location"),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: placed.value ? share : null,
          child: const Text("Share"),
        ),
      ],
      children: [
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: .circular(12),
            child: Stack(
              children: [
                LocationMap(
                  center.value,
                  zoom: 2,
                  interactive: true,
                  showMarker: false,
                  controller: mapController,
                  onPositionChanged: (camera, hasGesture) {
                    center.value = camera.center;
                    if (hasGesture) {
                      own.value = null;
                      placed.value = true;
                    }
                  },
                ),
                IgnorePointer(
                  child: Center(
                    child: Transform.translate(
                      offset: const .new(0, -20),
                      child: LocationMap.markerOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: locating.value ? null : locate,
          icon: locating.value
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: const Text("Use current location"),
        ),
        if (error.value case final error?)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        TextField(
          controller: descriptionController,
          textCapitalization: .sentences,
          decoration: const .new(labelText: "Description (optional)"),
        ),
      ],
    );
  }
}
