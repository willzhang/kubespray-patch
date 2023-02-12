#!/usr/bin/env bash
set -e

export nic1={{ nic1 }}
export nic2={{ nic2 }}
export nic3={{ nic3 }}
export nic4={{ nic4 }}
export node_name=node195

nics=($nic1 $nic2 $nic3 $nic4)
for i in "${!nics[@]}"; do
  #get nic values from sriovnetworknodestates.yaml
  nic=${nics[$i]}
  export pciAddress=$(yq -o json '.status.interfaces | map(select(.name == env(nic)) | .pciAddress)' sriovnetworknodestates.yaml | jq .[])
  export deviceID=$(yq -o json '.status.interfaces | map(select(.name == env(nic)) | .deviceID)' sriovnetworknodestates.yaml | jq .[])
  export vendor=$(yq -o json '.status.interfaces | map(select(.name == env(nic)) | .vendor)' sriovnetworknodestates.yaml | jq .[])

  # replace values to policy.yaml
  let "i=i+1"
  yq e -i ".spec.nicSelector.rootDevices[0] = env(pciAddress)" manifests/policys/policy_${i}.yaml
  yq e -i ".spec.nicSelector.deviceID = env(deviceID)" manifests/policys/policy_${i}.yaml
  yq e -i ".spec.nicSelector.vendor = env(vendor)" manifests/policys/policy_${i}.yaml
done

for nic in $nic1 $nic2
do
  if ip link show $nic >/dev/null 2>&1;then
    ip link set $nic allmulticast on
  fi
done
