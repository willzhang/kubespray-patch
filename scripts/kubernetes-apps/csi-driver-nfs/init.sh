#!/usr/bin/env bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")}
export readonly VERSION=${2:-$(basename "$PWD")}

wget -q https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts/${VERSION}/csi-driver-nfs-${VERSION}.tgz

mkdir -p images/shim
helm template csi-driver-nfs-${VERSION}.tgz | grep image: | awk -F" " '{print $2}' | tr -d '"' | sort -u > images/shim/${NAME}-images.txt

mkdir -p  files/shim
echo "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts/${VERSION}/csi-driver-nfs-${VERSION}.tgz" > files/shim/${NAME}-files.txt
