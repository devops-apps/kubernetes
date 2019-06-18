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
FLANNEL_INSTALL_PATH=/data/apps/k8s/networks/flannel
SOFTWARE=/root/software
VERSION=v0.11.0
DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/network/flannel-${VERSION}-linux-amd64.tar.gz
FLANNEL_ETCD_ENPOINTS=https://10.10.10.22:2379,https://10.10.10.23:2379,https://10.10.10.24:2379
FLANNEL_ETCD_PREFIX=/k8s/network
CA_DIR=/etc/k8s/ssl
IFACE=eth0 


### 1.Check if the install directory exists.
if [ ! -d $FLANNEL_INSTALL_PATH/bin ]; then
     mkdir -p $FLANNEL_INSTALL_PATH/bin     
fi

### 2.Install binary of flannel.
if [ ! -f "$SOFTWARE/flannel-${VERSION}-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE >>/tmp/install.log  2>&1
fi
cd $SOFTWARE && tar -xzf flannel-${VERSION}-linux-amd64.tar.gz -C ./
cp -fp ${SOFTWARE}/{flanneld,mk-docker-opts.sh} ${FLANNEL_INSTALL_PATH}/bin
ln -sf  ${FLANNEL_INSTALL_PATH}/bin/{flanneld,mk-docker-opts.sh}  /usr/local/bin
chmod -R 755 $FLANNEL_INSTALL_PATH

### 3.Install flannel of service .
cat >/usr/lib/systemd/system/flanneld.service<<EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
ExecStart=${FLANNEL_INSTALL_PATH}/bin/flanneld \\
  -etcd-cafile=${CA_DIR}/ca.pem \\
  -etcd-certfile=${CA_DIR}/flannel.pem \\
  -etcd-keyfile=${CA_DIR}/flannel-key.pem \\
  -etcd-endpoints=${FLANNEL_ETCD_ENPOINTS} \\
  -etcd-prefix=${FLANNEL_ETCD_PREFIX} \\
  -iface=${IFACE} \\
  -ip-masq
ExecStartPost=${FLANNEL_INSTALL_PATH}/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker

Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF
  
