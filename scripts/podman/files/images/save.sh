#!/usr/bin/env bash
set -e

for image in $(cat images.list)
do
  image_tar_name=$(echo  ${image##*/} | sed 's#:#_#g')
  podman save -o ${image_tar_name}.tar.gz $image
done
