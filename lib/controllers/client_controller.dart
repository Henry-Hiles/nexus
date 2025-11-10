import "dart:io";

import "package:matrix/matrix.dart";
import "package:nexusbot/controllers/settings_controller.dart";
import "package:riverpod/riverpod.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class ClientController extends AsyncNotifier<Client> {
  @override
  Future<Client> build() async {
    final settings = ref.watch(SettingsController.provider)!;
    final client = Client(
      "nexusbot",
      database: await MatrixSdkDatabase.init(
        "NexusBot",
        database: await databaseFactoryFfi.openDatabase(inMemoryDatabasePath),
      ),
    );

    await client.checkHomeserver(settings.homeserver);
    await client.login(
      LoginType.mLoginPassword,
      identifier: AuthenticationUserIdentifier(user: settings.name),
      password: (await File(settings.botPasswordFile).readAsString()).trim(),
    );

    return client;
  }

  static final provider = AsyncNotifierProvider<ClientController, Client>(
    ClientController.new,
  );
}
