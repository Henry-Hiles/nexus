import "package:matrix/matrix.dart";

extension GetHeaders on Client {
  Map<String, String> get headers => {"authorization": "Bearer $accessToken"};
}
