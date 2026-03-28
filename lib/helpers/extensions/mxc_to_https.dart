extension MxcToHttps on Uri {
  Uri mxcToHttps(String homeserver) => Uri.parse(
    homeserver,
  ).resolve("_matrix/client/v1/media/download/$host$path");
}
