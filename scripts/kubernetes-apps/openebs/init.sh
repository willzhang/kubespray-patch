#!/usr/bin/env bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")}
export readonly VERSION=${2:-$(basename "$PWD")}

VERSION=${VERSION#v}
wget -q https://github.com/openebs/charts/releases/download/openebs-${VERSION}/openebs-${VERSION}.tgz

utils_tag=$(helm show values openebs-${VERSION}.tgz --jsonpath {.helper.imageTag})
localprovisioner_tag=$(helm show values openebs-${VERSION}.tgz --jsonpath {.localprovisioner.imageTag})

mkdir -p images/shim
cat  <<EOF> images/shim/openebs-images.txt
docker.io/openebs/linux-utils:$utils_tag
docker.io/openebs/provisioner-localpv:${localprovisioner_tag}
EOF
mkdir -p  files/shim
echo "https://github.com/openebs/charts/releases/download/openebs-${VERSION}/openebs-${VERSION}.tgz" > files/shim/openebs-files.txt
