#!/usr/bin/env bash
# use helm find app version from chart version
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly NAME=${1:-$(basename "$PWD")}
export readonly VERSION=${2:-$(basename "$PWD")}

VERSION=${VERSION#v}
image_list=images/shim/${NAME}-images.txt
file_list=files/shim/${NAME}-files.txt
rm -rf images/shim/ files/shim/ charts
mkdir -p images/shim/ files/shim/ charts

repo_url="https://prometheus-community.github.io/helm-charts"
repo_name="prometheus-community/kube-prometheus-stack"
chart_name="prometheus-community"

helm repo add --force-update ${chart_name} ${repo_url}
helm pull ${repo_name} --version=${VERSION} -d charts --untar

helm template charts/${NAME} --version=${VERSION} | grep image: | awk -F" " '{print $2}' | tr -d '"' |sort -u > ${image_list}
sed -i '/^bats/ s/./docker.io\/&/' images/shim/${NAME}-images.txt
sed -i '/^grafana/ s/./docker.io\/&/' images/shim/${NAME}-images.txt

app_version=$(helm search repo --versions --regexp "\v"${repo_name}"\v" | grep ${VERSION} | awk '{print $3}')
echo "quay.io/prometheus-operator/prometheus-config-reloader:${app_version}" >> ${image_list}

kube_state_metrics_tag=$(helm show values charts/kube-prometheus-stack/charts/kube-state-metrics --jsonpath {.image.tag})
echo "registry.k8s.io/kube-state-metrics/kube-state-metrics:${kube_state_metrics_tag}" >> ${image_list}

echo "https://github.com/prometheus-community/helm-charts/releases/download/kube-prometheus-stack-${VERSION}/kube-prometheus-stack-${VERSION}.tgz" > ${file_list}
