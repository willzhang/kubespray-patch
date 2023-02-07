#!/bin/bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")}
export readonly VERSION=${2:-$(basename "$PWD")}

wget -q https://raw.githubusercontent.com/projectcalico/calico/${VERSION}/manifests/tigera-operator.yaml
mkdir -p images/shim
cat tigera-operator.yaml |grep quay.io | awk -F" " '{print $2}' > images/shim/${NAME}-images.txt
echo "docker.io/calico/csi:${VERSION}" >> images/shim/${NAME}-images.txt
echo "docker.io/calico/node-driver-registrar:${VERSION}" >> images/shim/${NAME}-images.txt

mkdir -p files/shim
echo "https://github.com/projectcalico/calico/releases/download/${VERSION}/tigera-operator-${VERSION}.tgz" > files/shim/${NAME}-files.txt
