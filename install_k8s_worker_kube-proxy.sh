#!/bin/bash
#
# Descripts: This is a install script about the k8s cluster !
# Copyright (C) 2001-2018 SIA
#
# INFO:
# touch: It is by Kevin li
# Date:  2016-08-17
# Email: bighank@163.com
# QQ:    2658757934
# blog:  https://blog.51cto.com/blief
######################################################################


#################### Variable parameter setting ######################
KUBE_NAME=kube-proxy
K8S_INSTALL_PATH=/data/apps/k8s/kubernetes
K8S_BIN_PATH=${K8S_INSTALL_PATH}/sbin
K8S_LOG_DIR=${K8S_INSTALL_PATH}/logs
K8S_CONF_PATH=/etc/k8s/kubernetes
KUBE_CONFIG_PATH=/etc/k8s/kubeconfig
CA_DIR=/etc/k8s/ssl
SOFTWARE=/root/software
HOSTNAME=`hostname`
VERSION=v1.12.0
DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/kubernetes/kubernetes-server-${VERSION}-linux-amd64.tar.gz
ETH_INTERFACE=eth1
LISTEN_IP=$(ifconfig | grep -A 1 ${ETH_INTERFACE} |grep inet |awk '{print $2}')
CLUSTER_PODS_CIDR=172.16.0.0/20


[ `id -u` -ne 0 ] && echo "The user no permission exec the scripts, Please use root is exec it..." && exit 0
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
     chmod 755 $K8S_CONF_PATH
fi

if [ ! -d "$KUBE_CONFIG_PATH" ]; then
     mkdir -p $KUBE_CONFIG_PATH
     chmod 755 $KUBE_CONFIG_PATH
fi

### 2.Install kube-proxy binary of kubernetes.
if [ ! -f "$SOFTWARE/kubernetes-server-${VERSION}-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE >>/tmp/install.log  2>&1
fi
cd $SOFTWARE && tar -xzf kubernetes-server-${VERSION}-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$KUBE_NAME $K8S_BIN_PATH
ln -sf  $K8S_BIN_PATH/${KUBE_NAME} /usr/local/bin
chmod -R 755 $K8S_INSTALL_PATH

### 3.Config the kube-proxy conf.
cat >${K8S_CONF_PATH}/kube-proxy-config.yaml<<EOF
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  burst: 200
  kubeconfig: "${KUBE_CONFIG_PATH}/kube-proxy.kubeconfig"
  qps: 100
bindAddress: ${LISTEN_IP}
healthzBindAddress: ${LISTEN_IP}:10256
metricsBindAddress: ${LISTEN_IP}:10249
clusterCIDR: ${CLUSTER_PODS_CIDR}
hostnameOverride: ${HOSTNAME}
mode: "ipvs"
EOF

### 4.Install the kube-proxy service.
cat >/usr/lib/systemd/system/${KUBE_NAME}.service <<EOF
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
WorkingDirectory=${K8S_INSTALL_PATH}
ExecStart=${K8S_BIN_PATH}/${KUBE_NAME} \\
  --config=${K8S_CONF_PATH}/kube-proxy-config.yaml \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=${K8S_LOG_DIR}/${KUBE_NAME} \\
  --v=2

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
