import "package:freezed_annotation/freezed_annotation.dart";

part "account.freezed.dart";
part "account.g.dart";

/// An account slot, each with its own gomuks directories.
///
/// Everything but [id] is cached from the last time the account was active, so
/// the account switcher and push routing work while it isn't.
@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Account({
  required final String id,
  final String? userId,
  final String? deviceId,
  final String? displayName,
  final Uri? avatar,
}) with _$Account {
  /// The slot accounts from before account switching existed
  static const String legacyId = "default";

  Map<String, Object?> toJson() => _$AccountToJson(this);

  factory Account.fromJson(Map<String, Object?> json) =>
      _$AccountFromJson(json);
}
