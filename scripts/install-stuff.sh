#!/usr/bin/env bash

# Script to boostrap a cluster! 

# Prerequisites
# - kubectl v1.27.4
# - jq v1.6
# - kubeseal https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#kubeseal

set -o errexit

# just paste whatever can help your teammates to install local tools
brew install jq kubectl kubeseal
