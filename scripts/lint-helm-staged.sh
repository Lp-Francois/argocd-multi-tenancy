#!/bin/sh
#
# Run helm lint on any chart that changed
#

set -e
  
# https://github.com/datreeio/CRDs-catalog/tree/main
SCHEMAS_LOCATION='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

kubeconform_config=(
  "-strict"
  "-ignore-missing-schemas"
  "-schema-location" "default"
  "-schema-location" $SCHEMAS_LOCATION
  "-verbose"
  "-summary"
)

for chart in $(git diff --name-only --staged | grep ^charts/ | cut -d "/" -f 1,2 | sort -u)
do
  echo "\n› Lint" $chart
  helm lint $chart
  # helm lint --strict ## Uncomment to make it fail on warnings

  echo '\n› Kube manifest validation for' $chart
  helm template $chart | kubeconform "${kubeconform_config[@]}"
done
