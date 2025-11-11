import "dart:io";

import "package:flutter/foundation.dart";
import "package:matrix/matrix.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class ClientController extends AsyncNotifier<Client> {
  @override
  Future<Client> build() async {
    final client = Client(
      "nexus",
      logLevel: kReleaseMode ? Level.warning : Level.verbose,
      importantStateEvents: {"im.ponies.room_emotes"},
      database: await MatrixSdkDatabase.init(
        "nexus",
        database: await databaseFactoryFfi.openDatabase(
          join((await getApplicationSupportDirectory()).path, "database.db"),
        ),
      ),
    );

    // TODO: Save info
    if (client.homeserver == null) {
      await client.checkHomeserver(Uri.https("federated.nexus"));
    }
    if (client.accessToken == null) {
      await client.login(
        LoginType.mLoginPassword,
        identifier: AuthenticationUserIdentifier(user: "quadradical"),
        password: File("./password.txt").readAsStringSync(),
      );
    }

    return client;
  }

  static final provider = AsyncNotifierProvider<ClientController, Client>(
    ClientController.new,
  );
}
