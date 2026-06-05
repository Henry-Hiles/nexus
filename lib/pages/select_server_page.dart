import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:nexus/models/homeserver.dart";
import "package:nexus/pages/login_page.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/divider_text.dart";

class SelectServerPage extends HookConsumerWidget {
  const SelectServerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final launch = ref.watch(LaunchHelper.provider).launchUrl;

    final isLoading = useState(false);
    final homeserverUrl = useTextEditingController();

    Future<void> setHomeserver(Uri? newHomeserver) async {
      isLoading.value = true;

      try {
        if (newHomeserver?.hasScheme == false) {
          newHomeserver = Uri.https(newHomeserver!.path);
        }

        final newUrl = newHomeserver == null
            ? null
            : await ref
                  .watch(ClientController.provider.notifier)
                  .discoverHomeserver(newHomeserver);

        if (context.mounted) {
          if (newUrl == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Homeserver verification failed. Is your homeserver down?",
                  style: .new(color: theme.colorScheme.onErrorContainer),
                ),
                backgroundColor: theme.colorScheme.errorContainer,
              ),
            );
          } else {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LoginPage(homeserver: newUrl)),
            );
          }
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: Appbar(),
      body: Center(
        child: ConstrainedBox(
          constraints: .new(maxWidth: 600),
          child: ListView(
            children: [
              Row(
                children: [
                  SvgPicture.asset("assets/icon.svg", width: 128),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text("Nexus", style: theme.textTheme.displayMedium),
                        Text(
                          "A Simple Matrix Client",
                          style: theme.textTheme.headlineMedium,
                          overflow: .ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(padding: .symmetric(vertical: 12), child: Divider()),
              DividerText("Enter a homeserver domain:"),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: TextField(
                      textInputAction: .done,
                      autofocus: true,
                      onSubmitted: (text) => setHomeserver(.tryParse(text)),
                      controller: homeserverUrl,
                      decoration: .new(
                        labelText: "Homeserver URL",
                        hintText: "matrix.org",
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: "Confirm homeserver choice",
                    onPressed: isLoading.value
                        ? null
                        : () => setHomeserver(.tryParse(homeserverUrl.text)),
                    icon: Icon(Icons.check),
                  ),
                ],
              ),
              DividerText("Or, choose from some popular homeservers:"),
              ...(<Homeserver>[
                .new(
                  name: "Matrix.org",
                  description:
                      "The Matrix.org Foundation offers the matrix.org homeserver as an easy entry point for anyone wanting to try out Matrix.",
                  url: .https("matrix.org"),
                  iconUrl:
                      "https://raw.githubusercontent.com/element-hq/logos/refs/heads/master/matrix/matrix-favicon${Theme.brightnessOf(context) == Brightness.dark ? "-white" : ""}.png",
                ),
                .new(
                  name: "Federated Nexus",
                  description:
                      "Federated Nexus is a community resource hosting multiple FOSS (especially federated) services, including Matrix and Forgejo. By the same developers who made Nexus client.",
                  url: .https("federated.nexus"),
                  iconUrl: "https://federated.nexus/images/icon.png",
                ),
                .new(
                  name: "Unredacted",
                  description:
                      "Unredacted is a 501(c)(3) non-profit organization that builds Internet infrastructure and services to help people evade censorship and protect their right to privacy.",
                  url: .https("unredacted.org", "services/si/matrix"),
                  iconUrl: "https://unredacted.org/favicon.ico",
                ),
              ].map(
                (homeserver) => Card(
                  child: ListTile(
                    enabled: !isLoading.value,
                    title: Text(homeserver.name),
                    leading: Image.network(
                      homeserver.iconUrl,
                      errorBuilder: (_, _, _) => SizedBox.shrink(),
                      height: 32,
                    ),
                    subtitle: Text(homeserver.description),
                    onTap: isLoading.value
                        ? null
                        : () => setHomeserver(homeserver.url),
                    trailing: IconButton(
                      tooltip: "Launch homeserver info page",
                      onPressed: () => launch(homeserver.url),
                      icon: Icon(Icons.info_outline),
                    ),
                  ),
                ),
              )),

              TextButton(
                onPressed: () => launch(.https("servers.joinmatrix.org")),
                child: Text("See more homeservers..."),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
