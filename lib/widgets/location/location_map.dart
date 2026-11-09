import "package:flutter_map/flutter_map.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:latlong2/latlong.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/launch_helper.dart";

class const LocationMap(
  final LatLng center, {
  final bool showMarker = true,
  final bool interactive = false,
  final double zoom = 15,
  final MapController? controller,
  final PositionCallback? onPositionChanged,
  super.key,
}) extends ConsumerWidget {
  /// The marker's icon, which points at the location from its bottom.
  static Widget markerOf(BuildContext context) => Icon(
    Icons.location_pin,
    size: 40,
    color: Theme.of(context).colorScheme.primary,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) => FlutterMap(
    mapController: controller,
    options: MapOptions(
      initialCenter: center,
      initialZoom: zoom,
      minZoom: 2,
      maxZoom: 19,
      onPositionChanged: onPositionChanged,
      interactionOptions: InteractionOptions(
        flags: interactive
            ? InteractiveFlag.all & ~InteractiveFlag.rotate
            : InteractiveFlag.none,
      ),
    ),
    children: [
      TileLayer(
        urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        // Required by OpenStreetMap's tile usage policy
        userAgentPackageName: "nexus.federated.nexus",
      ),
      if (showMarker)
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 40,
              height: 40,
              alignment: .topCenter,
              child: markerOf(context),
            ),
          ],
        ),
      // Required by OpenStreetMap
      Align(
        alignment: .bottomRight,
        child: Material(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          child: InkWell(
            onTap: interactive
                ? () => ref
                      .read(LaunchHelper.provider)
                      .launchUrl(
                        Uri.https("www.openstreetmap.org", "/copyright"),
                      )
                : null,
            child: Padding(
              padding: const .symmetric(horizontal: 4, vertical: 2),
              child: Text(
                "© OpenStreetMap",
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: .ellipsis,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
