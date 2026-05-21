import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/info/audio.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/info/file.dart";
import "package:nexus/models/info/image.dart";
import "package:nexus/models/info/video.dart";
part "message.freezed.dart";
part "message.g.dart";

@Freezed(unionKey: "msgtype", fallbackUnion: "default")
abstract class MessageContent extends Content with _$MessageContent {
  MessageContent._();
  factory MessageContent({required String body}) = UnknownMessageContent;

  @FreezedUnionValue("m.text")
  factory MessageContent.text({
    required String body,
    MessageFormat? format,
    String? formattedBody,
  }) = TextMessageContent;

  @FreezedUnionValue("m.notice")
  factory MessageContent.notice({
    required String body,
    MessageFormat? format,
    String? formattedBody,
  }) = NoticeMessageContent;

  @FreezedUnionValue("m.emote")
  factory MessageContent.emote({
    required String body,
    MessageFormat? format,
    String? formattedBody,
  }) = EmoteMessageContent;

  @FreezedUnionValue("m.image")
  factory MessageContent.image({
    required String body,
    MessageFormat? format,
    String? formattedBody,
    // EncryptedFile? file
    String? filename,
    ImageInfo? info,
    Uri? url,
  }) = ImageMessageContent;

  @FreezedUnionValue("m.file")
  factory MessageContent.file({
    required String body,
    MessageFormat? format,
    String? formattedBody,
    // EncryptedFile? file
    String? filename,
    FileInfo? info,
    Uri? url,
  }) = FileMessageContent;

  @FreezedUnionValue("m.audio")
  factory MessageContent.audio({
    required String body,
    MessageFormat? format,
    String? formattedBody,
    // EncryptedFile? file
    String? filename,
    AudioInfo? info,
    Uri? url,
  }) = AudioMessageContent;

  @FreezedUnionValue("m.video")
  factory MessageContent.video({
    required String body,
    MessageFormat? format,
    String? formattedBody,
    // EncryptedFile? file
    String? filename,
    VideoInfo? info,
    Uri? url,
  }) = VideoMessageContent;

  @FreezedUnionValue("m.location")
  factory MessageContent.location({required String body, required Uri geoUri}) =
      LocationMessageContent;

  factory MessageContent.fromJson(Map<String, Object?> json) =>
      _$MessageContentFromJson(json);
}

@JsonEnum()
enum MessageFormat {
  @JsonValue("org.matrix.custom.html")
  html,
}
