#!/usr/bin/env bash

set -eu -o pipefail

if [ "$#" -ne 1 ]; then
    >&2 echo "Error: Missing version parameter"
    >&2 echo
    >&2 echo "Usage: $0 tcc-version"
    >&2 echo
    >&2 echo "Example:"
    >&2 echo "$0 1.0.14"

    exit 1
fi

TUXEDO_VERSION="$1"
TUXEDO_SRC_URL="https://raw.githubusercontent.com/tuxedocomputers/tuxedo-control-center/v${TUXEDO_VERSION}"

WORKDIR=$(mktemp -d)
trap 'rm -r "$WORKDIR"' EXIT

for f in package.json package-lock.json; do
    wget "$TUXEDO_SRC_URL/$f" -O "$WORKDIR/$f"
done

# fixme: that fucking cached stuff is broken now...
nix run "github:svanderburg/node2nix#node2nix" -- \
 --development \
 --nodejs-14 \
 --input "$WORKDIR/package.json" \
 --lock "$WORKDIR/package-lock.json" \
 --output node-packages.nix \
 --composition node-composition.nix
