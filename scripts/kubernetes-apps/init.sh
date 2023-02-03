#!/usr/bin/env bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1

while read name version
do
  bash ${name}/init.sh $name ${version}
  [ ! -z "$(ls -A ${name}/images/shim 2>/dev/null)" ] && cat ${name}/images/shim/*-images.txt >> ./kubernetes_apps-images.txt
  [ ! -z "$(ls -A ${name}/files/shim 2>/dev/null)" ] && cat ${name}/files/shim/*-files.txt >> ./kubernetes_apps-files.txt
done < versions.txt
