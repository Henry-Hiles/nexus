{
  androidenv,
}:
androidenv.composeAndroidPackages {
  toolsVersion = "26.1.1";
  platformToolsVersion = "36.0.1";
  buildToolsVersions = [
    "35.0.0"
    "36.0.0"
  ];
  cmakeVersions = [ "3.22.1" ];
  platformVersions = [ "36" ];
  abiVersions = [
    "armeabi-v7a"
    "arm64-v8a"
  ];
  includeNDK = true;
  ndkVersions = [ "27.0.12077973" ];

}
