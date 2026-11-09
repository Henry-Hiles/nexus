import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/location.dart";
import "package:nexus/widgets/location/location_map.dart";
import "package:nexus/widgets/location/location_viewer_sheet.dart";

class const LocationMessage(final LocationMessageContent content, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final point = content.point;
    final description = content.description;

    if (point == null) {
      return Wrap(
        spacing: 8,
        children: [
          Text(
            "Invalid location:",
            style: TextStyle(color: theme.colorScheme.error),
          ),
          Text(content.body),
        ],
      );
    }

    return Column(
      crossAxisAlignment: .start,
      spacing: 8,
      children: [
        if (description != null)
          Text(description, style: theme.textTheme.titleSmall),
        ConstrainedBox(
          constraints: const .new(maxWidth: 400),
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: ClipRRect(
              borderRadius: .circular(12),
              child: Stack(
                children: [
                  LocationMap(point),
                  Positioned.fill(
                    child: Material(
                      type: .transparency,
                      child: InkWell(
                        onTap: () => context.showAdaptiveSheet(
                          enableDrag: false,
                          (_) => LocationViewerSheet(
                            point,
                            type: content.assetType,
                            description: description,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(point.formatted, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
