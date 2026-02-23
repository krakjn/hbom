#!/usr/bin/env bash

set -eu

# Check pipefail support in a subshell, ignore if unsupported
# shellcheck disable=SC3040
(set -o pipefail 2> /dev/null) && set -o pipefail

help() {
  cat <<'EOF'
Install hbom (Hardware Bill of Materials) from GitHub releases

  https://github.com/krakjn/hbom

Linux x86_64 and i386 only.

USAGE:
    install.sh [options]

FLAGS:
    -h, --help      Display this message
    -f, --force     Force overwriting an existing binary

OPTIONS:
    --tag TAG       Tag (version) to install, defaults to latest release
    --to LOCATION   Where to install the binary [default: ~/bin]
EOF
}

url=https://github.com/krakjn/hbom
releases=$url/releases

say() {
  echo "install: $*" >&2
}

err() {
  if [ -n "${td-}" ]; then
    rm -rf "$td"
  fi

  say "error: $*"
  exit 1
}

need() {
  if ! command -v "$1" > /dev/null 2>&1; then
    err "need $1 (command not found)"
  fi
}

download() {
  dl_url="$1"
  output="$2"

  args=()
  if [ -n "${GITHUB_TOKEN+x}" ]; then
    args+=(--header "Authorization: Bearer $GITHUB_TOKEN")
  fi

  if command -v curl > /dev/null; then
    curl --proto =https --tlsv1.2 -sSfL ${args[@]+"${args[@]}"} "$dl_url" -o"$output"
  else
    wget --https-only --secure-protocol=TLSv1_2 --quiet ${args[@]+"${args[@]}"} "$dl_url" -O"$output"
  fi
}

force=false
while test $# -gt 0; do
  case $1 in
    --force | -f)
      force=true
      ;;
    --help | -h)
      help
      exit 0
      ;;
    --tag)
      tag=$2
      shift
      ;;
    --to)
      dest=$2
      shift
      ;;
    *)
      say "error: unrecognized argument '$1'. Usage:"
      help
      exit 1
      ;;
  esac
  shift
done

command -v curl > /dev/null 2>&1 ||
  command -v wget > /dev/null 2>&1 ||
  err "need wget or curl (command not found)"

need mkdir
need mktemp

if [ -z "${tag-}" ]; then
  need grep
  need cut
fi

if [ -z "${dest-}" ]; then
  dest="$HOME/bin"
fi

# Linux only
kernel=$(uname -s)
case $kernel in
  Linux) ;;
  *)
    err "Linux only (detected: $kernel)"
    ;;
esac

# x86_64 or i386/i686 only
arch=$(uname -m)
case $arch in
  x86_64) asset=hbom-x86_64-linux-musl ;;
  i386 | i686) asset=hbom-i386-linux-musl ;;
  *)
    err "unsupported architecture: $arch (supported: x86_64, i386)"
    ;;
esac

if [ -z "${tag-}" ]; then
  tag=$(
    download https://api.github.com/repos/krakjn/hbom/releases/latest - |
    grep tag_name |
    cut -d'"' -f4
  )
fi

binary_url="$releases/download/$tag/$asset"

say "Repository:  $url"
say "Tag:         $tag"
say "Asset:       $asset"
say "Destination: $dest"

td=$(mktemp -d || mktemp -d -t tmp)

if [ -e "$dest/hbom" ] && [ "$force" = false ]; then
  err "\`$dest/hbom\` already exists (use -f to overwrite)"
else
  download "$binary_url" "$td/hbom"
  mkdir -p "$dest"
  cp "$td/hbom" "$dest/hbom"
  chmod 755 "$dest/hbom"
  say "Installed \`$dest/hbom\`"
fi

rm -rf "$td"
