import "dart:async";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/timezones.dart";
import "package:nexus/helpers/extensions/is_desktop.dart";
import "package:nexus/helpers/hooks/saving.dart";
import "package:nexus/widgets/settings/inline_text_field.dart";
import "package:timezone/timezone.dart";

class const TimezoneField({
  required final String? value,

  required final FutureOr<void> Function(String? value)? onChanged,
  final TextStyle? style,
  super.key,
}) extends HookConsumerWidget {
  static String offsetOf(String timezone) {
    final offset = TZDateTime.now(getLocation(timezone)).timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, "0");
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, "0");
    return "UTC${offset.isNegative ? "-" : "+"}$hours:$minutes";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final saving = Saving.use();
    final timezones = ref.watch(TimezonesController.provider);
    final enabled = onChanged != null && !saving.active;
    final iconSize = InlineTextField.iconSizeOf(style);

    void choose(SearchController controller, String? timezone) {
      controller.closeView("");
      if (timezone != value) saving.run(() => onChanged!(timezone));
    }

    return SearchAnchor(
      viewHintText: "Search timezones...",
      viewConstraints: context.isDesktop
          ? const .new(minWidth: 320, maxWidth: 400, maxHeight: 400)
          : null,
      builder: (context, controller) => InkWell(
        hoverColor: colorScheme.surfaceContainerHighest,
        onTap: enabled ? controller.openView : null,
        child: Padding(
          padding: const .fromLTRB(6, 8, 0, 8),
          child: Row(
            mainAxisSize: .min,
            children: [
              Text(
                value?.replaceAll("_", " ") ?? "Timezone",
                style: value == null
                    ? style?.copyWith(color: colorScheme.onSurfaceVariant)
                    : style,
              ),
              SizedBox(
                width: iconSize + 12,
                child: saving.active
                    ? Center(
                        child: SizedBox.square(
                          dimension: iconSize - 4,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(
                        Icons.edit,
                        size: iconSize,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
            ],
          ),
        ),
      ),
      suggestionsBuilder: (context, controller) {
        final query = controller.text.trim().toLowerCase().replaceAll(" ", "_");

        return [
          if (value != null && query.isEmpty)
            ListTile(
              leading: Icon(Icons.close),
              title: Text("Remove timezone"),
              onTap: () => choose(controller, null),
            ),
          ...timezones
              .where((timezone) => timezone.toLowerCase().contains(query))
              .map(
                (timezone) => ListTile(
                  leading: Icon(
                    timezone == value ? Icons.check : Icons.schedule,
                  ),
                  title: Text(timezone.replaceAll("_", " ")),
                  subtitle: Text(offsetOf(timezone)),
                  onTap: () => choose(controller, timezone),
                ),
              ),
        ];
      },
    );
  }
}
