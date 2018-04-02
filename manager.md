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

# Get Kube
# curl -LO https://github.com/kubernetes/kubernetes/releases/download/v1.9.6/kubernetes.tar.gz
# tar -zxvf kubernetes.tar.gz

# https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md

wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl"

chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/

# Replace ETCD IP
# Replace CIDR range
# Remove HTTPS and certs
cat > kube-apiserver.service <<EOF
# [Unit]
# Description=Kubernetes API Server
# Documentation=https://github.com/kubernetes/kubernetes

# [Service]
# ExecStart=/usr/local/bin/kube-apiserver \\
#   --admission-control=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
#   --advertise-address=${INTERNAL_IP} \\
#   --allow-privileged=true \\
#   --apiserver-count=3 \\
#   --audit-log-maxage=30 \\
#   --audit-log-maxbackup=3 \\
#   --audit-log-maxsize=100 \\
#   --audit-log-path=/var/log/audit.log \\
#   --authorization-mode=Node,RBAC \\
#   --bind-address=0.0.0.0 \\
#   --client-ca-file=/var/lib/kubernetes/ca.pem \\
#   --enable-swagger-ui=true \\
#   --etcd-cafile=/var/lib/kubernetes/ca.pem \\
#   --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
#   --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
#   --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
#   --event-ttl=1h \\
#   --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
#   --insecure-bind-address=127.0.0.1 \\
#   --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
#   --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
#   --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
#   --kubelet-https=true \\
#   --runtime-config=api/all \\
#   --service-account-key-file=/var/lib/kubernetes/ca-key.pem \\
#   --service-cluster-ip-range=10.32.0.0/24 \\
#   --service-node-port-range=30000-32767 \\
#   --tls-ca-file=/var/lib/kubernetes/ca.pem \\
#   --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
#   --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
#   --v=2
# Restart=on-failure
# RestartSec=5

# [Install]
# WantedBy=multi-user.target

[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \
  --admission-control=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --advertise-address=172.31.12.29 \
  --allow-privileged=true \
  --apiserver-count=3 \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/var/log/audit.log \
  --authorization-mode=Node,RBAC \
  --bind-address=172.31.12.29 \
  --enable-swagger-ui=true \
  --etcd-servers=http://172.31.12.29:2379 \
  --event-ttl=1h \
  --insecure-bind-address=172.31.12.29 \
  --kubelet-https=false \
  --runtime-config=api/all \
  --service-cluster-ip-range=172.31.0.0/16 \
  --service-node-port-range=30000-32767 \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# cat > kube-controller-manager.service <<EOF
# [Unit]
# Description=Kubernetes Controller Manager
# Documentation=https://github.com/kubernetes/kubernetes

# [Service]
# ExecStart=/usr/local/bin/kube-controller-manager \\
#   --address=0.0.0.0 \\
#   --cluster-cidr=172.31.0.0/16 \\
#   --cluster-name=kubernetes \\
#   --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
#   --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
#   --leader-elect=true \\
#   --master=http://127.0.0.1:8080 \\
#   --root-ca-file=/var/lib/kubernetes/ca.pem \\
#   --service-account-private-key-file=/var/lib/kubernetes/ca-key.pem \\
#   --service-cluster-ip-range=10.32.0.0/24 \\
#   --v=2
# Restart=on-failure
# RestartSec=5

# [Install]
# WantedBy=multi-user.target

cat > kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \
  --address=0.0.0.0 \
  --cluster-cidr=172.31.0.0/16 \
  --cluster-name=kubernetes \
  --leader-elect=true \
  --master=http://172.31.12.29:8080 \
  --service-cluster-ip-range=172.31.0.0/16 \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat > kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --leader-elect=true \\
  --master=http://172.31.12.29:8080 \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo mv kube-apiserver.service kube-scheduler.service kube-controller-manager.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler

# edit /etc/default/etcd
echo 'ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"' >> edit /etc/default/etcd
echo 'ETCD_ADVERTISE_CLIENT_URLS="http://172.31.12.29:2379,http://172.31.12.29:4001"' >> edit /etc/default/etcd



```