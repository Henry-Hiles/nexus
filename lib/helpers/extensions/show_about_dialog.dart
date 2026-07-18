import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:m3e_card_list/m3e_card_list.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:package_info_plus/package_info_plus.dart";

extension ShowContextMenu on BuildContext {
  Future<void> showAboutDialog(WidgetRef ref) async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (mounted) {
      showDialog(
        context: this,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: .min,
            spacing: 16,
            children: [
              Row(
                spacing: 12,
                children: [
                  SvgPicture.asset("assets/icon.svg", width: 64),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Wrap(
                          crossAxisAlignment: .center,
                          spacing: 4,
                          children: [
                            Text(
                              "Nexus",
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text("(${packageInfo.version})"),
                          ],
                        ),

                        Text(
                          "A simple and user-friendly Matrix client",
                          overflow: .ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              M3ECardColumn(
                onTap: (index) =>
                    ref.watch(LaunchHelper.provider).launchUrl(switch (index) {
                      0 => Uri.https("git.federated.nexus", "nexus/nexus"),
                      _ => Uri.https("liberapay.com", "QuadRadical"),
                    }),
                children: [
                  ListTile(
                    leading: Icon(Icons.commit),
                    title: Text("Source Code"),
                  ),
                  ListTile(
                    leading: Icon(Icons.favorite, color: Colors.pinkAccent),
                    title: Text("Donate"),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => showLicensePage(context: context),
              child: Text("View licenses"),
            ),
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text("Close"),
            ),
          ],
        ),
      );
    }
  }
}
