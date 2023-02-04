#!/bin/bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")}
export readonly VERSION=${2:-$(basename "$PWD")}

VERSION=${VERSION#v}
mkdir -p images/shim
wget -qO- https://github.com/elastic/cloud-on-k8s/archive/refs/tags/${VERSION}.tar.gz | tar -xz
components_version=$(helm show values cloud-on-k8s-${VERSION}/deploy/eck-beats --jsonpath {.version})
cat <<EOF> "images/shim/${NAME}-images.txt"
docker.elastic.co/eck/eck-operator:${VERSION}
docker.elastic.co/elasticsearch/elasticsearch:${components_version}
docker.elastic.co/beats/filebeat:${components_version}
docker.elastic.co/kibana/kibana:${components_version}
EOF

mkdir -p files/shim
echo "https://helm.elastic.co/helm/eck-operator/eck-operator-${VERSION}.tgz" > files/shim/${NAME}-files.txt
