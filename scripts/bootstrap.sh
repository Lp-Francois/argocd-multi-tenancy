#!/usr/bin/env bash

# Script to boostrap a Kubernetes cluster with ArgoCD all the useful stuff! 🚀

# Prerequisites
# - kubectl v1.27.4
# - jq v1.6
# - kubeseal https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#kubeseal

set -o errexit

if ! command -v jq &> /dev/null
then
    echo "jq cli could not be found."
    exit 1
fi

DEBUG=false
CLUSTER=""
# skip the confirmation prompt
FORCE=false

display_help() {
  echo "Usage: ./scripts/bootstrap.sh [--debug|--force] --cluster=<cluster-name>"
  echo ""
  echo "  --cluster=<name>  Specify cluster name. (with kubecontex or check options in /clusters folder) [required]"
  echo "  --folder=<name>   Specify different cluster folder name than the cluster name. Useful when the cluster name is different"
  echo "                    than the folder name (example: cluster is prod, but the real name on AWS is a UUID). [optional]"
  echo "  --debug           Enable debug mode. (more verbose) [optional]"
  echo "  --force           Skip the confirmation prompt. [optional]"
  echo ""
  echo "Examples:"
  echo "  # Start local cluster"
  echo "  ./scripts/bootstrap.sh --cluster=local"
  echo "  "
  echo "  # Start development cluster with a name different from the cluster folder"
  echo "  ./scripts/bootstrap.sh --cluster=arn:aws:eks:eu-central-2:xxxxxxxxxx:cluster/myawesome-uuid --folder=development"
  echo ""
}

# Loop through the arguments
for arg in "$@"; do
  case $arg in
    --debug*)
      DEBUG=true
      ;;
    --cluster=*)
      CLUSTER="${arg#*=}"
      ;;
    --folder=*)
      CLUSTER_FOLDER="${arg#*=}"
      ;;
    --help)
      display_help
      exit 0
      ;;
    --force)
      FORCE=true
      ;;
    *)
      echo -e "\nInvalid argument: $arg\n"
      display_help
      exit 1
      ;;
  esac
done

# check if FOLDER is not an empty string or undefined, if it is, set FOLDER to take the CLUSTER value
if [ -z "$CLUSTER_FOLDER" ]; then
  echo "› CLUSTER_FOLDER variable is undefined. Setting it to $CLUSTER"
  CLUSTER_FOLDER=$CLUSTER
fi

# Check if DEBUG is enabled
if [ "$DEBUG" = true ]; then
  echo "Debug mode is enabled."
  set -x
fi

if [ -z "$CLUSTER" ]; then
  echo "› CLUSTER variable is undefined. Please set it to the cluster you want to bootstrap. You can find the list in the /clusters folder."
  exit 1
fi

echo -e "\n› Bootstraping: cluster $CLUSTER"
echo -e "     using config folder:          bootstrap/clusters/$CLUSTER_FOLDER"
echo -e "     to the current k8s context:   $(kubectl config current-context)"

if [ "$FORCE" = false ]; then
  echo -e "\nDo you want to continue? [y/N]"

  read -r answer

  if [ "$answer" != "y" ]; then
    echo "Aborting bootstrap."
    echo "See you👋"
    exit 1
  fi
fi

cat << EOF

    «In a perfect world, it should "just work" ✨ 
    so go get a coffee and come back when everything is ready :)
    But of course, expect it to fail and to manually debug 💚»

EOF

##########################################################################################
# Secrets & Configs
##########################################################################################
## => here you could add some logic to restore secrets if they exist (from your favourite 
## password manager)

## Example of simple workflow to restore a Sealed Secret PK from 1password
# echo -e '\n› Restore Kubernetes secret for sealed-secret 🔑\n'
# echo -e "please login to 1password..."
# op document get "$SEALED_SECRET_1P_NAME" | kubectl apply -f -

##########################################################################################
# ArgoCD
##########################################################################################
echo -e '\n› Installing ArgoCD & components 🚀\n'

echo -e '› Apply argocd manifests'
kubectl apply -k bootstrap/clusters/$CLUSTER_FOLDER/argo-cd

## If your repo is private, you might want to restore the git credentials at this step
## to give ArgoCD access to your repo

# echo -e '\n› Restore Git Repository secret 🔑\n'

# kubectl create secret generic creds-12345 \
#   --namespace=argocd \
#   --from-literal=password=$(op read "op://folder/random-uuid/password") \
#   --from-literal=git=https://github.com/organization \
#   --from-literal=url=https://github.com/organization \
#   --from-literal=username=not-needed \
#   -o json --dry-run=client |
#   jq '.metadata.labels |= {"argocd.argoproj.io/secret-type":"repo-creds", "managed-by":"argocd.argoproj.io"}' |
#   kubectl apply -f-

echo -e '\n› Waiting for argo-server to be ready'
kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=120s
kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-application-controller --timeout=120s
kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-repo-server --timeout=120s

# here consider this login temporary, please delete the secret and setup a prod-secure solution
echo -e '\n› Retrieve argocd secret to login:\n'
echo -e "username: admin"
echo -e "password: $(kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" -n argocd | base64 -d)\n";

echo -e "> To login, run the following in a new shell: \n"
echo -e "       kubectl port-forward -n argocd svc/argocd-server 8081:80"
# only works on mac eheh 
echo -e "       open http://localhost:8081"

echo -e '\n› Waiting for crds to be ready'
kubectl wait --namespace argocd --for condition=established --timeout=60s crd/applications.argoproj.io
kubectl wait --namespace argocd --for condition=established --timeout=60s crd/applicationsets.argoproj.io
kubectl wait --namespace argocd --for condition=established --timeout=60s crd/appprojects.argoproj.io

##########################################################################################
# Kubernetes components
##########################################################################################
echo -e '\n› Apply argocd custom resources (Apps & AppSets)'
kubectl apply -f bootstrap/clusters/$CLUSTER_FOLDER/argo-cd.yaml
kubectl apply -f bootstrap/clusters/$CLUSTER_FOLDER/root.yaml

echo -e '\n› Done!'
