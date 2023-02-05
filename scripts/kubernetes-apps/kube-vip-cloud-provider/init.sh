#!/bin/bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")}
export readonly VERSION=${2:-$(basename "$PWD")}

mkdir -p images/shim
wget -q https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/${VERSION}/manifest/kube-vip-cloud-controller.yaml
cat kube-vip-cloud-controller.yaml | grep image: | awk -F" " '{print $2}' >"images/shim/${NAME}-images.txt"
