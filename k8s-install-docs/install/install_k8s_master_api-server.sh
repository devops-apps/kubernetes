#!/bin/bash
#
# Descripts: This is a install script about the k8s cluster !
# Copyright (C) 2001-2018 Redis SIA
#
# INFO:
# touch: It is by Kevin li
# Date:  2016-08-17
# Email: bighank@163.com
# QQ:    2658757934
# blog:  http://home.51cto.com/space?uid=6170059
######################################################################


#################### Variable parameter setting ######################
K8S_INSTALL_PATH=/data/apps/k8s/kubernetes
CONF_PATH=/etc/k8s/kubernetes
SOFTWARE=/root/software
DOWNLOAD_URL=https://devops.mo9.com/download
VERSION=v1.12.0
BIN_NAME=kube-apiserver


### 1.Check if the install directory exists.
if [ ! -d $K8S_INSTALL_PATH ]; then
     mkdir -p $K8S_INSTALL_PATH
     
fi

### 2.Install kube-apiserver binary of kubernetes.
mkdir -p $K8S_INSTALL_PATH/bin >>/dev/null
if [ ! -f "$SOFTWARE/kubernetes-server-linux-amd64.tar.gz" ]; then
     wget ${DOWNLOAD}/${VERSION}/kubernetes-server-linux-amd64.tar.gz -P $SOFTWARE
fi
cd $SOFTWARE && tar -xzf kubernetes-server-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$BIN_NAME $K8S_INSTALL_PATH/bin
ln -sf  $K8S_INSTALL_PATH/bin/* /usr/local/bin
chown -R k8s:k8s $K8S_INSTALL_PATH
chmod -R 755 $K8S_INSTALL_PATH

### 3.Install the kube-apiserver service.
cat >/usr/lib/systemd/system/kube-apiserver.service<<"EOF"
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
User=k8s
Type=notify
EnvironmentFile=-/etc/k8s/kubernetes/kube-apiserver
ExecStart=/data/apps/k8s/kubernetes/bin/kube-apiserver \
  --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --bind-address=0.0.0.0 \
  --insecure-bind-address=10.0.0.22 \
  --insecure-port=8080 \
  --secure-port=6443 \
  --advertise-address=10.0.0.22 \
  --authorization-mode=Node,RBAC \
  --anonymous-auth=false \
  --runtime-config=api/all \
  --audit-policy-file=/etc/k8s/kubernetes/audit-policy.yaml \
  --enable-bootstrap-token-auth=true \
  --token-auth-file=/etc/k8s/ssl/token.csv \
  --service-cluster-ip-range=10.254.0.0/16 \
  --service-node-port-range=8400-9000 \
  --tls-cert-file=/etc/k8s/ssl/kubernetes.pem \
  --tls-private-key-file=/etc/k8s/ssl/kubernetes-key.pem \
  --client-ca-file=/etc/k8s/ssl/ca.pem \
  --service-account-key-file=/etc/k8s/ssl/ca-key.pem \
  --etcd-cafile=/etc/k8s/ssl/ca.pem \
  --etcd-certfile=/etc/k8s/ssl/etcd.pem \
  --etcd-keyfile=/etc/k8s/ssl/etcd-key.pem \
  --etcd-servers=https://10.10.10.22:2379,https://10.10.10.23:2379,https://10.10.10.24:2379 \
  --enable-swagger-ui=true \
  --allow-privileged=true \
  --apiserver-count=3 \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/data/apps/k8s/kubernetes/logs/kube-apiserver/audit.log \
  --storage-backend=etcd3 \
  --event-ttl=168h \
  --alsologtostderr=true \
  --logtostderr=false \
  --log-dir=/data/apps/k8s/kubernetes/logs/kube-apiserver \
  --v=2

Restart=on-failure
RestartSec=5
LimitNOFILE=65536
EOF
