# Kubernetes infrastructure with ArgoCD 🐙☸️

Include multi-tenancy, local setup, bootstrap script and more.

![Argo dashboard](./docs/pics/argo-in-local.png)

## Getting started 🚀

```sh
# start local cluster (https://kind.sigs.k8s.io/)
kind create cluster --wait 5m --config=./scripts/kind/kind-config.yaml

# bootstrap argocd on the cluster
./scripts/bootstrap.sh --cluster=local
# follow the instructions to get the argocd password and the URL
```

## Commands 💻

```sh
./scripts/bootstrap.sh --help

./scripts/lint-helm.sh
./scripts/lint-helm-stagged.sh
```

## Inspirations

Cool github repos that helped to find a nice structure:

- https://github.com/fluxcd/flux2-multi-tenancy
- https://github.com/kostis-codefresh/gitops-environment-promotion
- https://github.com/argoproj-labs/argocd-autopilot

Of course, adapt the structure to your organization... #ConwaysLaw
