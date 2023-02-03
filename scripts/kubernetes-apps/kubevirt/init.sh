#!/bin/bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")}
export readonly VERSION=${2:-$(basename "$PWD")}

rm -rf images/shim/ files/shim
export CDI_TAG=$(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest)
export CDI_VERSION=$(echo ${CDI_TAG##*/})

mkdir -p images/shim
cat <<EOF >"images/shim/kubevirt-images.txt"
quay.io/kubevirt/virt-api:${VERSION}
quay.io/kubevirt/virt-controller:${VERSION}
quay.io/kubevirt/virt-handler:${VERSION}
quay.io/kubevirt/virt-launcher:${VERSION}
quay.io/kubevirt/virt-operator:${VERSION}
quay.io/kubevirt/cdi-operator:${CDI_VERSION}
quay.io/kubevirt/cdi-apiserver:${CDI_VERSION}
quay.io/kubevirt/cdi-controller:${CDI_VERSION}
quay.io/kubevirt/cdi-uploadproxy:${CDI_VERSION}
quay.io/kubevirt/cdi-importer:${CDI_VERSION}
quay.io/kubevirt/cdi-cloner:${CDI_VERSION}
quay.io/kubevirt/cdi-uploadserver:${CDI_VERSION}
EOF

mkdir -p files/shim/
echo "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-amd64" > files/shim/kubevirt-files.txt
