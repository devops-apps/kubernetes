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
K8S_INSTALL_PATH=/usr/locall/bin
CA_PATH=/etc/k8s/ssl
K8S_KUBECONFIG_PATH=/etc/k8s/kubeconfig
SOFTWARE=/root/software
VERSION=v1.14.2
DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/kubernetes/kubernetes-server-${VERSION}-linux-amd64.tar.gz
BIN_NAME=kubectl
KUBE_APISERVER_URL=https://dev-kube-api.mo9.com


[ `id -u` -ne 0 ] && echo "The user no permission exec the scripts, Please use root is exec it..." && exit 0
### 1.Install the kubectl binary.
if [ ! -f "$SOFTWARE/kubernetes-server-${VERSION}-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE
fi
cd $SOFTWARE && tar -xzf kubernetes-server-${VERSION}-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$BIN_NAME $K8S_INSTALL_PATH

# 3.Install the  kubeconfig for kubectl
kubectl config set-cluster kubernetes \
  --certificate-authority=${CA_DIR}/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER_URL} \
  --kubeconfig=${K8S_KUBECONFIG_PATH}/kubectl.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=${CA_DIR}/admin.pem \
  --client-key=${CA_DIR}/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=${K8S_KUBECONFIG_PATH}/kubectl.kubeconfig

kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin \
  --kubeconfig=${K8S_KUBECONFIG_PATH}/kubectl.kubeconfig

kubectl config use-context kubernetes --kubeconfig=${K8S_KUBECONFIG_PATH}/kubectl.kubeconfig
