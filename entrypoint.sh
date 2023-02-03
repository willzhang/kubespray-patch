#!/usr/bin/env bash
set -e

registry_type=${REGISTRY_TYPE:-"registry"}
registry_url=${REGISTRY_URL:-"http://kubespray-registry:5000"}
registry_username=${REGISTRY_USERNAME:-"admin"}
registry_password=${REGISTRY_PASSWORD:-"Registry12345"}

minio_url=${MINIO_URL:-"http://kubespray-minio:9000"}
minio_root_user=${MINIO_ROOT_USER:-"minio"}
minio_root_password=${MINIO_ROOT_PASSWORD:-"minio123"}

registry_protocal=$(echo ${registry_url} | awk -F: '{print $1}')
registry_host=$(echo ${registry_url} | awk -F// '{print $2}')

package=/kubespray/packages
package_cache=/kubespray/packages_cache
images_list=${package_cache}/images.list
harbor_projects=${package_cache}/harbor_projects.list

function log_info() {
    echo -e "\033[36m$1 \033[0m"
}

if [ "${registry_protocal}" == "http" ];then
  tls_verify=false
elif [ "${registry_protocal}" == "https" ];then
  tls_verify=true
else
  echo "can not verify registry protocal is http or https!"
  exit 1
fi

[ ! -d /etc/containers/certs.d/${registry_host} ] && certs="empty"
if [ "${tls_verify}" == "true" ] && [ "${certs}" == "empty" ];then
  log_info "registry is https but certs file /etc/containers/certs.d/${registry_host} not found!"
  exit 1
fi

while ! skopeo login $registry_host -u ${registry_username} -p ${registry_password} --tls-verify=${tls_verify}
do
    echo waiting for registry ready...
    sleep 10
done

while ! mc config host add minio ${minio_url} ${minio_root_user} ${minio_root_password}
do
    echo waiting for minio ready...
    sleep 10
done

for bucket in debs files
do
  if ! mc ls minio/${bucket} >/dev/null 2>&1;then
    echo "minio bucket not found creating ..."
    mc mb minio/${bucket}
    mc anonymous set public minio/${bucket}
  fi
done

mkdir -p $package $package_cache
if [ -z "$(ls -A ${package_cache})" ]; then
   tar -zxvf ${package}/kubespray-offline_*.tar.gz -C ${package_cache}
else
   echo "package_cache not empty, skip untar!"
fi

if [ "$registry_type" == "harbor" ];then
  for project in $(cat ${harbor_projects})
  do
    echo "creating harbor project: $project"
    curl -u "${registry_username}:${registry_password}" -X POST -H "Content-Type: application/json" "${registry_url}/api/v2.0/projects" \
    -d "{ \"project_name\": \"${project}\", \"public\": true}" -k
  done
fi

icount=0
count=$(cat $images_list | wc -l)
for image in $(cat $images_list)
do
  let icount+=1
  if echo $image|grep -E "registry.k8s.io/kube|registry.k8s.io/pause"; then registry_host_kube=kubernetes/;else registry_host_kube="";fi
  log_info "[$icount/$count]copying image: $image -> ${registry_host}/${registry_host_kube}${image#*/}"
  skopeo copy --insecure-policy oci:${package_cache}/images:${image} \
  --src-shared-blob-dir ${package_cache}/images docker://${registry_host}/${registry_host_kube}${image#*/} \
  --dest-tls-verify=${tls_verify} --dest-username ${registry_username} --dest-password ${registry_password}
done

if [ -z "$(mc ls minio/debs)" ] || [ -z "$(mc ls minio/files)" ]
then
  mc cp --recursive $package_cache/public/* minio/debs
  mc cp --recursive $package_cache/files/* minio/files
else
  echo "bucket debs or files not empty, skip copy file."
fi

log_info "#######################"
log_info "init success and sleep!"
log_info "#######################"
sleep infinity
