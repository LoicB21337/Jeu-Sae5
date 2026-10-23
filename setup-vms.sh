#!/usr/bin/env bash
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")"
source ./config.env

NET_ARGS=()
if [ -n "${NETWORK:-}" ]; then NET_ARGS=(--network "$NETWORK"); fi

echo ">> Création de la VM 'services'"
multipass launch 24.04 --name services --cpus 1 --memory 1G --disk 8G \
  --cloud-init cloud-init/services.yaml

echo ">> Création de la VM 'jeu'"
multipass launch 24.04 --name jeu --cpus 2 --memory 2G --disk 10G \
  ${NET_ARGS[@]+"${NET_ARGS[@]}"} --cloud-init cloud-init/jeu.yaml

echo ">> Attente de la fin de cloud-init (installation des paquets)"
multipass exec services -- cloud-init status --wait
multipass exec jeu -- cloud-init status --wait

echo ">> VMs prêtes :"
multipass list
echo "Étape suivante : ./deploy.sh"
