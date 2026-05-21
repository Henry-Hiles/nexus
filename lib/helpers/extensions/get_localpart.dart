extension GetLocalpart on String {
  String get localpart => length > 1 ? substring(1).split(":").first : "?";
}
