#!/bin/bash
set -euo pipefail

function cleanup {
    rm -rf terraform.tfstate*
}
trap cleanup EXIT

if [ -f "__sops__terraform.tfstate" ]; then
    sops --output-type "json" -output "terraform.tfstate" -decrypt "__sops__terraform.tfstate"
fi

terraform init
terraform apply --auto-approve

if [ -f ".sops.yaml" ]; then
    sops --input-type "json" -output "__sops__terraform.tfstate" --encrypted-regex "^attributes$" -encrypt "terraform.tfstate"
fi
