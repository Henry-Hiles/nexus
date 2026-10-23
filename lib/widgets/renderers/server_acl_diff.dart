import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/success_scheme.dart";
import "package:nexus/models/content/server_acl.dart";
import "package:nexus/widgets/renderers/change_line.dart";

/// The servers newly denied (in red) and allowed (in green) by a server ACL
/// event, and those no longer denied or allowed, struck through.
class const ServerAclDiff(
  final ServerACLContent content, {
  final ServerACLContent? previous,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ipLiteralsAllowed = switch (previous) {
      final previous?
          when previous.allowIpLiterals != content.allowIpLiterals =>
        content.allowIpLiterals == true,
      _ => null,
    };

    Widget? listDiff(
      String label,
      Color color,
      IList<String> before,
      IList<String> after, {
      required bool ipLiterals,
    }) {
      // Sets, as an ACL can list hundreds of servers
      final beforeSet = before.toISet();
      final afterSet = after.toISet();
      final removed = before.where((server) => !afterSet.contains(server));
      final added = after.where((server) => !beforeSet.contains(server));
      if (removed.isEmpty && added.isEmpty && !ipLiterals) return null;

      return ChangeLine(
        label: label,
        removed: .new(removed),
        added: .new(added),
        removedColor: color,
        addedColor: color,
        trailing: [
          if (ipLiterals)
            Text(
              "servers using IP addresses",
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: .start,
      spacing: 2,
      children: [
        ?listDiff(
          "Denied",
          theme.colorScheme.error,
          previous?.deny ?? const .empty(),
          content.deny,
          ipLiterals: ipLiteralsAllowed == false,
        ),
        ?listDiff(
          "Allowed",
          theme.successScheme.primary,
          previous?.allow ?? const .empty(),
          content.allow,
          ipLiterals: ipLiteralsAllowed == true,
        ),
      ],
    );
  }
}
