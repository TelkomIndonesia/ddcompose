#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
. "$SCRIPT_DIR/env.lib.sh"
. "$SCRIPT_DIR/sops.lib.sh"

# Decrypt '__sops__.*' files
if [[ ! -z "$(sops.find-files)" ]]; then
    sops.bulk-decrypt
    trap sops.bulk-rm-decrypted EXIT
fi

# load env from .env and generate from md5 of files/folders
COMPOSE_ADD_ENV_FILES="${COMPOSE_ADD_ENV_FILES:-"$PWD/.secret.env"}"
for FILE in $COMPOSE_ADD_ENV_FILES; do
    env.dotenv "$FILE"
done
env.fenv

# execute script
export PATH="$SCRIPT_DIR:$PATH"
"$@"
