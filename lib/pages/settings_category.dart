import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/settings_sections.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/widgets/highlight_wrapper.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class SettingsCategoryPage extends HookConsumerWidget {
  final int index;
  final int? initialHighlight;
  const SettingsCategoryPage(this.index, {this.initialHighlight, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlight = useState<int?>(initialHighlight);
    final listController = useRef(ListController());
    final scrollController = useScrollController();

    useEffect(() {
      if (initialHighlight == null) return null;
      Timer? timer;

      void listener() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!listController.value.isAttached) return;

        listController.value.animateToItem(
          index: initialHighlight!,
          scrollController: scrollController,
          alignment: 0.5,
          duration: (_) => .new(milliseconds: 700),
          curve: (_) => Curves.easeInOut,
        );
        timer = Timer(.new(seconds: 1), () {
          highlight.value = null;
        });
        listController.value.removeListener(listener);
      });

      listController.value.addListener(listener);
      return timer?.cancel;
    }, []);

    return ref
        .watch(SettingsSectionsController.provider)
        .betterWhen(
          data: (sections) => Scaffold(
            appBar: AppBar(
              title: Text(sections.values.flattenedToList[index].title),
            ),
            body: SafeArea(
              child: SuperListView(
                controller: scrollController,
                listController: listController.value,
                padding: .symmetric(vertical: 12, horizontal: 8),
                children: sections.values.flattenedToList[index].settings
                    .mapIndexed(
                      (index, setting) => Padding(
                        padding: .only(bottom: 4),
                        child: HighlightWrapper(
                          setting.builder(
                            setting.title,
                            setting.description,
                            setting.icon,
                          ),
                          isHighlighted: highlight.value == index,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
  }
}
