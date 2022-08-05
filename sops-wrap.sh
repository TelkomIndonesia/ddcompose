#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
. "$SCRIPT_DIR/sops.lib.sh"

sops.bulk-decrypt
"$@"
sops.bulk-encrypt
INCLUDE_PATTERN="${ADDITIONAL_ENCRYPTION_INCLUDE_PATTERN:-""}" \
    sops.bulk-encrypt-add
