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
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)


[ `id -u` -ne 0 ] && echo "The user no permission exec the scripts, Please use root is exec it..." && exit 0

##############################  Token install of kubernetes  ######################################
#1.Check if directory exists .
if [ ! -d "$K8S_CONF_PATH" ]; then
     mkdir -p $K8S_CONF_PATH
fi

#2.Install the cfssl tools

cat > ${K8S_CONF_PATH}/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF


############################## sync encryption-config files for kubernetes apiserver ######################################
#master
ansible master_k8s_vgs -m  copy -a "src=${K8S_CONF_PATH}/encryption-config.yaml  dest=${K8S_CONF_PATH}/encryption-config.yaml" -b



