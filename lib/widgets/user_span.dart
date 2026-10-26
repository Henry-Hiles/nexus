import "package:flutter/gestures.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/author.dart";
import "package:nexus/helpers/extensions/displayname_color.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/global_rect.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/models/event.dart";

/// A user's [name] in text, opening their popover when tapped. Unlike a widget
/// in text, it wraps and ellipsizes with the rest of it.
class UserSpan extends TextSpan {
  UserSpan(
    BuildContext context,
    String name, {
    required String userId,
    required TapGestureRecognizer recognizer,
    String? roomId,
    super.style,
    super.children,
  }) : super(
         text: name,
         recognizer: recognizer
           ..onTapUp = (details) {
             if (!context.mounted) return;

             context.showUserPopover(
               userId,
               roomId: roomId,
               anchor: context.globalRectAt(details.globalPosition),
             );
           },
       );

  factory UserSpan.sender(
    BuildContext context,
    WidgetRef ref,
    Event event, {
    required TapGestureRecognizer recognizer,
  }) {
    final color = ref.displaynameColor(event.roomId, event.sender);

    return UserSpan(
      context,
      ref.watch(AuthorController.provider(event)).value?.displayName ??
          event.sender.localpart,
      userId: event.sender,
      roomId: event.roomId,
      recognizer: recognizer,
      style: TextStyle(color: color, fontWeight: .bold),
      children: [
        if (event.pmp != null)
          TextSpan(
            text: " (via ${event.sender})",
            recognizer: recognizer,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: .bold),
          ),
      ],
    );
  }
}
