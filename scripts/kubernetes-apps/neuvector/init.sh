#!/usr/bin/env bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")}
export readonly VERSION=${2:-$(basename "$PWD")}

VERSION=${VERSION#v}
wget -q https://github.com/neuvector/neuvector-helm/archive/refs/tags/${VERSION}.tar.gz
tar -zxf ${VERSION}.tar.gz

mkdir -p images/shim
helm template neuvector-helm-${VERSION}/charts/core |grep image: | awk -F "[\"\"]" '{print $2}' > images/shim/neuvector-images.txt
mkdir -p files/shim
echo "https://github.com/neuvector/neuvector-helm/archive/refs/tags/${VERSION}.tar.gz" > files/shim/neuvector-files.txt
