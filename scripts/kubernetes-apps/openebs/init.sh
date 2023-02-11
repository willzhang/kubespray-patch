#!/usr/bin/env bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")}
export readonly VERSION=${2:-$(basename "$PWD")}

VERSION=${VERSION#v}
wget -q https://github.com/openebs/charts/releases/download/openebs-${VERSION}/openebs-${VERSION}.tgz

mkdir -p images/shim
helm template openebs-${VERSION}.tgz -f openebs.values.yaml | grep image: | awk -F" " '{print $2}' | tr -d '"' | sort -u > images/shim/${NAME}-images.txt
utils_tag=$(helm show values openebs-${VERSION}.tgz --jsonpath {.helper.imageTag})
echo "docker.io/openebs/linux-utils:$utils_tag" >> images/shim/${NAME}-images.txt

mkdir -p  files/shim
echo "https://github.com/openebs/charts/releases/download/openebs-${VERSION}/openebs-${VERSION}.tgz" > files/shim/openebs-files.txt
