import "package:http/http.dart" as http;

import "fakes.dart";

/// Fake platforms that do the browser's part of OAuth on Continuwuity, logging
/// in as [username], then hand the redirect back to Nexus.
class OAuthFakes(final String username, final String password) {
  final links = FakeAppLinks();
  late final launcher = FakeUrlLauncher(onLaunch);

  Future<void> onLaunch(Uri url) async {
    if (!url.queryParameters.containsKey("code_challenge")) return;

    final redirect = await authorize(url);
    // Nexus listens for the redirect after the launch returns
    await Future.delayed(const .new(milliseconds: 500));
    links.open(redirect);
  }

  /// Logs in on [authorizationUrl], then confirms the grant, returning the URI
  /// Continuwuity redirects back to the app with.
  Future<Uri> authorize(Uri authorizationUrl) async {
    final client = http.Client();
    String? cookie;

    Future<Uri> followRedirect(
      String method,
      Uri url, [
      Map<String, String>? form,
    ]) async {
      final request = http.Request(method, url)
        ..followRedirects = false
        ..headers.addAll({
          // Continuwuity only accepts its forms from top-level navigations
          "Sec-Fetch-Site": "same-origin",
          "Sec-Fetch-Mode": "navigate",
          "Sec-Fetch-Dest": "document",
          "Cookie": ?cookie,
        });
      if (form != null) request.bodyFields = form;

      final response = await http.Response.fromStream(
        await client.send(request),
      );
      if (response.headers["set-cookie"] case final setCookie?) {
        cookie = setCookie.split(";").first;
      }

      return switch ((response.statusCode, response.headers["location"])) {
        (302 || 303 || 307, final location?) => url.resolve(location),
        (final status, _) => throw StateError(
          "Expected $method $url to redirect, got $status: ${response.body}",
        ),
      };
    }

    try {
      final loginUrl = await followRedirect("GET", authorizationUrl);
      final grantUrl = await followRedirect("POST", loginUrl, {
        "identifier": username,
        "password": password,
      });
      return await followRedirect("POST", grantUrl, {"stage": "confirm"});
    } finally {
      client.close();
    }
  }
}
