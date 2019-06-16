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
KUBE_NAME=kubelet
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
USER=k8s
CLUSTER_DNS_DOMAIN=mo9.com
CLUSTER_DNS_IP=10.254.0.2
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

if [ ! -d "$KUBE_INSTALL_PATH/${KUBE_NAME}" ]; then
     mkdir -p $KUBE_INSTALL_PATH/${KUBE_NAME}
     chmod 755 $KUBE_INSTALL_PATH/${KUBE_NAME}
fi

### 2.Install kubelet binary of kubernetes.
if [ ! -f "$SOFTWARE/kubernetes-server-${VERSION}-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE >>/tmp/install.log  2>&1
fi
cd $SOFTWARE && tar -xzf kubernetes-server-${VERSION}-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$KUBE_NAME $K8S_BIN_PATH
ln -sf  $K8S_BIN_PATH/${KUBE_NAME} /usr/local/bin
chown -R $USER:$USER $K8S_INSTALL_PATH
chmod -R 755 $K8S_INSTALL_PATH


### 3.Configure the kubele config settings.
# configure default system config
cat >${K8S_CONF_PATH}/kubelet-config.json<<EOF
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "authentication": {
    "x509": {
      "clientCAFile": "/etc/k8s/ssl/ca.pem"
    },
    "webhook": {
      "enabled": true,
      "cacheTTL": "2m0s"
    },
    "anonymous": {
      "enabled": false
    }
  },
  "authorization": {
    "mode": "Webhook",
    "webhook": {
      "cacheAuthorizedTTL": "5m0s",
      "cacheUnauthorizedTTL": "30s"
    }
  },
  "address": "${LISTEN_IP}",
  "port": 10250,
  "readOnlyPort": 0,
  "cgroupDriver": "cgroupfs",
  "hairpinMode": "promiscuous-bridge",
  "serializeImagePulls": false,
  "featureGates": {
    "RotateKubeletClientCertificate": true,
    "RotateKubeletServerCertificate": true
  },
  "clusterDomain": "${CLUSTER_DNS_DOMAIN}.",
  "clusterDNS": ["${CLUSTER_DNS_IP}"],
  "podcidr": "${CLUSTER_PODS_CIDR}",
  "maxPods": "220",
  "docker-root": "/data/apps/k8s/docker/data",
  "fail-swap-on": "false",
  "volume-plugin-dir": "${K8S_INSTALL_PATH}/${KUBE_NAME}/plugins"
}
EOF

### 4.Install kube-kubele service.
cat >/usr/lib/systemd/system/${KUBE_NAME}.service<<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service] 
WorkingDirectory=${K8S_INSTALL_PATH}
ExecStart=${K8S_BIN_PATH}/${KUBE_NAME} \\
  --allow-privileged=true \\
  --bootstrap-kubeconfig=${KUBE_CONFIG_PATH}/kubelet-bootstrap.kubeconfig \\
  --kubeconfig=${KUBE_CONFIG_PATH}/kubelet.kubeconfig \\
  --config=${K8S_CONF_PATH}/kubelet-config.json \\
  --cert-dir=${CA_DIR} \\
  --hostname-override=${HOSTNAME} \\
  --pod-infra-container-image=registry.cn-beijing.aliyuncs.com/k8s_images/pause-amd64:3.1 \\
  --event-qps=0 \\
  --kube-api-qps=1000 \\
  --kube-api-burst=2000 \\
  --registry-qps=0 \\
  --image-pull-progress-deadline=30m \\
  --root-dir=${K8S_INSTALL_PATH}/${KUBE_NAME} \\
  --volume-plugin-dir=${K8S_INSTALL_PATH}/${KUBE_NAME}/plugins \\
  --log-dir=${K8S_LOG_DIR}/${KUBE_NAME} \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --v=2

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
