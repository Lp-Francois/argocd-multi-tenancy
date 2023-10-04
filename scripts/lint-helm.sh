#!/bin/sh
#
# Run helm lint on all charts and kubeconform on all manifests
#

set -e
# set -x

for chart in $(ls -d charts/*/)
do
  echo '\n› Build helm dependencies' $chart
  echo '\n› Lint' $chart
  helm lint $chart
  # helm lint --strict ## Uncomment to make it fail on warnings

  echo '\n› Kube manifest validation for' $chart
  helm template $chart | kubeconform \
    -strict \
    -summary \
    -verbose \
    -ignore-missing-schemas \
    -schema-location default \
    -schema-location \
    'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

# CRD schemas catalog:
# https://github.com/datreeio/CRDs-catalog/tree/main
done
