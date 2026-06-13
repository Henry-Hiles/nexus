import "package:cross_cache/cross_cache.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:m3e_buttons/m3e_buttons.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/widgets/error_dialog.dart";

class ExpandableImage extends ConsumerWidget {
  final Widget child;
  final String? source;
  const ExpandableImage(this.source, {required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => InkWell(
    onTap: source == null
        ? null
        : () => showDialog(
            context: context,
            builder: (_) => SafeArea(
              child: Stack(
                children: [
                  Align(
                    alignment: .topRight,
                    child: Padding(
                      padding: .all(32),
                      child: M3EButton(
                        onPressed: Navigator.of(context).pop,
                        child: Icon(Icons.close),
                      ),
                    ),
                  ),
                  Center(
                    child: InteractiveViewer(
                      maxScale: 10,
                      child: Image(
                        fit: .contain,
                        errorBuilder: (_, error, stackTrace) => ErrorDialog(
                          "Loading failed for $source\nError: $error",
                          stackTrace,
                        ),
                        image: CachedNetworkImage(
                          source!,
                          ref.watch(CrossCacheController.provider),
                          headers: ref.headers,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    child: child,
  );
}
