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
    # TEMPORARY: the e2e tests against Continuwuity from the forge, till the update gets into unstable
    continuwuity = {
      url = "git+https://forgejo.ellis.link/Continuwuation/Continuwuity?ref=v26.11.0-alpha.1";
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
