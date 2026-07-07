import "dart:io";

Future<String> getXCodeSDK() async {
  final result = await Process.run("xcrun", ["--show-sdk-path"]);

  if (result.exitCode != 0) {
    throw Exception("Failed to get XCode SDK\n${result.stderr}");
  }

  return result.stdout.trim();
}
