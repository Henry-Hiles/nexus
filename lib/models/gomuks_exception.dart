class GomuksException implements Exception {
  final String message;
  const GomuksException(this.message);

  /// The Matrix error code, if gomuks returned an error in the form `M_CODE (HTTP 404): message`
  String? get errorCode =>
      RegExp(r"^(M_[A-Z_]+)").firstMatch(message)?.group(1);

  @override
  String toString() => message;
}
