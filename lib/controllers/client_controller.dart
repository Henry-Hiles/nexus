import "dart:convert";
import "dart:io";
import "package:flutter/foundation.dart";
import "package:matrix/encryption.dart";
import "package:nexus/controllers/database_controller.dart";
import "package:vodozemac/vodozemac.dart" as vod;
import "package:flutter_vodozemac/flutter_vodozemac.dart" as fl_vod;
import "package:matrix/matrix.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/secure_storage_controller.dart";
import "package:nexus/models/session_backup.dart";

class ClientController extends AsyncNotifier<Client> {
  @override
  bool updateShouldNotify(
    AsyncValue<Client> previous,
    AsyncValue<Client> next,
  ) =>
      previous.hasValue != next.hasValue ||
      previous.value?.accessToken != next.value?.accessToken;
  static const sessionBackupKey = "sessionBackup";

  @override
  Future<Client> build() async {
    if (!vod.isInitialized()) fl_vod.init();
    final client = Client(
      "nexus",
      logLevel: kReleaseMode ? Level.warning : Level.verbose,
      importantStateEvents: {"im.ponies.room_emotes"},
      supportedLoginTypes: {AuthenticationTypes.password},
      verificationMethods: {KeyVerificationMethod.emoji},
      database: await MatrixSdkDatabase.init(
        "nexus",
        database: await ref.watch(DatabaseController.provider.future),
      ),
      nativeImplementations: NativeImplementationsIsolate(
        compute,
        vodozemacInit: fl_vod.init,
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

    if (client.userID != null) {
      //   client.encryption?.keyVerificationManager.addRequest(
      //     KeyVerification(encryption: client.encryption!, userId: client.userID!),
      //   );
    }

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
      ref.invalidateSelf(asReload: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  static final provider = AsyncNotifierProvider<ClientController, Client>(
    ClientController.new,
  );
}
