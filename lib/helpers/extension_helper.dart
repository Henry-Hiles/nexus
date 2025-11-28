import "package:flutter/material.dart";
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
    await loadHeroUsers();
    return FullRoom(
      roomData: this,
      title: getLocalizedDisplayname(),
      avatar: await avatar?.getThumbnailUri(client, width: 24, height: 24),
    );
  }
}

extension GetHeaders on Client {
  Map<String, String> get headers => {"authorization": "Bearer $accessToken"};
}

extension ToMessage on Event {
  Future<Message?> toMessage({bool mustBeText = false}) async {
    final replyId = relationshipType == RelationshipTypes.reply
        ? relationshipEventId
        : null;
    final sender = (await fetchSenderUser()) ?? senderFromMemoryOrFallback;

    final newContent = content["m.new_content"] as Map<String, Object?>?;
    final metadata = {
      "formatted":
          newContent?["formatted_body"] ??
          newContent?["body"] ??
          (formattedText.isEmpty ? this.body : formattedText),
      "eventType": type,
      "displayName": sender.displayName ?? sender.id,
      "txnId": transactionId,
    };

    final editedAt = relationshipType == RelationshipTypes.edit
        ? originServerTs
        : null;
    final body = newContent?["body"] as String? ?? this.body;
    final eventId = editedAt == null
        ? this.eventId
        : relationshipEventId ?? this.eventId;

    if (redacted) return null;

    final asText =
        Message.text(
              metadata: metadata,
              id: eventId,
              authorId: senderId,
              text: body,
              replyToMessageId: replyId,
              deliveredAt: originServerTs,
              editedAt: editedAt,
            )
            as TextMessage;

    if (mustBeText) return asText;

    return switch (type) {
      EventTypes.Encrypted => asText.copyWith(
        text: "Unable to decrypt message.",
        metadata: {"formatted": "Unable to decrypt message.", ...metadata},
      ),
      EventTypes.Message => switch (messageType) {
        MessageTypes.Image => Message.image(
          metadata: metadata,
          id: eventId,
          authorId: senderId,
          text: text,
          source: (await getAttachmentUri()).toString(),
          replyToMessageId: replyId,
          deliveredAt: originServerTs,
        ),
        MessageTypes.Audio => Message.audio(
          metadata: metadata,
          id: eventId,
          authorId: senderId,
          text: text,
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

extension ToTheme on ColorScheme {
  ThemeData get theme => ThemeData.from(colorScheme: this).copyWith(
    cardTheme: CardThemeData(color: primaryContainer),
    appBarTheme: AppBarTheme(
      titleSpacing: 0,
      backgroundColor: surfaceContainerLow,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

extension ToMessages on List<MatrixEvent> {
  Future<List<Message>> toMessages(Room room) async {
    final messages = await Future.wait(
      map((event) => Event.fromMatrixEvent(event, room).toMessage()),
    );

    return {
      for (var msg in messages.nonNulls.toList().reversed.toList()) msg.id: msg,
    }.values.toList();
  }
}
