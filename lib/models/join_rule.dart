import "package:freezed_annotation/freezed_annotation.dart";

@JsonEnum(fieldRename: FieldRename.snake)
enum JoinRule { public, knock, invite, private, restricted, knockRestricted }
