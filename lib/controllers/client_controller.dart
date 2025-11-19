import "dart:convert";
import "dart:io";
import "package:flutter/foundation.dart";
import "package:vodozemac/vodozemac.dart" as voz;
import "package:flutter_vodozemac/flutter_vodozemac.dart" as voz_fl;
import "package:matrix/matrix.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/secure_storage_controller.dart";
import "package:nexus/models/session_backup.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class ClientController extends AsyncNotifier<Client> {
  static const sessionBackupKey = "sessionBackup";
  @override
  Future<Client> build() async {
    if (!voz.isInitialized()) await voz_fl.init();
    final client = Client(
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

    final backupJson = await ref
        .watch(SecureStorageController.provider.notifier)
        .get(sessionBackupKey);

    if (backupJson != null) {
      final backup = SessionBackup.fromJson(json.decode(backupJson));

      await client.init(
        waitForFirstSync: false,
        newToken: backup.accessToken,
        newHomeserver: backup.homeserver,
        newUserID: backup.userID,
        newDeviceID: backup.deviceID,
        newDeviceName: backup.deviceName,
      );
    }

    ref.onDispose(
      client.onRoomState.stream.listen((_) => ref.notifyListeners()).cancel,
    );

    return client;
  }

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
      final deviceName = "Nexus Client login on ${Platform.localHostname}";
      final details = await MatrixApi(homeserver: client.homeserver).login(
        LoginType.mLoginPassword,
        initialDeviceDisplayName: deviceName,
        identifier: AuthenticationUserIdentifier(user: username),
        password: password,
      );
      await ref
          .watch(SecureStorageController.provider.notifier)
          .set(
            sessionBackupKey,
            json.encode(
              SessionBackup(
                accessToken: details.accessToken,
                homeserver: client.homeserver!,
                userID: details.userId,
                deviceID: details.deviceId,
                deviceName: deviceName,
              ).toJson(),
            ),
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
