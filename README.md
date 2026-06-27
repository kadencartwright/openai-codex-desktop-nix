# OpenAI Codex Desktop for Nix

This repository packages the OpenAI Codex desktop app for Linux with Nix.

It is specifically for the desktop Electron app. It is not a package for the
OpenAI Codex CLI, although the desktop app uses a `codex` CLI binary at runtime.

## What it does

- Downloads the official macOS Arm Codex desktop bundle from OpenAI.
- Extracts the Electron app payload and icon.
- Rebuilds native Node modules for Linux and Electron 39.
- Patches the app's "open in editor" targets for Linux editors and file managers.
- Installs a `codex-desktop` launcher and desktop entry.

## Requirements

- Nix with flakes enabled.
- `x86_64-linux`.
- Network access during the first build.
- An OpenAI Codex CLI binary available on `PATH`, or provided by the package
  fallback from nixpkgs.

The upstream Codex desktop app is unfree software and currently requires
Electron 39, which nixpkgs marks as insecure/EOL. This flake imports nixpkgs
with `allowUnfree = true` and permits the Electron dependency so the package can
build without extra user config.

## Try it

```sh
nix run github:kadencartwright/openai-codex-desktop-nix
```

## Install

```sh
nix profile install github:kadencartwright/openai-codex-desktop-nix
codex-desktop
```

## Use in a NixOS or Home Manager flake

Add the input:

```nix
inputs.openai-codex-desktop-nix.url = "github:kadencartwright/openai-codex-desktop-nix";
```

Then add the package to your system or home packages:

```nix
{ inputs, pkgs, ... }:

{
  environment.systemPackages = [
    inputs.openai-codex-desktop-nix.packages.${pkgs.system}.default
  ];
}
```

For Home Manager:

```nix
{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.openai-codex-desktop-nix.packages.${pkgs.system}.default
  ];
}
```

## Editor detection

The package patches Codex's open-target detection for Linux. It currently looks
for these targets:

- VS Code / Code OSS
- VS Code Insiders
- Cursor
- Windsurf
- Zed
- File manager via `xdg-open`

The launcher also reads optional Chromium/Electron flags from:

```text
~/.config/codex-flags.conf
```

Example:

```text
--enable-features=UseOzonePlatform
--ozone-platform=wayland
```

## Updating

When OpenAI publishes a new desktop build, update these fields in `default.nix`:

- `version`
- `codexZip.hash`
- `npmDepsHash`, if `package-lock.json` or native dependencies change

Then run:

```sh
nix flake update
nix build
```

Maintainers can use the helper script for the common case:

```sh
scripts/update-version.sh 26.602.71036
```

Or update to the latest version listed in OpenAI's Sparkle appcast:

```sh
scripts/update-version.sh --latest
```

The repository also has a scheduled GitHub Action that checks the appcast three
times per day and opens an auto-merge PR if a newer version builds
successfully. After the update lands on `main`, another workflow creates a
`v<version>` tag and moves the `latest` tag to the current package version.

There is also a repo-local Codex skill at
`.codex/skills/update-codex-desktop-package` for agents maintaining this
package.

## License

This repository only contains the Nix packaging and Linux patching code. It does
not redistribute the OpenAI Codex desktop app. The upstream app has its own
license terms and is fetched during the Nix build.

`patch-linux-open-targets.mjs` carries its own SPDX header from the original
source. Other packaging files in this repository are provided under the MIT
license.
