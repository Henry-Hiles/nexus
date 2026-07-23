import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_id.dart";
import "package:nexus/models/oauth_auth_code_response.dart";
import "package:nexus/models/requests/oauth/get_auth_url.dart";

class AuthUrlController extends AsyncNotifier<OAuthAuthCodeResponse> {
  final Uri homeserver;
  AuthUrlController(this.homeserver);

  @override
  Future<OAuthAuthCodeResponse> build() async => ref
      .watch(ClientController.provider.notifier)
      .getAuthUrl(
        .new(
          homeserverUrl: homeserver,
          redirectUri: .new(scheme: "nexus.federated.nexus", path: "/"),
          responseMode: .query,
          scopes: .new([Scope.clientApi, Scope.device]),
          clientId: await ref.watch(
            ClientIdController.provider(homeserver).future,
          ),
        ),
      );

  static final provider = AsyncNotifierProvider.family
      .autoDispose<AuthUrlController, OAuthAuthCodeResponse, Uri>(
        AuthUrlController.new,
      );
}
