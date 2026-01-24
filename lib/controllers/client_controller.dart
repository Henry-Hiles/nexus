import "dart:convert";
import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:flutter/foundation.dart";
import "package:nexus/helpers/extensions/gomuks_buffer.dart";
import "package:nexus/models/client_state.dart";
import "package:nexus/models/sync_status.dart";
import "package:nexus/src/third_party/gomuks.g.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

void gomuksCallback(
  Pointer<Char> command,
  int requestId,
  GomuksBorrowedBuffer data,
) {
  try {
    final muksEventType = command.cast<Utf8>().toDartString();
    final Map<String, dynamic> decodedMuksEvent = data.toJson();

    switch (muksEventType) {
      case "client_state":
        final clientState = ClientState.fromJson(decodedMuksEvent);
        debugPrint("Received event: $clientState");
      case "sync_status":
        final syncStatus = SyncStatus.fromJson(decodedMuksEvent);
        debugPrint("Received event: $syncStatus");
    }
  } catch (error, stackTrace) {
    debugPrintStack(stackTrace: stackTrace, label: error.toString());
  }
}

class ClientController extends Notifier<int> {
  @override
  int build() {
    final handle = GomuksInit();
    ref.onDispose(() => GomuksDestroy(handle));

    GomuksStart(
      handle,
      Pointer.fromFunction<
        Void Function(Pointer<Char>, Int64, GomuksBorrowedBuffer)
      >(gomuksCallback),
    );

    return handle;
  }

  void sendCommand(String command, Map<String, dynamic> data) {
    // final response = GomuksSubmitCommand(
    //   state,
    //   command.toNativeUtf8().cast<Char>(),
    //   data.toGomuksBuffer(),
    // );

    // return response.buf; TODO
  }

  static final provider = NotifierProvider<ClientController, int>(
    ClientController.new,
  );
}
