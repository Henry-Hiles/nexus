import "package:file_selector/file_selector.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/composer_params.dart";
import "package:path/path.dart";

typedef AttachmentParams = ({ComposerParams composer, int? editingRowId});

class AttachmentController(final AttachmentParams params)
    extends Notifier<(String, MessageContent?)?> {
  @override
  Null build() => null;

  Future<void> add(XFile file) async {
    final filename = basename(file.path);
    state = (filename, null);

    final isEncrypted = ref.read(
      RoomsController.provider.select(
        (value) =>
            value[params.composer.roomId]
                ?.state[EventType.encryption.type]
                ?.isNotEmpty ==
            true,
      ),
    );

    final content = await ref
        .read(ClientController.provider.notifier)
        .uploadMedia(.new(path: file.path, encrypt: isEncrypted));

    state = (filename, content);
  }

  void set((String, MessageContent?)? attachment) => state = attachment;

  static final provider =
      NotifierProvider.family<
        AttachmentController,
        (String, MessageContent?)?,
        AttachmentParams
      >(AttachmentController.new);
}
