import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:latlong2/latlong.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:nexus/models/location.dart";
import "package:nexus/widgets/location_map.dart";

class const LocationViewerSheet(
  final LatLng point, {
  final LocationAssetType type = .self,
  final String? description,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => SheetLayout(
    title: Text(
      description ?? (type == .self ? "Shared Location" : "Location"),
    ),
    actions: [
      TextButton(
        onPressed: () => ref
            .read(LaunchHelper.provider)
            .launchUrl(GeoUri.openStreetMap(point)),
        child: const Text("Open in OpenStreetMap"),
      ),
      TextButton(
        onPressed: Navigator.of(context).pop,
        child: const Text("Close"),
      ),
    ],
    children: [
      SizedBox(
        height: 400,
        child: ClipRRect(
          borderRadius: .circular(12),
          child: LocationMap(point, interactive: true),
        ),
      ),
      SelectableText(point.formatted),
    ],
  );
}
