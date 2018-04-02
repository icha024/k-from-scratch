```bash

sudo apt-get update
sudo apt-get -y install \
    etcd \
    unzip \
    tree \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
touch /tmp/added-docker-repo

sudo apt-get -y install docker-ce
usermod -a -G docker ubuntu
touch /tmp/installed-docker

# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md

wget -q --show-progress --https-only --timestamping \
  https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz \
  https://github.com/containerd/cri-containerd/releases/download/v1.0.0-beta.1/cri-containerd-1.0.0-beta.1.linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubelet

sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes

sudo tar -xvf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin/
sudo tar -xvf cri-containerd-1.0.0-beta.1.linux-amd64.tar.gz -C /
chmod +x kubectl kube-proxy kubelet
sudo mv kubectl kube-proxy kubelet /usr/local/bin/

# cat > kubelet.service <<EOF
# [Unit]
# Description=Kubernetes Kubelet
# Documentation=https://github.com/kubernetes/kubernetes
# After=cri-containerd.service
# Requires=cri-containerd.service

# [Service]
# ExecStart=/usr/local/bin/kubelet \\
#   --allow-privileged=true \\
#   --anonymous-auth=false \\
#   --authorization-mode=Webhook \\
#   --client-ca-file=/var/lib/kubernetes/ca.pem \\
#   --cloud-provider= \\
#   --cluster-dns=10.32.0.10 \\
#   --cluster-domain=cluster.local \\
#   --container-runtime=remote \\
#   --container-runtime-endpoint=unix:///var/run/cri-containerd.sock \\
#   --image-pull-progress-deadline=2m \\
#   --kubeconfig=/var/lib/kubelet/kubeconfig \\
#   --network-plugin=cni \\
#   --pod-cidr=${POD_CIDR} \\
#   --register-node=true \\
#   --runtime-request-timeout=15m \\
#   --tls-cert-file=/var/lib/kubelet/${HOSTNAME}.pem \\
#   --tls-private-key-file=/var/lib/kubelet/${HOSTNAME}-key.pem \\
#   --v=2
# Restart=on-failure
# RestartSec=5

# [Install]
# WantedBy=multi-user.target
# EOF

cat > kubelet.service <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=cri-containerd.service
Requires=cri-containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --allow-privileged=true \\
  --anonymous-auth=false \\
  --cloud-provider= \\
  --cluster-dns=8.8.8.8 \\
  --cluster-domain=cluster.local \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/cri-containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --pod-cidr=172.31.0.0/16 \\
  --register-node=true \\
  --runtime-request-timeout=15m \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# cat > kube-proxy.service <<EOF
# [Unit]
# Description=Kubernetes Kube Proxy
# Documentation=https://github.com/kubernetes/kubernetes

# [Service]
# ExecStart=/usr/local/bin/kube-proxy \\
#   --cluster-cidr=10.200.0.0/16 \\
#   --kubeconfig=/var/lib/kube-proxy/kubeconfig \\
#   --proxy-mode=iptables \\
#   --v=2
# Restart=on-failure
# RestartSec=5

# [Install]
# WantedBy=multi-user.target
# EOF

cat > kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --cluster-cidr=172.31.0.0/16 \\
  --kubeconfig=/var/lib/kube-proxy/kubeconfig \\
  --proxy-mode=iptables \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


sudo mv kubelet.service kube-proxy.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable containerd cri-containerd kubelet kube-proxy
sudo systemctl start containerd cri-containerd kubelet kube-proxy


# configs
#   kubectl config set-cluster kubernetes-the-hard-way \
#     --certificate-authority=ca.pem \
#     --embed-certs=true \
#     --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
#     --kubeconfig=${instance}.kubeconfig

#   kubectl config set-credentials system:node:${instance} \
#     --client-certificate=${instance}.pem \
#     --client-key=${instance}-key.pem \
#     --embed-certs=true \
#     --kubeconfig=${instance}.kubeconfig

#   kubectl config set-context default \
#     --cluster=kubernetes-the-hard-way \
#     --user=system:node:${instance} \
#     --kubeconfig=${instance}.kubeconfig

  kubectl config set-cluster kubernetes-the-hard-way \
    --server=http://172.31.12.29:6443 \
    --kubeconfig=worker.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:worker \
    --kubeconfig=worker.kubeconfig

# kubectl config set-cluster kubernetes-the-hard-way \
#   --certificate-authority=ca.pem \
#   --embed-certs=true \
#   --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
#   --kubeconfig=kube-proxy.kubeconfig
# kubectl config set-credentials kube-proxy \
#   --client-certificate=kube-proxy.pem \
#   --client-key=kube-proxy-key.pem \
#   --embed-certs=true \
#   --kubeconfig=kube-proxy.kubeconfig
# kubectl config set-context default \
#   --cluster=kubernetes-the-hard-way \
#   --user=kube-proxy \
#   --kubeconfig=kube-proxy.kubeconfig

kubectl config set-cluster kubernetes-the-hard-way \
  --server=http://172.31.12.29:6443 \
  --kubeconfig=kube-proxy.kubeconfig
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

# ------------
kubectl config set-cluster kubernetes-the-hard-way \
  --server=http://172.31.12.29:6443
  --user=admin
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way

kubectl config set-context default \
  --server=http://172.31.12.29:6443 \
  --user=admin


```