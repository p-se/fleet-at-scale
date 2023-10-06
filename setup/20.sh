#!/bin/bash
#
# Description: setup 20 fleet downstreams
#

set -euo pipefail
set -x

n=${1-20} # number of clusters

BIN_SCRIPTS=$(dirname $0)
MAX_CONCURRENCY=6
BASE_INDEX=0

FLEET_VERSION=0.9.0-rc.4
FLEET_CRDS_CHART_URL="https://github.com/rancher/fleet/releases/download/v${FLEET_VERSION}/fleet-crd-${FLEET_VERSION}.tgz"
FLEET_CHART_URL="https://github.com/rancher/fleet/releases/download/v${FLEET_VERSION}/fleet-${FLEET_VERSION}.tgz"

export EXTRA_K3D_ARGS="${EXTRA_K3D_ARGS:-}" # e.g. "-v /dev/mapper:/dev/mapper" on brtfs filesystems

seq() {
  command seq $(( $BASE_INDEX + $1 )) $(( $BASE_INDEX + $2 ))
}

setup_local_registry() {
  if !k3d registry list k3d-registry >/dev/null 2>&1 ; then
    k3d registry create
  fi
  port=$(docker inspect -f '{{ index .Config.Labels "k3s.registry.port.external"}}' k3d-registry)
  images=$(helm template ${FLEET_CHART_URL} | grep -i -o 'image:.*' | grep "rancher/[^\"']*" -o)
  for image in $images; do
    crane cp ${image} localhost:${port}/${image} || {
      docker tag ${image} localhost:${port}/${image}
      docker push localhost:${port}/${image}
    }
  done
  export DOCKER_MIRROR=http://k3d-registry:${port}
}

setup_upstream() {
  k3d cluster create upstream --servers 1 \
    --no-lb --k3s-arg='--disable=servicelb,metrics-server,traefik@server:*' \
    --api-port 6443 --network fleet --kubeconfig-switch-context
}

install_fleet() {
  helm -n cattle-fleet-system upgrade --install --create-namespace fleet-crd "${FLEET_CRDS_CHART_URL}"
  # host=$( docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' k3d-upstream-server-0 ) 
  host=$( docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' minikube ) 
  ca=$( kubectl config view --flatten -o jsonpath='{.clusters[?(@.name == "minikube")].cluster.certificate-authority-data}' | base64 -d )
  server="https://$host:6443"
  helm -n cattle-fleet-system upgrade --install \
    --set apiServerCA="$ca" \
    --set apiServerURL="$server" \
    `# --set debug=true --set debugLevel=99` \
    fleet "${FLEET_CHART_URL}"

  # Wait for setup to complete
  { grep -E -q -m 1 "fleet-agent-local.*1/1"; kill $!; } < <(kubectl get bundles -n fleet-local -w)
}

create_downstream_clusters() {
    seq 1 $n | xargs -I{} -n1 -P${MAX_CONCURRENCY} ${BIN_SCRIPTS}/20-k3d "perf{}" "{}" fleet
}

label_clusters() {
  for i in $(seq 1 $n); do
    envs=(dev test prod)
    env=${envs[$(($i%3))]}
    kubectl label clusters.fleet.cattle.io -n "fleet-default" "perf$i" env=$env
  done
}

register_clusters() {
  seq 1 $n | xargs -I{} -n1 -P${MAX_CONCURRENCY} ${BIN_SCRIPTS}/20-managed-clusters "perf{}" {}
  label_clusters
}

# Step 0: configure local registry for caching images
setup_local_registry

# Step 1: create local upstream cluster and install fleet on it
setup_upstream
install_fleet

# Step 2: create downstream clusters and register them against the upstream
create_downstream_clusters
kubectl config use-context k3d-upstream
register_clusters

# cleanup() {
#   k3d cluster delete --all
#   seq 1 10 | xargs -I{} -n1 -P6 k3d cluster delete "perf{}"
# }
