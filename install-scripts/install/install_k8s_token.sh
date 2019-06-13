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
K8S_CONF_PATH=/etc/k8s/kubernetes
BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')


[ `id -u` -ne 0 ] && echo "The user no permission exec the scripts, Please use root is exec it..." && exit 0

##############################  Token install of kubernetes  ######################################
#1.Check if directory exists .
if [ ! -d "$K8S_CONF_PATH" ]; then
     mkdir -p $K8S_CONF_PATH
fi

#2.Install the cfssl tools

cat > ${K8S_CONF_PATH}/token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF


############################## sync encryption-config files for kubernetes apiserver ######################################
#master
ansible master_k8s_vgs -m  copy -a "src=${K8S_CONF_PATH}/token.csv  dest=${K8S_CONF_PATH}/" -b



