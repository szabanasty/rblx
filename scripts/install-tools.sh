#!/usr/bin/env bash
# Verified release archives from the official GitHub release pages:
# https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1
# https://github.com/luau-lang/luau/releases/tag/0.741
# https://github.com/JohnnyMorganz/luau-lsp/releases/tag/1.70.1
set -euo pipefail

if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
    echo 'This installer supports Linux x86_64. See README.md for Windows/macOS.' >&2
    exit 1
fi

for tool in curl unzip sha256sum mktemp; do
    command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }
done

tools_dir="${RBLX_TOOLS_DIR:-/workspace/.tools}"
cache_dir="$tools_dir/downloads"
mkdir -p "$cache_dir"
download_tmp=''
trap 'if [[ -n "$download_tmp" ]]; then rm -f -- "$download_tmp"; fi' EXIT

download_verified() {
    local url="$1" archive="$2" checksum="$3"
    if [[ ! -f "$archive" ]]; then
        download_tmp="$(mktemp "$cache_dir/download.XXXXXX")"
        curl --fail --location --silent --show-error --retry 2 \
            --connect-timeout 20 --max-time 180 "$url" --output "$download_tmp"
        printf '%s  %s\n' "$checksum" "$download_tmp" | sha256sum --check --status
        mv -- "$download_tmp" "$archive"
        download_tmp=''
    fi
    if ! printf '%s  %s\n' "$checksum" "$archive" | sha256sum --check --status; then
        echo "Checksum mismatch: $archive. Remove this cached archive and retry." >&2
        exit 1
    fi
}

rojo_archive="$cache_dir/rojo-7.7.1-linux-x86_64.zip"
luau_archive="$cache_dir/luau-0.741-ubuntu.zip"
lsp_archive="$cache_dir/luau-lsp-1.70.1-linux-x86_64.zip"
definitions="$cache_dir/roblox-types-1.70.1.d.luau"
download_verified \
    'https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip' \
    "$rojo_archive" \
    '00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4'
download_verified \
    'https://github.com/luau-lang/luau/releases/download/0.741/luau-ubuntu.zip' \
    "$luau_archive" \
    '134dc762ad26232af83e43f98dec03ff6030dd3a4452f9408b9d50ccea025503'
download_verified \
    'https://github.com/JohnnyMorganz/luau-lsp/releases/download/1.70.1/luau-lsp-linux-x86_64.zip' \
    "$lsp_archive" \
    '1a2ea1ae4f98f8946cefd970a4b54853e11ab4775e6932faa7f60cf920346567'
download_verified \
    'https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.d.luau' \
    "$definitions" \
    '2857efa8245485f8c25c19c018ee1ef9b46afab4efd2ea70fc3257cd3faf7080'

mkdir -p "$tools_dir/rojo/7.7.1" "$tools_dir/luau/0.741"
mkdir -p "$tools_dir/luau-lsp/1.70.1"
unzip -q -o "$rojo_archive" -d "$tools_dir/rojo/7.7.1"
unzip -q -o "$luau_archive" -d "$tools_dir/luau/0.741"
unzip -q -o "$lsp_archive" -d "$tools_dir/luau-lsp/1.70.1"
cp -- "$definitions" "$tools_dir/luau-lsp/1.70.1/globalTypes.d.luau"
chmod +x "$tools_dir/rojo/7.7.1/rojo" \
    "$tools_dir/luau/0.741/luau" \
    "$tools_dir/luau/0.741/luau-analyze" \
    "$tools_dir/luau/0.741/luau-compile"
chmod +x "$tools_dir/luau-lsp/1.70.1/luau-lsp"

"$tools_dir/rojo/7.7.1/rojo" --version
printf 'Installed Luau 0.741 in %s\n' "$tools_dir/luau/0.741"
printf 'Add %s/rojo/7.7.1 and %s/luau/0.741 to PATH.\n' "$tools_dir" "$tools_dir"
