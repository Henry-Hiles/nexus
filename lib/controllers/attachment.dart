import "package:file_selector/file_selector.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/message.dart";
import "package:path/path.dart";

class AttachmentController extends Notifier<(String, MessageContent?)?> {
  final String roomId;
  AttachmentController(this.roomId);

  @override
  Null build() => null;

  Future<void> add(XFile file) async {
    final filename = basename(file.path);
    state = (filename, null);

    final isEncrypted = ref.read(
      RoomsController.provider.select(
        (value) =>
            value[roomId]?.state[EventType.encryption.type]?.isNotEmpty == true,
      ),
    );

    final content = await ref
        .watch(ClientController.provider.notifier)
        .uploadMedia(.new(path: file.path, encrypt: isEncrypted));

    state = (filename, content);
  }

  static final provider = NotifierProvider.family
      .autoDispose<AttachmentController, (String, MessageContent?)?, String>(
        AttachmentController.new,
      );
}
