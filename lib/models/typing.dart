import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "typing.freezed.dart";
part "typing.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const Typing({
  required final String roomId,
  final IList<String> userIds = const .empty(),
}) with _$Typing {
  factory Typing.fromJson(Map<String, Object?> json) => _$TypingFromJson(json);
}
