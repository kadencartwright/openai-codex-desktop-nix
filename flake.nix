{
  description = "Nix package for the OpenAI Codex desktop app on Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowInsecurePredicate = pkg: nixpkgs.lib.getName pkg == "electron";
        };
      };
      package = pkgs.callPackage ./default.nix { };
    in
    {
      packages.${system} = {
        default = package;
        openai-codex-desktop = package;
      };

      apps.${system} = {
        default = {
          type = "app";
          program = "${package}/bin/codex-desktop";
        };

        openai-codex-desktop = self.apps.${system}.default;
      };

      overlays.default = final: prev: {
        openai-codex-desktop = final.callPackage ./default.nix { };
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
