extension EventIdIsFake on String {
  bool get isFake => startsWith("~") || startsWith("\$gomuks");
}
