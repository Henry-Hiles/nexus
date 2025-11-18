import "package:flutter/foundation.dart";
import "package:matrix/matrix.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class ClientController extends AsyncNotifier<Client> {
  @override
  Future<Client> build() async => Client(
    "nexus",
    logLevel: kReleaseMode ? Level.warning : Level.verbose,
    importantStateEvents: {"im.ponies.room_emotes"},
    supportedLoginTypes: {AuthenticationTypes.password},
    database: await MatrixSdkDatabase.init(
      "nexus",
      database: await databaseFactoryFfi.openDatabase(
        join((await getApplicationSupportDirectory()).path, "database.db"),
      ),
    ),
  );

  Future<bool> setHomeserver(Uri homeserverUrl) async {
    final client = await future;
    try {
      await client.checkHomeserver(homeserverUrl);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    final client = await future;
    try {
      await client.login(
        LoginType.mLoginPassword,
        initialDeviceDisplayName:
            "Nexus Client login at ${DateTime.now().toIso8601String()}",
        identifier: AuthenticationUserIdentifier(user: username),
        password: password,
      );
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }

  static final provider = AsyncNotifierProvider<ClientController, Client>(
    ClientController.new,
  );
}
