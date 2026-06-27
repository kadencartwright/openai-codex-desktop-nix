---
name: update-codex-desktop-package
description: Update and release this repository's OpenAI Codex desktop Nix package. Use when Codex is asked to bump the packaged Codex desktop app version, refresh hashes, handle upstream native dependency changes, validate the Nix build, commit, tag, or publish an updated release for this repo.
---

# Update Codex Desktop Package

## Workflow

1. Confirm the working tree is clean or identify unrelated local changes before editing.
2. Determine the target OpenAI Codex desktop app version. For the latest version, use OpenAI's Sparkle appcast at `https://persistent.oaistatic.com/codex-app-prod/appcast.xml`; do not guess URL patterns.
3. Run the helper from the repo root:

```sh
scripts/update-version.sh <version>
```

Use `scripts/update-version.sh --latest` to read the appcast directly. This updates `default.nix`, refreshes the official zip hash, and runs `nix build .#openai-codex-desktop`.

4. If the build fails on the `better-sqlite3` or `node-pty` version assertions, inspect the extracted app dependency versions from the build log or failed build directory, update `package.json` and `package-lock.json`, then rerun the helper/build. Keep `@electron/rebuild` pinned unless there is a specific incompatibility.
5. Run `nix flake show` after the build passes.
6. Commit the update with a message like `Update Codex desktop to <version>`.
7. Create and push an annotated tag matching the upstream version:

```sh
git tag -a v<version> -m "OpenAI Codex desktop <version>"
git push origin main v<version>
```

## Guardrails

- Package only the desktop Electron app, not the Codex CLI.
- Keep `x86_64-linux` as the supported system unless the package is actually tested elsewhere.
- Keep the README clear that the upstream app is unfree and Electron 39 is permitted because nixpkgs marks it insecure/EOL.
- Do not remove the Linux editor-target patch unless upstream ships equivalent Linux support.
- Do not tag until `nix build .#openai-codex-desktop` succeeds.
