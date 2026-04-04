extension GetLocalpart on String {
  String get localpart => substring(1).split(":").first;
}
