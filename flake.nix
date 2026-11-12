{
  description = "Nexus Flutter Flake";

  inputs = {
    self.submodules = true;
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix2flatpak = {
      url = "github:neobrain/nix2flatpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # TEMPORARY: the e2e tests against Continuwuity from the forge, till there's a new full release in nixpkgs
    continuwuity = {
      url = "git+https://forgejo.ellis.link/Continuwuation/Continuwuity?ref=ea3beb628a3cab6fbc4142b725c9edb043846eb6";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      flake-parts,
      nixpkgs,
      self,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./linux/nix ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };
}
