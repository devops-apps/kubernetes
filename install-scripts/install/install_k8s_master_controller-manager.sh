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
# blog:  https://blog.51cto.com/blief
######################################################################


#################### Variable parameter setting ######################
KUBE_NAME=kube-controller-manager
K8S_INSTALL_PATH=/data/apps/k8s/kubernetes
K8S_BIN_PATH=${K8S_INSTALL_PATH}/sbin
K8S_LOG_DIR=${K8S_INSTALL_PATH}/logs
K8S_CONF_PATH=/etc/k8s/kubernetes
CA_DIR=/etc/k8s/ssl
SOFTWARE=/root/software
VERSION=v1.14.2
DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/kubernetes/kubernetes-server-${VERSION}-linux-amd64.tar.gz
USER=k8s
CLUSTER_RANG_SUBNET=10.254.0.0/22


### 1.Check if the install directory exists.
if [ ! -d "$K8S_INSTALL_PATH" ]; then
     mkdir -p $K8S_INSTALL_PATH
     mkdir -p $K8S_BIN_PATH
else
     if [ ! -d "$K8S_BIN_PATH" ]; then
          mkdir -p $K8S_BIN_PATH
     fi
fi

if [ ! -d "$K8S_LOG_DIR" ]; then
     mkdir -p $K8S_LOG_DIR
     mkdir -p $K8S_LOG_DIR/$KUBE_NAME
else
     if [ ! -d "$K8S_LOG_DIR/$KUBE_NAME" ]; then
          mkdir -p $K8S_LOG_DIR/$KUBE_NAME
     fi
fi

if [ ! -d "$K8S_CONF_PATH" ]; then
     mkdir -p $K8S_CONF_PATH
fi

### 2.Install kube-controller-manager binary of kubernetes.
if [ ! -f "$SOFTWARE/kubernetes-server-${VERSION}-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE >>/tmp/install.log  2>&1
fi
cd $SOFTWARE && tar -xzf kubernetes-server-${VERSION}-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$KUBE_NAME $K8S_BIN_PATH
ln -sf  $K8S_BIN_PATH/* /usr/local/bin
chown -R $USER:$USER $K8S_INSTALL_PATH
chmod -R 755 $K8S_INSTALL_PATH

### 3.Install the kube-controller-manager service.
cat >/usr/lib/systemd/system/kube-controller-manager.service<<"EOF"
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
User=${USER}
ExecStart=${K8S_BIN_PATH}/${KUBE_NAME} \\
  --port=0 \\
  --secure-port=10252 \\
  --bind-address=127.0.0.1 \\
  --kubeconfig=${K8S_CONF_PATH}/${KUBE_NAME}.kubeconfig \\
  --service-cluster-ip-range=${CLUSTER_RANG_SUBNET} \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=${CA_DIR}/ca.pem \\
  --cluster-signing-key-file=${CA_DIR}/ca-key.pem \\
  --root-ca-file=${CA_DIR}/ca.pem \\
  --service-account-private-key-file=${CA_DIR}/ca-key.pem \\
  --leader-elect=true \\
  --feature-gates=RotateKubeletServerCertificate=true \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --horizontal-pod-autoscaler-use-rest-clients=true \\
  --horizontal-pod-autoscaler-sync-period=10s \\
  --tls-cert-file=${CA_DIR}/kube-controller-manager.pem \\
  --tls-private-key-file=${CA_DIR}/kube-controller-manager-key.pem \\
  --use-service-account-credentials=true \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=${K8S_LOG_DIR}/${KUBE_NAME} \\
  --flex-volume-plugin-dir=${K8S_INSTALL_PATH}/libexec/kubernetes \\
  --v=2

Restart=on
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
