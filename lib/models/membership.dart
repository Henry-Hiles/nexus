import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "membership.freezed.dart";

@freezed
abstract class Membership with _$Membership {
  const Membership._();
  const factory Membership({
    required Uri? avatarUrl,
    required String displayName,
    required String userId,
  }) = _Membership;

  factory Membership.fromContent(
    IMap<String, dynamic> content,
    String userId,
  ) => Membership(
    avatarUrl: Uri.tryParse(content["avatar_url"] ?? ""),
    userId: userId,
    displayName: content["displayname"] ?? userId.substring(1).split(":").first,
  );
}
