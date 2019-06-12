#!/bin/bash
#
# Descripts: This is a install script about the k8s cluster !
# Copyright (C) 2001-2018  SIA
#
# INFO:
# touch: It is by Kevin li
# Date:  2016-08-17
# Email: bighank@163.com
# QQ:    2658757934
# blog:  https://blog.51cto.com/blief
######################################################################


[ `id -u` -ne 0 ] && echo "The user no permission exec the scripts, Please use root is exec it..." && exit 0

#################### Variable parameter setting ######################
KUBE_NAME=kube-apiserver
K8S_INSTALL_PATH=/data/apps/k8s/kubernetes
K8S_BIN_PATH=${K8S_INSTALL_PATH}/bin
K8S_LOG_DIR=${K8S_INSTALL_PATH}/logs
K8S_CONF_PATH=/etc/k8s/kubernetes
CA_DIR=/etc/k8s/ssl
SOFTWARE=/root/software
VERSION=v1.14.2
DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/kubernetes/kubernetes-server-${VERSION}-linux-amd64.tar.gz
ETC_ENDPOIDS=https://10.10.10.22:2379,https://10.10.10.23:2379,https://10.10.10.24:2379
ETH_INTERFACE=eth1
LISTEN_IP=$(ifconfig | grep -A 1 ${ETH_INTERFACE} |grep inet |awk '{print $2}')
USER=k8s
CLUSTER_RANG_SUBNET=10.254.0.0/22
SERVER_PORT_RANG=8400-9400


### 1.Check if the install directory exists.
if [ ! -d "$K8S_INSTALL_PATH" ]; then
     mkdir -p $K8S_INSTALL_PATH
else
     if [ ! -d "$K8S_BIN_PATH" ]; then
          mkdir -p $K8S_BIN_PATH
     fi
fi

if [ ! -d "$K8S_LOG_DIR" ]; then
     mkdir -p $K8S_LOG_DIR
else
     if [ ! -d "$K8S_LOG_DIR/$KUBE_NAME" ]; then
          mkdir -p $K8S_LOG_DIR/$KUBE_NAME
     fi
fi

if [ ! -d "$K8S_CONF_PATH" ]; then
     mkdir -p $K8S_CONF_PATH
fi

### 2.Install kube-apiserver binary of kubernetes.
if [ ! -f "$SOFTWARE/kubernetes-server-${VERSION}-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE >>/tmp/install.log  2>&1
fi
cd $SOFTWARE && tar -xzf kubernetes-server-${VERSION}-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$KUBE_NAME $K8S_INSTALL_PATH/bin
ln -sf  $K8S_INSTALL_PATH/bin/* /usr/local/bin
chown -R $USER:$USER $K8S_INSTALL_PATH
chmod -R 755 $K8S_INSTALL_PATH

### 3.Install the kube-apiserver service.
cat >/usr/lib/systemd/system/${KUBE_NAME}.service<<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
[Service]
User=${USER}
Type=notify
EnvironmentFile=-${K8S_CONF_PATH}/${KUBE_NAME}
ExecStart=${K8S_BIN_PATH}/${KUBE_NAME} \\
  --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --bind-address=0.0.0.0 \\
  --insecure-bind-address=${LISTEN_IP} \\
  --insecure-port=8080 \\
  --secure-port=6443 \\
  --advertise-address=${LISTEN_IP} \\
  --authorization-mode=Node,RBAC \\
  --anonymous-auth=false \\
  --runtime-config=api/all \\
  --audit-policy-file=${K8S_CONF_PATH}/audit-policy.yaml \\
  --enable-bootstrap-token-auth=true \\
  --token-auth-file=${K8S_CONF_PATH}/token.csv \\
  --service-cluster-ip-range=${CLUSTER_RANG_SUBNET} \\
  --service-node-port-range=${SERVER_PORT_RANG} \\
  --tls-cert-file=${CA_DIR}/kubernetes.pem \\
  --tls-private-key-file=${CA_DIR}/kubernetes-key.pem \\
  --client-ca-file=${CA_DIR}/ca.pem \\
  --service-account-key-file=${CA_DIR}/ca-key.pem \\
  --etcd-cafile=${CA_DIR}/ca.pem \\
  --etcd-certfile=${CA_DIR}/etcd.pem \\
  --etcd-keyfile=${CA_DIR}/etcd-key.pem \\
  --etcd-servers=${ETCD_ENDPOIDS} \\
  --enable-swagger-ui=true \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=${K8S_LOG_DIR}/${KUBE_NAME}/audit.log \\
  --storage-backend=etcd3 \\
  --event-ttl=168h \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=${K8S_LOG_DIR}/${KUBE_NAME} \\
  --v=2
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
EOF