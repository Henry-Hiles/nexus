extension GetLocalpart on String {
  String get localpart => length > 1 ? substring(1).split(":").first : "?";

  /// Whether this looks like a valid Matrix user ID, e.g. `@user:example.com`.
  bool get isValidUserId => RegExp(r"^@[^:\s]+:[^\s]+$").hasMatch(this);

  /// Whether this is a valid Matrix server name, e.g. `example.com:8448`.
  bool get isValidServerName => RegExp(
    r"^(\[[0-9a-f:.]+\]|[a-z0-9.-]{1,255})(:\d{1,5})?$",
    caseSensitive: false,
  ).hasMatch(this);

  String? get serverName {
    final index = indexOf(":");
    return index == -1 ? null : substring(index + 1);
  }
}
