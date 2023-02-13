#!/usr/bin/env bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1

echo "Installing podman"
if ! command -v podman &> /dev/null
then
  tar -zxvf files/podman/podman-linux-amd64.tar.gz
  cp -r podman-linux-amd64/usr podman-linux-amd64/etc /
  rm -rf podman-linux-amd64
  cp files/podman/catatonit.x86_64 /usr/local/bin/catatonit
  chmod +x /usr/local/bin/catatonit
fi

echo "Loading image, please wait..."
for image in $(cat files/images/images.list)
do
  image_tar_name=$(echo  ${image##*/} | sed 's#:#_#g')
  if ! podman image exists $image;then
    podman load -i files/images/${image_tar_name}
  fi
done

echo "Running container, please wait..."
if ! podman play kube kubespray.yaml
then
  echo "###############################"
  echo "please clean and run again:"
  echo "  podman kube down kubespray.yaml"
  echo "  podman volume prune -f"
  echo "##############################"
fi
