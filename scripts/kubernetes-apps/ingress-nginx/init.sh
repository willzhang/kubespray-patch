#!/usr/bin/env bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")}
export readonly VERSION=${2:-$(basename "$PWD")}

VERSION=${VERSION#v}
wget -q https://github.com/kubernetes/ingress-nginx/releases/download/helm-chart-${VERSION}/ingress-nginx-${VERSION}.tgz

mkdir -p images/shim
helm template ingress-nginx-${VERSION}.tgz \
--set controller.image.digest=null \
--set controller.admissionWebhooks.patch.image.digest=null | grep image: | sort -u  | awk -F" " '{print $2}' | tr -d '"' > images/shim/ingress-nginx-images.txt

mkdir -p  files/shim
echo "https://github.com/kubernetes/ingress-nginx/releases/download/helm-chart-${VERSION}/ingress-nginx-${VERSION}.tgz" > files/shim/ingress-nginx-files.txt
