import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/client_state.dart";

class ClientStateController extends Notifier<ClientState?> {
  @override
  Null build() => null;

  void set(ClientState newState) {
    state = newState;
  }

  static final provider = NotifierProvider<ClientStateController, ClientState?>(
    ClientStateController.new,
  );
}
