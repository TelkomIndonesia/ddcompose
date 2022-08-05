#!/bin/bash

FILE_PREFIX=${FILE_PREFIX:-"__sops__"}
DIR=${DIR:-"."}

# list files with prefix $FILE_PREFIX
function sops.find-files {
    not_path=${EXCLUDE_PATTERN:-""}
    name=${INCLUDE_PATTERN:-""}
    if [ -z "$name" ]; then
        name="${FILE_PREFIX}*"
    fi

    find $DIR -type f -name "${name}" -not -path "${not_path}" "$@"
}

# guess sops supported type based on the file extension
function sops._guess-type {
    filename=$(basename -- "${1:-""}")
    if [ -z "$filename" ]; then
        return
    fi

    extension="${filename##*.}"
    if [ "$extension" == "tfstate" ]; then
        echo "json"
    fi
}

# wrapper of sops command
function sops._sops {
    INPUT_TYPE=${INPUT_TYPE:-""}
    OUTPUT_TYPE=${OUTPUT_TYPE:-""}

    if [ ! -z "${INPUT_TYPE}" ]; then
        sops --input-type "$INPUT_TYPE" $@
    elif [ ! -z "${OUTPUT_TYPE}" ]; then
        sops --output-type "$OUTPUT_TYPE" $@
    else
        sops "$@"
    fi
}

# bulk encrypt or decrypt based on "$MODE" environment variables
function _bulk-xcrypt {
    MODE=${MODE:-"decrypt"}

    sops.find-files |
        while read f; do
            filename=$(basename $f)
            uf="$(dirname "$f")/${filename#$FILE_PREFIX}"

            if [ "decrypt" == "$MODE" ]; then
                OUTPUT_TYPE="$(sops._guess-type "$uf")" \
                    sops._sops -output "$uf" -decrypt "$f"
            else
                INPUT_TYPE="$(sops._guess-type "$uf")" \
                    sops._sops -output "$f" -encrypt "$uf"
            fi
        done
}

# bulk decrypt files listed by sops.find-files
function sops.bulk-decrypt {
    _bulk-xcrypt
}

# bulk encrypt files listed by sops.find-files
function sops.bulk-encrypt {
    MODE="encrypt" _bulk-xcrypt
}

# bulk encrypt files listed by sops.find-files that is not yet encrypted
function sops.bulk-encrypt-add {
    sops.find-files |
        while read uf; do
            f="$(dirname "$uf")/${FILE_PREFIX}$(basename "$uf")"
            if [ ! -f "$f" ]; then
                continue
            fi

            INPUT_TYPE="$(sops._guess-type "$uf")" \
                sops._sops -output "$f" -encrypt "$uf"
        done
}

function sops.bulk-updatekeys {
    sops.find-files -print0 |
        xargs -0 -I {} sops updatekeys -y {}
}

function sops.default-age-key-file {
    if [ ! -z "${SOPS_AGE_KEY_FILE:-""}" ]; then
        echo "$SOPS_AGE_KEY_FILE"
        return
    fi

    XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "$XDG_CONFIG_HOME/sops/age/keys.txt"

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$HOME/Library/Application Support/sops/age/keys.txt"

    elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo "$XDG_CONFIG_HOME/sops/age/keys.txt"

    elif [[ "$OSTYPE" == "win32" ]]; then
        echo "$LOCALAPPDATA/sops/age/keys.txt"

    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo "$XDG_CONFIG_HOME/sops/age/keys.txt"

    fi
}

function sops.bulk-rm-decrypted {
    sops.find-files |
        while read f; do
            filename=$(basename $f)
            uf="$(dirname "$f")/${filename#$FILE_PREFIX}"
            rm "$uf"
        done
}
