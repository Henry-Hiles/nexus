import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";

/// The [chosen] items, above a field searching [options] to choose more.
class const SearchChooser({
  required final TextEditingController controller,
  required final ISet<String> chosen,

  required final IList<String> options,

  required final String Function(String id) nameOf,
  required final Widget Function(String id) avatarOf,
  required final String? Function(String id) subtitleOf,
  required final void Function(String id) onAdded,
  required final void Function(String id) onRemoved,

  /// The submitted text, and the top suggestion matching it if there is one.
  required final void Function(String text, String? topMatch) onSubmitted,
  required final String label,
  required final String hint,
  required final String removeTooltip,

  final String? emptyText,
  final String? error,
  final bool loading = false,
  final bool autofocus = false,
  final void Function(String text)? onChanged,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final query = useValueListenable(controller).text.trim().toLowerCase();
    final shown = options
        .where(
          (id) =>
              !chosen.contains(id) &&
              (nameOf(id).toLowerCase().contains(query) ||
                  id.toLowerCase().contains(query)),
        )
        .toIList();

    ListTile tileOf(String id, {Widget? trailing, VoidCallback? onTap}) =>
        ListTile(
          leading: avatarOf(id),
          title: Text(nameOf(id), overflow: .ellipsis),
          subtitle: switch (subtitleOf(id)) {
            final subtitle? => Text(subtitle, overflow: .ellipsis),
            null => null,
          },
          trailing: trailing,
          onTap: onTap,
        );

    AnimatedSize animated(Widget? child) => AnimatedSize(
      duration: Durations.medium2,
      curve: Curves.easeInOut,
      alignment: .topCenter,
      child: child ?? const SizedBox(width: .infinity),
    );

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        animated(switch ((chosen.isEmpty, emptyText)) {
          (true, null) => null,
          (true, final emptyText?) => Padding(
            padding: .only(bottom: 12),
            child: Text(emptyText),
          ),
          (false, _) => Padding(
            padding: .only(bottom: 12),
            child: Column(
              children: chosen
                  .map(
                    (id) => tileOf(
                      id,
                      trailing: IconButton(
                        tooltip: removeTooltip,
                        icon: Icon(Icons.delete),
                        onPressed: () => onRemoved(id),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        }),
        TextField(
          controller: controller,
          enabled: !loading,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: (text) {
            final trimmed = text.trim();
            if (trimmed.isNotEmpty) onSubmitted(trimmed, shown.firstOrNull);
          },
          decoration: .new(
            labelText: label,
            hintText: hint,
            errorText: error,
            suffixIcon: loading
                ? Padding(
                    padding: .all(12),
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(),
                    ),
                  )
                : null,
          ),
        ),
        animated(
          shown.isEmpty
              ? null
              : Padding(
                  padding: .only(top: 12, bottom: 4),
                  child: Material(
                    elevation: 4,
                    borderRadius: .circular(12),
                    clipBehavior: .antiAlias,
                    child: ConstrainedBox(
                      constraints: const .new(maxHeight: 240),
                      child: ListView.builder(
                        padding: .zero,
                        shrinkWrap: true,
                        itemExtent: 72,
                        itemCount: shown.length,
                        itemBuilder: (context, index) => tileOf(
                          shown[index],
                          onTap: () => onAdded(shown[index]),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
