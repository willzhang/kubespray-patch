#!/usr/bin/env bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1

while read name version
do
  bash ${name}/init.sh $name ${version}
done < versions.txt

find ./ -name "*-images.txt" | xargs cat | sort -u > ./kubernetes_apps-images.list
find ./ -name "*-files.txt" | xargs cat | sort -u > ./kubernetes_apps-files.list
