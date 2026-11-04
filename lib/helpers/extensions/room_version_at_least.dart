extension RoomVersionAtLeast on String? {
  /// Whether this room version is [version] or newer. Unknown ones, like
  /// unstable versions, are assumed to be new enough.
  bool versionAtLeast(int version) => switch (int.tryParse(this ?? "")) {
    final number? => number >= version,
    null => true,
  };
}
