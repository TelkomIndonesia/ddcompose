#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
. "$SCRIPT_DIR/env.lib.sh"
. "$SCRIPT_DIR/sops.lib.sh"

COMPOSE_ADD_ENV_FILES="${COMPOSE_ADD_ENV_FILES:-".secret.env"}"
COMPOSE_SKIP_RSYNC=${COMPOSE_SKIP_RSYNC:-"false"}

# Decrypt '__sops__*' files and prepare statement to remove the decrypted file on exit so that it is not stored anywhere
if [[ ! -z "$(sops.find-files)" ]]; then
    sops.bulk-decrypt
    trap sops.bulk-rm-decrypted EXIT
fi

# rsync if we are talking to remote docker via ssh
if [[ "${DOCKER_HOST:-""}" == "ssh://"* ]] && [[ "$COMPOSE_SKIP_RSYNC" == "false" ]]; then
    rsync "${PWD}/" "${DOCKER_HOST#"ssh://"}:${PWD}" \
        -av \
        --delete \
        --exclude "__sops__*" \
        $(for FILE in $COMPOSE_ADD_ENV_FILES; do
            echo -n "--exclude $FILE "
        done) \
        $(if [ -f .rsync-exclude ]; then
            echo -n "--exclude .rsync-exclude "
            echo -n "--exclude-from .rsync-exclude "
        fi)

# create docker volume to be used by docker compose locally
elif [[ "${DOCKER_HOST:-""}" != "ssh://"* ]]; then
    volume="ddcompose-$(pwd | sha256sum | cut -d' ' -f1)"
    docker volume create "$volume"
    tar -cvO "." | docker run -i --rm -v "$volume:/dst" alpine tar -xf - -C /dst

    export DDCOMPOSE_MANIFEST_VOLUME="$volume"
    if [ -z "${COMPOSE_FILE:-""}" ]; then
        export COMPOSE_FILE=$(ls -r | grep -E '^docker-compose(\.override)?\.(yml|yaml)$' | xargs | sed -e 's/\s\+/:/g')
    fi
    export COMPOSE_FILE="$COMPOSE_FILE:docker-compose.ddcompose.yml"
    echo -en "volumes:\n  ${volume}:\n    external: true" >"docker-compose.ddcompose.yml"
fi

# load additional env
for FILE in $COMPOSE_ADD_ENV_FILES; do
    env.dotenv "$FILE"
done
env.fenv
export PATH="$SCRIPT_DIR:$PATH"

# execute script
"$@"
