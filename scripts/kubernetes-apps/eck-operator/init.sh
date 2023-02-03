#!/bin/bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")}
export readonly VERSION=${2:-$(basename "$PWD")}

mkdir -p images/shim
cat <<EOF >"images/shim/${NAME}-images.txt"
docker.elastic.co/eck/eck-operator:${VERSION#v}
docker.elastic.co/elasticsearch/elasticsearch:8.3.1
docker.elastic.co/beats/filebeat:8.3.1
docker.elastic.co/kibana/kibana:8.3.1
EOF
