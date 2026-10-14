extension DistributorName on String {
  String get distributorName => startsWith("nexus.federated.nexus")
      ? "Google Play Services"
      : split(".").last;
}
