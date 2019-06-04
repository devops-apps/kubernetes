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
VERSION=v1.14.2
DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/kubernetes/${VERSION}/kubernetes-server-linux-amd64.tar.gz
BIN_NAME=kube-scheduler


### 1.Check if the install directory exists.
if [ ! -d $K8S_INSTALL_PATH ]; then
     mkdir -p $K8S_INSTALL_PATH
     
fi

### 2.Install kube-apiserver binary of kubernetes.
mkdir -p $K8S_INSTALL_PATH/bin >>/dev/null
if [ ! -f "$SOFTWARE/kubernetes-server-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE
fi
cd $SOFTWARE && tar -xzf kubernetes-server-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$BIN_NAME $K8S_INSTALL_PATH/bin
ln -sf  $K8S_INSTALL_PATH/bin/* /usr/local/bin
chown -R k8s:k8s $K8S_INSTALL_PATH
chmod -R 755 $K8S_INSTALL_PATH

### 3.Install the kube-scheduler service.
cat >/usr/lib/systemd/system/kube-scheduler.service<<"EOF"
[Unit]
Description=Kubernetes kube-scheduler Service
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service

[Service]
User=k8s
ExecStart=/data/apps/k8s/kubernetes/bin/kube-scheduler \
  --address=127.0.0.1 \
  --kubeconfig=/etc/k8s/kubeconfig/kube-scheduler.kubeconfig \
  --leader-elect=true \
  --alsologtostderr=true \
  --logtostderr=false \
  --log-dir=/data/apps/k8s/kubernetes/logs/kube-scheduler \
  --v=2

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
