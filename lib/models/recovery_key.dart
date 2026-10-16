import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "recovery_key.freezed.dart";
part "recovery_key.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const RecoveryKey({
  required final String recoveryKey,

  required final IMap<String, dynamic> crossSigningKeys,
  final IMap<String, dynamic>? passphraseMeta,
}) with _$RecoveryKey {
  Map<String, Object?> toJson() => _$RecoveryKeyToJson(this);

  factory RecoveryKey.fromJson(Map<String, Object?> json) =>
      _$RecoveryKeyFromJson(json);
}
