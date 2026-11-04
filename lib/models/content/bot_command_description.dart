import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/helpers/extensions/get_link_info.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/content/content.dart";

part "bot_command_description.freezed.dart";
part "bot_command_description.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const BotCommandDescriptionContent({
  required final String command,
  final IList<BotParameter> parameters = const .empty(),
  @JsonKey(fromJson: BotCommandDescriptionContent.plainText)
  final String? description,
}) extends Content with _$BotCommandDescriptionContent {
  // The plain text from an extensible events m.text block
  static String? plainText(Map<String, dynamic>? json) =>
      switch (json?["m.text"]) {
        final List representations =>
          representations
              .map(
                (representation) => switch (representation) {
                  {"mimetype": final String mimetype}
                      when mimetype != "text/plain" =>
                    null,
                  {"body": final String body} => body,
                  _ => null,
                },
              )
              .nonNulls
              .firstOrNull,
        _ => null,
      };

  bool get isValid =>
      command.trim().isNotEmpty &&
      parameters.map((parameter) => parameter.key).toISet().length ==
          parameters.length &&
      parameters.every((parameter) => parameter.schema.isValid());

  @override
  Map<String, Object?> toJson() => _$BotCommandDescriptionContentToJson(this);

  factory BotCommandDescriptionContent.fromJson(Map<String, Object?> json) =>
      _$BotCommandDescriptionContentFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const BotParameter({
  required final String key,
  required final BotParameterSchema schema,
  final bool optional = false,
  @JsonKey(fromJson: BotCommandDescriptionContent.plainText)
  final String? description,
}) with _$BotParameter {
  Map<String, Object?> toJson() => _$BotParameterToJson(this);

  factory BotParameter.fromJson(Map<String, Object?> json) =>
      _$BotParameterFromJson(json);
}

@Freezed(unionKey: "schema_type")
sealed class BotParameterSchema with _$BotParameterSchema {
  const BotParameterSchema._();

  static final separator = RegExp(r"[\s,]+");

  const factory BotParameterSchema.primitive({required BotPrimitiveType type}) =
      PrimitiveSchema;

  const factory BotParameterSchema.literal({required Object value}) =
      LiteralSchema;

  const factory BotParameterSchema.union({
    required IList<BotParameterSchema> variants,
  }) = UnionSchema;

  const factory BotParameterSchema.array({required BotParameterSchema items}) =
      ArraySchema;

  bool isValid({BotParameterSchema? parent}) => switch (this) {
    PrimitiveSchema() => true,
    LiteralSchema(:final value) =>
      value is String || value is int || value is bool,
    UnionSchema(:final variants) =>
      (parent == null || parent is ArraySchema) &&
          variants.isNotEmpty &&
          variants.every(
            (variant) =>
                variant is! UnionSchema && variant.isValid(parent: this),
          ),
    ArraySchema(:final items) => parent == null && items.isValid(parent: this),
  };

  String get label => switch (this) {
    PrimitiveSchema(:final type) => type.label,
    LiteralSchema(:final value) => "$value",
    UnionSchema(:final variants) =>
      variants.map((variant) => variant.label).join(" | "),
    ArraySchema(:final items) => "${items.label}...",
  };

  String get expected => switch (this) {
    PrimitiveSchema(:final type) => type.expected,
    LiteralSchema(:final value) => '"$value"',
    UnionSchema(:final variants) =>
      variants.map((variant) => variant.expected).join(" or "),
    ArraySchema(:final items) => items.expected,
  };

  bool allows(BotPrimitiveType type) => switch (this) {
    PrimitiveSchema(type: final allowed) => allowed == type,
    LiteralSchema() => false,
    UnionSchema(:final variants) => variants.any(
      (variant) => variant.allows(type),
    ),
    ArraySchema(:final items) => items.allows(type),
  };

  IList<Object> get literals => switch (this) {
    PrimitiveSchema() => const .empty(),
    LiteralSchema(:final value) => [value].lock,
    UnionSchema(:final variants) =>
      variants.expand((variant) => variant.literals).toIList(),
    ArraySchema(:final items) => items.literals,
  };

  Object? parse(String text, {required String roomId}) => switch (this) {
    PrimitiveSchema(:final type) => type.parse(text, roomId: roomId),
    LiteralSchema(:final value) => "$value" == text ? value : null,
    UnionSchema(:final variants) =>
      variants
          .map((variant) => variant.parse(text, roomId: roomId))
          .nonNulls
          .firstOrNull,
    ArraySchema(:final items) => items.parse(text, roomId: roomId),
  };

  ({Object? value, String? error}) parseText(
    String text, {
    required String roomId,
  }) {
    final parts = (this is ArraySchema ? text.split(separator) : [text.trim()])
        .where((part) => part.isNotEmpty)
        .map((part) => (part, parse(part, roomId: roomId)))
        .toIList();

    return switch (parts.firstWhereOrNull((part) => part.$2 == null)) {
      (final part, _) => (value: null, error: '"$part" isn\'t $expected.'),
      null when parts.isEmpty => (value: null, error: null),
      null when this is ArraySchema => (
        value: parts.map((part) => part.$2).nonNulls.toList(),
        error: null,
      ),
      null => (value: parts.first.$2, error: null),
    };
  }

  factory BotParameterSchema.fromJson(Map<String, Object?> json) =>
      _$BotParameterSchemaFromJson(json);
}

enum BotPrimitiveType(final String label, final String expected) {
  @JsonValue("string")
  string("text", "text"),
  @JsonValue("integer")
  integer("number", "a whole number"),
  @JsonValue("boolean")
  boolean("yes/no", "yes or no"),
  @JsonValue("user_id")
  userId("user", "a user ID like @alice:example.org"),
  @JsonValue("server_name")
  serverName("server", "a server name like example.org"),
  @JsonValue("room_alias")
  roomAlias("room alias", "a room alias like #room:example.org"),
  @JsonValue("room_id")
  roomId("room", "a room ID or link like !abc:example.org"),
  @JsonValue("event_id")
  eventId("event", r"a message link or event ID like $abc");

  Object? parse(String text, {required String roomId}) {
    final (:identifier, :eventId, :via) =
        text.linkInfo ??
        (identifier: text, eventId: null, via: const IList<String>.empty());

    return switch (this) {
      .string => text,
      // In the range canonical JSON allows
      .integer => switch (int.tryParse(text, radix: 10)) {
        final value? when value.abs() <= 9007199254740991 => value,
        _ => null,
      },
      .boolean => switch (text.toLowerCase()) {
        "true" || "yes" => true,
        "false" || "no" => false,
        _ => null,
      },
      .userId when identifier.startsWith("@") && identifier.contains(":") =>
        identifier,
      .roomAlias when identifier.startsWith("#") && identifier.contains(":") =>
        identifier,
      .serverName when text.isValidServerName => text,
      .roomId when identifier.startsWith("!") && eventId == null => {
        "type": "room_id",
        "id": identifier,
        if (via.isNotEmpty) "via": via.unlock,
      },
      .eventId when identifier.startsWith("!") && eventId != null => {
        "type": "event_id",
        "id": identifier,
        "event_id": eventId,
        if (via.isNotEmpty) "via": via.unlock,
      },
      .eventId when identifier.startsWith(r"$") => {
        "type": "event_id",
        "id": roomId,
        "event_id": identifier,
      },
      _ => null,
    };
  }
}
