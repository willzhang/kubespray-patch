ARG KUBESPRAY_VERSION

FROM httpd:2 as builder0
RUN mkdir -p /auth \
    && htpasswd -Bbn admin Registry12345 > /etc/containers/auth/htpasswd

FROM quay.io/kubespray/kubespray:${KUBESPRAY_VERSION}
ARG KUBESPRAY_VERSION \
    KUBERNETES_VERSION \
    PACKAGE_VERSION \
    CALICO_VERSION \
    CALICO_OPERATOR_VERSION

ENV PACKAGES=/kubespray/packages \
    PACKAGES_CACHE=/kubespray/packages_cache

ENV skopeo_bin_version=v1.11.0 \
    TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

RUN apt update -qq \
    && apt install -y tzdata \
    && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && apt install -q -y --no-install-recommends git wget nano vim iproute2 iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# install tools
RUN mkdir -p $PACKAGES \
    && mkdir -p $PACKAGES_CACHE \
    && wget -q --no-check-certificate https://github.com/lework/skopeo-binary/releases/download/${skopeo_bin_version}/skopeo-linux-amd64 \
    && mv skopeo-linux-amd64 /usr/local/bin/skopeo \
    && chmod +x /usr/local/bin/skopeo \
    && wget -q https://dl.min.io/client/mc/release/linux-amd64/mc \
    && mv mc /usr/local/bin/ \
    && chmod +x /usr/local/bin/mc

# generate registry certs
ENV domain=registry.kubespray.com \
    certs_dir=/etc/containers/certs.d
RUN mkdir -p "/etc/containers/certs.d/${domain}:5000" \
    && openssl req -newkey rsa:4096 -nodes -sha256 -keyout /auth/certs/${domain}:5000/${domain}.key \
       -addext "subjectAltName = DNS:${domain}" \
       -x509 -days 365 -out /auth/certs/${domain}:5000/${domain}.crt \
       -subj "/C=CN/ST=Guangdong/L=Shenzhen/O=example/OU=example/CN=example" \
    && openssl x509 -inform PEM -in /auth/certs/${domain}:5000/${domain}.crt -out /auth/certs/${domain}:5000/${domain}.cert

# patch image bug
RUN rm -rf /kubespray/ && cd / \
    && git clone https://github.com/kubernetes-sigs/kubespray.git -b ${KUBESPRAY_VERSION} --depth=1 /kubespray && cd /kubespray \
    && sed -i "8,12s/^/#/" /kubespray/roles/container-engine/cri-o/tasks/cleanup.yaml \
    && pip3 install ruamel.yaml jmespath kubernetes \
    && ansible-galaxy collection install kubernetes.core

# patch kubeadm certificate to 10 years
RUN wget -q https://github.com/lework/kubeadm-certs/releases/download/${KUBERNETES_VERSION}/kubeadm-linux-amd64 \
    && export kubeadm_sha256sum=$(sha256sum kubeadm-linux-amd64 | cut -d " " -f 1) \
    && file_path="./roles/download/defaults/main.yml" \
    && wget -q https://github.com/mikefarah/yq/releases/download/v4.30.8/yq_linux_amd64 \
    && chmod +x ./yq_linux_amd64 \
    && ./yq_linux_amd64 e -i ".kubeadm_checksums.amd64.[env(KUBERNETES_VERSION)] = env(kubeadm_sha256sum)" ${file_path} \
    && rm -rf kubeadm-linux-amd64 yq_linux_amd64

# patch environment
RUN sed -i "s#container_manager: containerd#container_manager: crio#g" /kubespray/inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml \
    && sed -i "s/# calico_bpf_enabled: false/calico_bpf_enabled: true/g" /kubespray/inventory/sample/group_vars/k8s_cluster/k8s-net-calico.yml \
    && sed -i "s#calico_bpf_service_mode: Tunnel#calico_bpf_service_mode: DSR#g" /kubespray/roles/network_plugin/calico/defaults/main.yml \
    && cp inventory/sample/group_vars/all/offline.yml /kubespray/inventory/sample/group_vars/all/mirror.yml \
    && sed -i -E '/# .*\{\{ files_repo/s/^# //g' /kubespray/inventory/sample/group_vars/all/mirror.yml \
    && sed -i -E '/# .*\{\{ registry_host/s/^# //g' /kubespray/inventory/sample/group_vars/all/mirror.yml

# patch image support harbor
RUN sed -i '/^kube_proxy_image_repo:.*/c kube_proxy_image_repo: "{{ kube_image_repo }}/kubernetes/kube-proxy"' /kubespray/roles/download/defaults/main.yml \
    && sed -i '/^pod_infra_image_repo:.*/c pod_infra_image_repo: "{{ kube_image_repo }}/kubernetes/pause"' /kubespray/roles/download/defaults/main.yml \
    && sed -i "/^imageRepository:.*/c imageRepository: {{ kube_image_repo }}/kubernetes" /kubespray/roles/download/templates/kubeadm-images.yaml.j2 \
    && sed -i "/^imageRepository:.*/c imageRepository: {{ kube_image_repo }}/kubernetes" /kubespray/roles/kubernetes/control-plane/templates/kubeadm-config.v1beta3.yaml.j2

# patch extra playbooks
COPY patches/ /kubespray/

# patch calico
RUN wget -q "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml" \
    && sed -ie "s#quay.io/tigera/operator:${CALICO_OPERATOR_VERSION}#{{ calico_operator_image_repo }}:{{ calico_operator_image_tag }}#g" tigera-operator.yaml \
    && mv tigera-operator.yaml /kubespray/roles/network_plugin/calico/templates/tigera-operator.yml.j2

COPY --from=builder0 /auth/htpasswd /auth
COPY kubespray-offline_${KUBERNETES_VERSION}_${PACKAGE_VERSION}.tar.gz ${PACKAGES}/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
