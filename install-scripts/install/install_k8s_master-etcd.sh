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
ETCD_INSTALL_PATH=/data/apps/k8s/etcd
SOFTWARE=/root/software
VERSION=v3.3.13
DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/etcd/etcd-${VERSION}-linux-amd64.tar.gz
CA_PATH=/etc/k8s/ssl
ETCD_ENPOIDTS="etcd01=https://10.10.10.22:2380,etcd02=https://10.10.10.23:2380,etcd03=https://10.10.10.24:2380"
LISTEN_IP=$(ifconfig | grep -A 1 eth1 |grep inet |awk '{print $2}')
USER=K8s

### 1.Check if the install directory exists.
if [ ! -d $ETCD_INSTALL_PATH ]; then
     mkdir $ETCD_INSTALL_PATH
     chmod 0755 $ETCD_INSTALL_PATH

fi

### 2.Install kube-controller-manager binary of kubernetes.
mkdir -p $ETCD_INSTALL_PATH/bin >>/dev/null
if [ ! -f "$SOFTWARE/etcd-${VERSION}-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE
     chmod -R 755 $ETCD_INSTALL_PATH
fi

mkdir -p $ETCD_INSTALL_PATH/bin >>/dev/null 2>&1
cd $SOFTWARE && tar -xzf etcd-${VERSION}-linux-amd64.tar.gz -C ./
cp -fp etcd-${VERSION}-linux-amd64/etcd* $ETCD_INSTALL_PATH/bin
ln -sf  $ETCD_INSTALL_PATH/bin/* /usr/local/bin
sudo chown -R $USER:$USER $ETCD_INSTALL_PATH

### 3.Install service of etcd .
cat >/usr/lib/systemd/system/etcd.service<<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
[Service]
Type=notify
WorkingDirectory=${ETCD_INSTALL_PATH}/data
User=${USER}
# set GOMAXPROCS to number of processors
ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/local/bin/etcd  \\
                        --name=etcd01 \\
                        --data-dir=${ETCD_INSTALL_PATH}/data \\
                        --cert-file=${CA_PATH}/etcd.pem \\
                        --key-file=${CA_PATH}/etcd-key.pem \\
                        --trusted-ca-file=${CA_PATH}/ca.pem \\
                        --peer-cert-file=${CA_PATH}/etcd.pem \\
                        --peer-key-file=${CA_PATH}/etcd-key.pem \\
                        --peer-trusted-ca-file=${CA_PATH}/ca.pem \\
                        --peer-client-cert-auth=true \\
                        --client-cert-auth=true \\
                        --listen-peer-urls=https://${LISTEN_IP}:2380 \\
                        --initial-advertise-peer-urls=https://${LISTEN_IP}:2380 \\
                        --listen-client-urls=https://${LINSTEN_IP}:2379,https://127.0.0.1:2379 \\
                        --advertise-client-urls=https://10.10.10.22:2379 \\
                        --initial-cluster-token=etcd-cluster-0 \\
                        --initial-cluster=${ETCD_ENPOIDTS} \\
                        --initial-cluster-state=new \\
                        --auto-tls=true \\
                        --peer-auto-tls=true"
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF