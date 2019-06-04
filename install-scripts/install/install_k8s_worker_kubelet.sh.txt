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
BIN_NAME=kubelet

### 1.Check if the install directory exists.
if [ ! -d $K8S_INSTALL_PATH ]; then
     mkdir -p $K8S_INSTALL_PATH
     
fi

### 2.Install the kube-kubelet binary.
mkdir -p $K8S_INSTALL_PATH/bin >>/dev/null
if [ ! -f "$SOFTWARE/kubernetes-server-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE
fi
cd $SOFTWARE && tar -xzf kubernetes-server-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$BIN_NAME $K8S_INSTALL_PATH/bin
ln -sf  $K8S_INSTALL_PATH/bin/* /usr/local/bin
chown -R k8s:k8s $K8S_INSTALL_PATH
chmod -R 755 $K8S_INSTALL_PATH


### 3.Configure the kubele config settings.
# configure default system config
mkdir -p $CONF_PATH >>/dev/null
cat >$CONF_PATH/kubelet.config.json<<"EOF"
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
  "address": "10.0.0.22",
  "port": 10250,
  "readOnlyPort": 0,
  "cgroupDriver": "cgroupfs",
  "hairpinMode": "promiscuous-bridge",
  "serializeImagePulls": false,
  "featureGates": {
    "RotateKubeletClientCertificate": true,
    "RotateKubeletServerCertificate": true
  },
  "clusterDomain": "cluster.local.",
  "clusterDNS": ["10.254.0.2"]
}
EOF

### 4.Install kube-kubele service.
cat >/usr/lib/systemd/system/kubelet.service<<"EOF"
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/data/apps/k8s/kubernetes
ExecStart=/data/apps/k8s/kubernetes/bin/kubelet \
  --bootstrap-kubeconfig=/etc/k8s/kubeconfig/kubelet-bootstrap.kubeconfig \
  --cert-dir=/etc/k8s/ssl \
  --kubeconfig=/etc/k8s/kubernetes/kubelet.kubeconfig \
  --config=/etc/k8s/kubernetes/kubelet.config.json \
  --hostname-override=kubelet-node1 \
  --pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest \
  --allow-privileged=true \
  --alsologtostderr=true \
  --logtostderr=false \
  --log-dir=/data/apps/k8s/kubernetes/logs/kube-kubelet \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF