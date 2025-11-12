import "package:flutter/widgets.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
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

extension ToMessage on Event {
  Future<Message?> toMessage({bool mustBeText = false}) async {
    final replyId = relationshipType == RelationshipTypes.reply
        ? relationshipEventId
        : null;
    final metadata = {
      "eventType": type,
      "displayName": senderFromMemoryOrFallback.displayName,
      "txnId": transactionId,
    };

    if (redacted) {
      return Message.text(
        metadata: metadata,
        id: eventId,
        authorId: senderId,
        text: "~~This message has been redacted.~~",
        deletedAt: redactedBecause?.originServerTs,
      );
    }

    final asText = Message.text(
      metadata: metadata,
      id: eventId,
      authorId: senderId,
      text: body,
      replyToMessageId: replyId,
      deliveredAt: originServerTs,
    );

    if (mustBeText) return asText;

    return switch (type) {
      EventTypes.Message => switch (messageType) {
        MessageTypes.Image => Message.image(
          metadata: metadata,
          id: eventId,
          authorId: senderId,
          source: (await getAttachmentUri()).toString(),
          replyToMessageId: replyId,
          deliveredAt: originServerTs,
        ),
        MessageTypes.Audio => Message.audio(
          metadata: metadata,
          id: eventId,
          authorId: senderId,
          text: body,
          replyToMessageId: replyId,
          source: (await getAttachmentUri()).toString(),
          deliveredAt: originServerTs,
          duration: Duration(hours: 1),
        ),
        MessageTypes.File => Message.file(
          name: content["filename"].toString(),
          metadata: metadata,
          id: eventId,
          authorId: senderId,
          source: (await getAttachmentUri()).toString(),
          replyToMessageId: replyId,
          deliveredAt: originServerTs,
        ),
        _ => asText,
      },
      EventTypes.RoomMember => Message.system(
        metadata: metadata,
        id: eventId,
        authorId: senderId,
        text:
            "${senderFromMemoryOrFallback.calcDisplayname()} joined the room.",
      ),
      EventTypes.Redaction => null,
      _ => Message.unsupported(
        metadata: metadata,
        id: eventId,
        authorId: senderId,
        replyToMessageId: replyId,
      ),
    };
  }
}
