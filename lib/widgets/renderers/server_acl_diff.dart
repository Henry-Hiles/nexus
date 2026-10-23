import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/success_scheme.dart";
import "package:nexus/models/content/server_acl.dart";

/// The servers newly denied (in red) and allowed (in green) by a server ACL
/// event, and those no longer denied or allowed, struck through.
class const ServerAclDiff(
  final ServerACLContent content, {
  final ServerACLContent? previous,
  super.key,
}) extends StatelessWidget {
  static const maxShown = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium;
    final colorScheme = theme.colorScheme;

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
      final beforeSet = before.toISet();
      final afterSet = after.toISet();
      final servers = [
        ...after
            .where((server) => !beforeSet.contains(server))
            .map((server) => (server, removed: false)),
        ...before
            .where((server) => !afterSet.contains(server))
            .map((server) => (server, removed: true)),
      ];
      if (servers.isEmpty && !ipLiterals) return null;

      return Wrap(
        spacing: 8,
        runSpacing: 2,
        children: [
          Text(label, style: style?.copyWith(fontWeight: .bold)),
          ...servers
              .take(maxShown)
              .map(
                (server) => Text(
                  "\"${server.$1}\"",
                  style: style?.copyWith(
                    color: color,
                    decoration: server.removed ? .lineThrough : null,
                  ),
                ),
              ),
          if (servers.length > maxShown)
            Text(
              "+${servers.length - maxShown} more",
              style: style?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          if (ipLiterals)
            Text(
              "servers using IP addresses",
              style: style?.copyWith(color: color),
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
          colorScheme.error,
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
