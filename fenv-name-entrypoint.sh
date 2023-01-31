#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
. "$SCRIPT_DIR/sops.lib.sh"

# Decrypt '__sops__*' files and prepare statement to remove the decrypted file on exit
if [[ ! -z "$(sops.find-files)" ]]; then
    sops.bulk-decrypt
    trap sops.bulk-rm-decrypted EXIT
fi

for DIR in */; do
    cd "$DIR"
    echo "=== $(basename $DIR) ===" >>/tmp/fenv.txt
    /scripts/fenv-name.sh | tee -a /tmp/fenv.txt
    echo >>/tmp/fenv.txt
    cd ..
done
