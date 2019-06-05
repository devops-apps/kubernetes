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
BIN_NAME=kube-proxy

### 1.Check if the install directory exists.
if [ ! -d $K8S_INSTALL_PATH ]; then
     mkdir -p $K8S_INSTALL_PATH
     
fi

### 2.Install the kube-proxy binary.
mkdir -p $K8S_INSTALL_PATH/bin >>/dev/null
if [ ! -f "$SOFTWARE/kubernetes-server-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE
fi
cd $SOFTWARE && tar -xzf kubernetes-server-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$BIN_NAME $K8S_INSTALL_PATH/bin
ln -sf  $K8S_INSTALL_PATH/bin/* /usr/local/bin
chown -R k8s:k8s $K8S_INSTALL_PATH
chmod -R 755 $K8S_INSTALL_PATH


### 3.Config the kube-proxy conf.
mkdir -p >$CONF_PATH >>/dev/null
cat >$CONF_PATH/kube-proxy.config.yaml<<"EOF"
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 10.0.0.22
clientConnection:
  kubeconfig: /etc/k8s/kubernetes/kube-proxy.kubeconfig
clusterCIDR: 10.10.0.0/16
healthzBindAddress: 10.0.0.22:10256
hostnameOverride: kube-node2
kind: KubeProxyConfiguration
metricsBindAddress: 10.0.0.22:10249
mode: "ipvs"
EOF


### 4.Install the kube-proxy service.
cat >/usr/lib/systemd/system/kube-proxy.service <<"EOF"
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
WorkingDirectory=/var/lib/kube-proxy
ExecStart=/opt/k8s/bin/kube-proxy \
  --config=/etc/k8s/kubernetes/kube-proxy.config.yaml \
  --alsologtostderr=true \
  --logtostderr=false \
  --log-dir=/data/apps/k8s/kubernetes/logs/kube-proxy \
  --v=2
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
