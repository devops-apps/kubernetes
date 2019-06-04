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
DOWNLOAD_URL=https://github.com/devops-apps/download/blob/master/kubernetes/v1.14.2/kubernetes-server-linux-amd64.tar.gz
VERSION=v1.12.0
BIN_NAME=kube-controller-manager


### 1.Check if the install directory exists.
if [ ! -d $K8S_INSTALL_PATH ]; then
     mkdir -p $K8S_INSTALL_PATH
     
fi

### 2.Install kube-controller-manager binary of kubernetes.
mkdir -p $K8S_INSTALL_PATH/bin >>/dev/null
if [ ! -f "$SOFTWARE/kubernetes-server-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE
fi
cd $SOFTWARE && tar -xzf kubernetes-server-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$BIN_NAME $K8S_INSTALL_PATH/bin
ln -sf  $K8S_INSTALL_PATH/bin/* /usr/local/bin
chown -R k8s:k8s $K8S_INSTALL_PATH
chmod -R 755 $K8S_INSTALL_PATH

### 3.Install the kube-controller-manager service.
cat >/usr/lib/systemd/system/kube-controller-manager.service<<"EOF"
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
User=k8s
ExecStart=/data/apps/k8s/kubernetes/bin/kube-controller-manager \
  --port=0 \
  --secure-port=10252 \
  --bind-address=127.0.0.1 \
  --kubeconfig=/etc/k8s/kubeconfig/kube-controller-manager.kubeconfig \
  --service-cluster-ip-range=10.254.0.0/16 \
  --cluster-name=kubernetes \
  --cluster-signing-cert-file=/etc/k8s/ssl/ca.pem \
  --cluster-signing-key-file=/etc/k8s/ssl/ca-key.pem \
  --root-ca-file=/etc/k8s/ssl/ca.pem \
  --service-account-private-key-file=/etc/k8s/ssl/ca-key.pem \
  --leader-elect=true \
  --feature-gates=RotateKubeletServerCertificate=true \
  --controllers=*,bootstrapsigner,tokencleaner \
  --horizontal-pod-autoscaler-use-rest-clients=true \
  --horizontal-pod-autoscaler-sync-period=10s \
  --tls-cert-file=/etc/k8s/ssl/kube-controller-manager.pem \
  --tls-private-key-file=/etc/k8s/ssl/kube-controller-manager-key.pem \
  --use-service-account-credentials=true \
  --alsologtostderr=true \
  --logtostderr=false \
  --log-dir=/data/apps/k8s/kubernetes/logs/kube-controller-manager \
  --flex-volume-plugin-dir=/data/apps/k8s/kubernetes/libexec/kubernetes \
  --v=2

Restart=on
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
