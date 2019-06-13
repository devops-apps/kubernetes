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
K8S_KUBECONFIG_PATH=/etc/k8s/kubeconfig
CA_DIR=/etc/k8s/ssl
KUBE_APISERVER=dev-kube-api.mo9.com


[ `id -u` -ne 0 ] && echo "The user no permission exec the scripts, Please use root is exec it..." && exit 0

##############################  Kubeconfig install of kubernetes  ######################################
#1.Check if directory exists .
if [ ! -d "$K8S_CONF_PATH" ]; then
     mkdir -p $K8S_KUBECONFIG_PATH
	 chmod 755 $K8S_KUBECONFIG_PATH
fi

#2.Install the  kubeconfig for kube-controller-manager
kubectl config set-cluster kubernetes \
  --certificate-authority=${CA_DIR}/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=${K8S_KUBECONFIG_PATH}/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=${CA_DIR}/kube-controller-manager.pem \
  --client-key=${CA_DIR}/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=${K8S_KUBECONFIG_PATH}/kube-controller-manager.kubeconfig

kubectl config set-context system:kube-controller-manager \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=${K8S_KUBECONFIG_PATH}/kube-controller-manager.kubeconfig

kubectl config use-context system:kube-controller-manager --kubeconfig=${K8S_KUBECONFIG_PATH}/kube-controller-manager.kubeconfig

#3.Install the  kubeconfig for kube-scheduler
kubectl config set-cluster kubernetes \
  --certificate-authority=${CA_DIR}/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=${K8S_KUBECONFIG_PATH}/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=${CA_DIR}/kube-scheduler.pem \
  --client-key=${CA_DIR}/kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=${K8S_KUBECONFIG_PATH}/kube-scheduler.kubeconfig

kubectl config set-context system:kube-scheduler \
  --cluster=kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=${K8S_KUBECONFIG_PATH}/kube-scheduler.kubeconfig

kubectl config use-context system:kube-scheduler --kubeconfig=${K8S_KUBECONFIG_PATH}/kube-scheduler.kubeconfig


############################## sync encryption-config files for kubernetes apiserver ######################################
#master
sudo ansible master_k8s_vgs -m  synchronize -a "src=${K8S_KUBECONFIG_PATH}/  dest=${K8S_KUBECONFIG_PATH}/ mode=push delete=yes rsync_opts=-avz" -b
sudo ansible master_k8s_vgs -m shell -a "chmod 666 ${K8S_KUBECONFIG_PATH}/*" -b
sudo ansible master_k8s_vgs -m shell -a "rm -rf ${K8S_KUBECONFIG_PATH}/{kubelet*,kube-proxy*}" -b

#worker
sudo ansible worker_k8s_vgs -m  synchronize -a "src=${K8S_KUBECONFIG_PATH}/  dest=${K8S_KUBECONFIG_PATH}/ mode=push delete=yes rsync_opts=-avz" -b
sudo ansible worker_k8s_vgs -m shell -a "chmod 666 ${K8S_KUBECONFIG_PATH}/*" -b
sudo ansible worker_k8s_vgs -m shell -a "rm -rf ${K8S_KUBECONFIG_PATH}/{kube-controller*,kube-scheduler*}" -b
