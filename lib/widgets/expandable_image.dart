import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:m3e_buttons/m3e_buttons.dart";
import "package:nexus/helpers/mxc_image.dart";
import "package:nexus/models/requests/download_media.dart";
import "package:nexus/widgets/error_dialog.dart";

class ExpandableImage extends ConsumerWidget {
  final Widget child;
  final DownloadMediaRequest? request;
  const ExpandableImage(this.request, {required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => InkWell(
    onTap: request == null
        ? null
        : () => showDialog(
            context: context,
            builder: (_) => SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: Navigator.of(context).pop,
                      child: InteractiveViewer(
                        maxScale: 10,
                        child: Image(
                          errorBuilder: (_, error, stackTrace) => ErrorDialog(
                            "Loading failed for ${request?.mxc}\nError: $error",
                            stackTrace,
                          ),
                          image: MxcImage(ref, request!),
                        ),
                      ),
                    ),
                  ),
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
                ],
              ),
            ),
          ),
    child: child,
  );
}
