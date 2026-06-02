import "package:cross_cache/cross_cache.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/controllers/url_preview_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/helpers/launch_helper.dart";

class UrlPreview extends ConsumerWidget {
  final String link;
  const UrlPreview(this.link, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ConstrainedBox(
    constraints: .loose(.fromWidth(400)),
    child: ref
        .watch(UrlPreviewController.provider(link))
        .betterWhen(
          data: (preview) => preview == null
              ? SizedBox.shrink()
              : InkWell(
                  onTap: () =>
                      ref.watch(LaunchHelper.provider).launchUrl(.parse(link)),
                  child: Card(
                    margin: .symmetric(vertical: 4),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: .all(16),
                      child: Column(
                        crossAxisAlignment: .start,
                        spacing: 4,
                        children: [
                          if (preview.title != null)
                            Text(
                              preview.title!,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          if (preview.description != null) ...[
                            Text(preview.description!),
                            SizedBox(height: 4),
                          ],
                          if (preview.imageUrl != null)
                            ClipRRect(
                              borderRadius: .all(.circular(8)),
                              child: Image(
                                errorBuilder: (_, _, _) => SizedBox.shrink(),
                                width: preview.width,
                                image: CachedNetworkImage(
                                  preview.imageUrl.toString(),
                                  ref.watch(CrossCacheController.provider),
                                  headers: ref.headers,
                                ),
                                fit: .fitWidth,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
  );
}
