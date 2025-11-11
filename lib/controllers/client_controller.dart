import "dart:io";

import "package:matrix/matrix.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class ClientController extends AsyncNotifier<Client> {
  @override
  Future<Client> build() async {
    final client = Client(
      "nexus",
      database: await MatrixSdkDatabase.init(
        "nexus",
        database: await databaseFactoryFfi.openDatabase("./test.db"),
      ),
    );
    //mxc
    await client.checkHomeserver(Uri.https("federated.nexus"));
    await client.login(
      LoginType.mLoginPassword,
      identifier: AuthenticationUserIdentifier(user: "quadradical"),
      password: File("./password.txt").readAsStringSync(),
    );

    return client;
  }

  static final provider = AsyncNotifierProvider<ClientController, Client>(
    ClientController.new,
  );
}
