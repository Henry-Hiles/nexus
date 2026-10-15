extension GetLocalpart on String {
  String get localpart => length > 1 ? substring(1).split(":").first : "?";

  String? get serverName {
    final index = indexOf(":");
    return index == -1 ? null : substring(index + 1);
  }
}
