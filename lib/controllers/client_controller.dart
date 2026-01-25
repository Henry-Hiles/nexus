import "dart:ffi";
import "dart:isolate";
import "package:ffi/ffi.dart";
import "package:flutter/foundation.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/sync_status_controller.dart";
import "package:nexus/helpers/extensions/gomuks_buffer.dart";
import "package:nexus/models/client_state.dart";
import "package:nexus/models/login.dart";
import "package:nexus/models/sync_status.dart";
import "package:nexus/src/third_party/gomuks.g.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class ClientController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final handle = await Isolate.run(GomuksInit);
    ref.onDispose(() => GomuksDestroy(handle));

    GomuksStart(
      handle,
      NativeCallable<
            Void Function(Pointer<Char>, Int64, GomuksBorrowedBuffer)
          >.listener((
            Pointer<Char> command,
            int requestId,
            GomuksBorrowedBuffer data,
          ) {
            try {
              final muksEventType = command.cast<Utf8>().toDartString();
              final Map<String, dynamic> decodedMuksEvent = data.toJson();

              switch (muksEventType) {
                case "client_state":
                  ref
                      .watch(ClientStateController.provider.notifier)
                      .set(ClientState.fromJson(decodedMuksEvent));
                  break;
                case "sync_status":
                  ref
                      .watch(SyncStatusController.provider.notifier)
                      .set(SyncStatus.fromJson(decodedMuksEvent));
                  break;
                case "sync_complete":
                  // ref
                  //     .watch(SyncStatusController.provider.notifier)
                  //     .set(SyncStatus.fromJson(decodedMuksEvent));
                  break;
                default:
                  debugPrint("Unhandled event: $muksEventType");
              }
            } catch (error, stackTrace) {
              debugPrintStack(stackTrace: stackTrace, label: error.toString());
            }
          })
          .nativeFunction,
    );

    return handle;
  }

  Future<Map<String, dynamic>> sendCommand(
    String command,
    Map<String, dynamic> data,
  ) async {
    final bufferPointer = data.toGomuksBufferPtr();
    final handle = await future;
    final response = await Isolate.run(
      () => GomuksSubmitCommand(
        handle,
        command.toNativeUtf8().cast<Char>(),
        bufferPointer.ref,
      ),
    );

    calloc.free(bufferPointer);

    return response.buf.toJson();
  }

  Future<bool> verify(String recoveryKey) async {
    try {
      await sendCommand("verify", {"recovery_key": recoveryKey});
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> login(Login login) async {
    try {
      await sendCommand("login", login.toJson());
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<String?> discoverHomeserver(Uri homeserver) async {
    try {
      final response = await sendCommand("discover_homeserver", {
        "user_id": "@fakeuser:${homeserver.host}",
      });
      return (response["m.homeserver"] as Map<String, dynamic>)["base_url"];
    } catch (error) {
      return null;
    }
  }

  static final provider = AsyncNotifierProvider<ClientController, int>(
    ClientController.new,
  );
}
