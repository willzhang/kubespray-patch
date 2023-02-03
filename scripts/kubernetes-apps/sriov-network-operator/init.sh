#!/usr/bin/env bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")} 
export readonly VERSION=${2:-$(basename "$PWD")}

rm -rf images/shim files/shim
wget -q https://github.com/k8snetworkplumbingwg/sriov-network-operator/releases/download/${VERSION}/sriov-network-operator-${VERSION#v}.tgz
tar -zxf sriov-network-operator-${VERSION#v}.tgz

mkdir -p images/shim
cat sriov-network-operator/values.yaml | grep "ghcr.io/k8snetworkplumbingwg" | awk '{print $2}' |sort -u >> images/shim/${NAME}-images.txt

mkdir -p files/shim
echo "https://github.com/k8snetworkplumbingwg/sriov-network-operator/releases/download/${VERSION}/sriov-network-operator-${VERSION#v}.tgz" > files/shim/sriov-network-operator-files.txt
