import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";

class ClientIdController(final Uri homeserver) extends AsyncNotifier<String> {
  @override
  Future<String> build() => ref
      .watch(ClientController.provider.notifier)
      .registerClient(
        .new(
          clientName: "Nexus",
          applicationType: .native,
          grantTypes: .new([.authorizationCode, .refreshToken]),
          responseTypes: .new([.code]),
          logoUri: Uri.https(
            "nexus.federated.nexus",
            "raw/branch/main/assets/mobile.svg",
          ),
          homeserverUrl: homeserver,
          clientUri: Uri.https("nexus.federated.nexus"),
          redirectUris: .new([
            .new(scheme: "nexus.federated.nexus", path: "/"),
          ]),
        ),
      );

  static final provider =
      AsyncNotifierProvider.family<ClientIdController, String, Uri>(
        ClientIdController.new,
      );
}
