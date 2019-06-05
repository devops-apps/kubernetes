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
# blog:  http://home.51cto.com/space?uid=6170059
######################################################################


#################### Variable parameter setting ######################
K8S_INSTALL_PATH=/data/apps/k8s/kubernetes
CA_PATH=/etc/k8s/kubernetes
SOFTWARE=/root/software
VERSION=v1.14.2
DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/kubernetes/${VERSION}/kubernetes-server-linux-amd64.tar.gz
BIN_NAME=kubectl
KUBE_APISERVER=https://dev-kube-api.mo9.com


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


### 3.create kube-config for kubectl
kubectl config set-cluster kubernetes \
  --certificate-authority=$CA_PATH/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER}
# set clinet auth parameters
kubectl config set-credentials admin \
  --client-certificate=$CA_PATH/admin.pem \
  --embed-certs=true \
  --client-key=/etc/kubernetes/ssl/admin-key.pem
# set up  and down context of parameters
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin
# set up  and doen context of default parameters
kubectl config use-context kubernetes