extension GetLocalpart on String {
  String get localpart => length > 1 ? substring(1).split(":").first : "?";

  /// Whether this looks like a valid Matrix user ID, e.g. `@user:example.com`.
  bool get isValidUserId => RegExp(r"^@[^:\s]+:[^\s]+$").hasMatch(this);

  String? get serverName {
    final index = indexOf(":");
    return index == -1 ? null : substring(index + 1);
  }
}
