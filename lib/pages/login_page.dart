import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:nexus/models/homeserver.dart";
import "package:nexus/models/login.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/divider_text.dart";
import "package:nexus/widgets/loading.dart";

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final client = ref.watch(ClientController.provider.notifier);

    final isLoading = useState(false);
    final homeserver = useState<String?>(null);

    final launch = ref.watch(LaunchHelper.provider).launchUrl;

    Future<void> setHomeserver(Uri? newHomeserver) async {
      isLoading.value = true;

      homeserver.value = newHomeserver == null
          ? null
          : await client.discoverHomeserver(
              newHomeserver.hasScheme
                  ? newHomeserver
                  : Uri.https(newHomeserver.path),
            );

      if (homeserver.value == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Homeserver verification failed. Is your homeserver down?",
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
            backgroundColor: theme.colorScheme.errorContainer,
          ),
        );
      }
      isLoading.value = false;
    }

    final homeserverUrl = useTextEditingController();
    final username = useTextEditingController();
    final password = useTextEditingController();

    return Scaffold(
      appBar: Appbar(),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64),
            children: [
              Row(
                children: [
                  SvgPicture.asset("assets/icon.svg"),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Nexus", style: theme.textTheme.displayMedium),
                        Text(
                          "A Simple Matrix Client",
                          style: theme.textTheme.headlineMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 12),
                child: Divider(),
              ),

              DividerText("Enter a homeserver domain:"),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: TextField(
                      controller: homeserverUrl,
                      decoration: InputDecoration(
                        labelText: "Homeserver URL (e.g. matrix.org)",
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: isLoading.value
                        ? null
                        : () => setHomeserver(Uri.tryParse(homeserverUrl.text)),
                    icon: Icon(Icons.check),
                  ),
                ],
              ),

              DividerText("Or, choose from some popular homeservers:"),
              ...(<Homeserver>[
                Homeserver(
                  name: "Matrix.org",
                  description:
                      "The Matrix.org Foundation offers the matrix.org homeserver as an easy entry point for anyone wanting to try out Matrix.",
                  url: Uri.https("matrix.org"),
                  iconUrl:
                      "https://raw.githubusercontent.com/element-hq/logos/refs/heads/master/matrix/matrix-favicon${Theme.brightnessOf(context) == Brightness.dark ? "-white" : ""}.png",
                ),
                Homeserver(
                  name: "Federated Nexus",
                  description:
                      "Federated Nexus is a community resource hosting multiple FOSS (especially federated) services, including Matrix and Forgejo. By the same developers who made Nexus client.",
                  url: Uri.https("federated.nexus"),
                  iconUrl: "https://federated.nexus/images/icon.png",
                ),
                Homeserver(
                  name: "Unredacted",
                  description:
                      "Unredacted is a 501(c)(3) non-profit organization that builds Internet infrastructure and services to help people evade censorship and protect their right to privacy.",
                  url: Uri.https("unredacted.org", "services/si/matrix"),
                  iconUrl: "https://unredacted.org/favicon.ico",
                ),
              ].map(
                (homeserver) => Card(
                  child: ListTile(
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
                      onPressed: () => launch(homeserver.url),
                      icon: Icon(Icons.info_outline),
                    ),
                  ),
                ),
              )),
              SizedBox(height: 8),
              TextButton(
                onPressed: () => launch(Uri.https("servers.joinmatrix.org")),
                child: Text("See more homeservers..."),
              ),
              if (isLoading.value)
                Padding(padding: EdgeInsets.only(top: 32), child: Loading())
              else if (homeserver.value != null) ...[
                DividerText("Then, sign in:"),
                SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(label: Text("Username")),
                  controller: username,
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(label: Text("Password")),
                  controller: password,
                  obscureText: true,
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    isLoading.value = true;
                    final succeeded = await client.login(
                      Login(
                        username: username.text,
                        password: password.text,
                        homeserverUrl: homeserver.value!,
                      ),
                    );

                    if (!succeeded && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Login failed. Is your password right?",
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                          backgroundColor: theme.colorScheme.errorContainer,
                        ),
                      );
                      isLoading.value = false;
                    }
                  },
                  child: Text("Sign In"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
