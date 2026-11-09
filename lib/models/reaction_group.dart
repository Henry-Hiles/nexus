import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "reaction_group.freezed.dart";

@Freezed(toJson: false, fromJson: false)
class const ReactionGroup({
  required final IList<String> senders,
  final String? shortcode,
}) with _$ReactionGroup;
