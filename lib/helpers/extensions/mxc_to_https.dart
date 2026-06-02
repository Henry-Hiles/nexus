extension MxcToHttps on Uri {
  Uri mxcToHttps(String homeserver) =>
      .parse(homeserver).resolve("_matrix/client/v1/media/download/$host$path");
}
