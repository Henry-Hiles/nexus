import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/models/full_room.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/loading.dart";

extension BetterWhen<T> on AsyncValue<T> {
  Widget betterWhen({
    required Widget Function(T value) data,
    Widget Function() loading = Loading.new,
    bool skipLoadingOnRefresh = false,
  }) => when(
    data: data,
    error: (error, stackTrace) => ErrorDialog(error, stackTrace),
    loading: loading,
    skipLoadingOnRefresh: skipLoadingOnRefresh,
  );
}

extension GetFullRoom on Room {
  Future<FullRoom> get fullRoom async {
    return FullRoom(
      roomData: this,
      title: getLocalizedDisplayname(),
      avatar: await avatar?.asImage(client),
    );
  }
}

extension GetImage on Uri {
  Future<Image?> asImage(Client client) async {
    final thumb = await getThumbnailUri(client, width: 24, height: 24);
    return Image.network(
      thumb.toString(),
      headers: {"authorization": "Bearer ${client.accessToken}"},
    );
  }
}
