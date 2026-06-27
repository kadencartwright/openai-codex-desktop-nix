#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: scripts/update-version.sh <codex-desktop-version>

Updates default.nix for a new OpenAI Codex desktop app version, refreshes the
official bundle hash, and runs nix build .#openai-codex-desktop.
EOF
}

if [[ $# -ne 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 2
fi

version="$1"
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
default_nix="${repo_root}/default.nix"
url="https://persistent.oaistatic.com/codex-app-prod/Codex-darwin-arm64-${version}.zip"

if [[ ! -f "${default_nix}" ]]; then
  echo "Could not find default.nix at ${default_nix}" >&2
  exit 1
fi

echo "Prefetching ${url}" >&2
prefetch_json="$(nix store prefetch-file --json "${url}")"
zip_hash="$(printf '%s\n' "${prefetch_json}" | sed -n 's/.*"hash":"\([^"]*\)".*/\1/p')"

if [[ -z "${zip_hash}" ]]; then
  echo "Could not parse hash from nix store prefetch-file output:" >&2
  printf '%s\n' "${prefetch_json}" >&2
  exit 1
fi

tmp="$(mktemp)"
awk -v new_version="${version}" -v new_hash="${zip_hash}" '
  /codexZip = fetchurl \{/ {
    in_codex_zip = 1
  }

  /^  version = "[^"]+";/ {
    sub(/"[^"]+"/, "\"" new_version "\"")
  }

  in_codex_zip && /^    hash = "sha256-[^"]+";/ {
    print "    hash = \"" new_hash "\";"
    in_codex_zip = 0
    next
  }

  { print }
' "${default_nix}" >"${tmp}"
mv "${tmp}" "${default_nix}"

echo "Updated default.nix to ${version} (${zip_hash})" >&2
echo "Building .#openai-codex-desktop" >&2
(
  cd "${repo_root}"
  nix build .#openai-codex-desktop
)
