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
SSL_BIN_PATH=/data/apps/k8s/cfssl
CA_DIR=/etc/k8s/ssl
VIP_KUBEAPI_OUTSIDE=192.168.20.100
VIP_KUBEAPI_INSIDE=10.10.10.100
MASTER1_IP=10.10.10.22
MASTER2_IP=10.10.10.23
MASTER3_IP=10.10.10.24
ETCD1_IP=10.10.10.22
ETCD2_IP=10.10.10.23
ETCD3_IP=10.10.10.24
CLUSTER_KUBERNETES_SVC_IP=10.254.0.1
DOMAIN=mo9.com


[ `id -u` -ne 0 ] && echo "The user no permission exec the scripts, Please use root is exec it..." && exit 0

##############################  Basic tools install of kubernetes  ######################################
#1.Check if directory exists .
if [ ! -d $SSL_BIN_PATH ]; then
     mkdir -p $SSL_PATH
     chmod 755 $SSL_PATH
fi
if [ ! -d $CA_DIR ]; then
     mkdir -p $CA_DIR
     chmod -R 755 $CA_DIR
fi

#2.Install the cfssl tools
which cfssl
if [ $? != 0 ]; then
     rm -rf  $SSL_BIN_PATH/bin
     mkdir -p $SSL_BIN_PATH/bin  > /dev/null 2>&1
     wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -P $SS_BINL_PATH/bin/  > /dev/null 2>&1
     wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -P $SSL_BIN__PATH/bin/  > /dev/null 2>&1
     wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -P $SSL_BIN_PATH/bin/  > /dev/null 2>&1
     cd  $SSL_BIN_PATH/bin/
     mv cfssl_linux-amd64 cfssl  && mv cfssljson_linux-amd64 cfssljson && mv cfssl-certinfo_linux-amd64 cfssl-certinfo
     chmod +x * && ln -sf $SSL_BIN_PATH/bin/* /usr/local/bin/
     echo ".........................................................................."
     echo "INFO: Install successd of ca tool ..."
fi


############################## Create kubernetes certificate file for root ca  ######################################
# Create the root certificate config file
rm -rf $CA_DIR/*
cat >$CA_DIR/ca-config.json<<EOF
{
  "signing": {
    "default": {
      "expiry": "175200h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "175200h"
      }
    }
  }
}
EOF

# Create the root certificate signature request file
cat >$CA_DIR/ca-csr.json<<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

# create ca.pem and ca-key.pem
cd $CA_DIR
cfssl gencert --initca=true ca-csr.json | cfssljson --bare ca
echo ".........................................................................."
echo "INFO: Create ca.pem adn ca-key.pem successd..."


############################## Create kubernetes certificate file ######################################
# Create the kubernetes certificate signature request file
cat >$CA_DIR/kubernetes-csr.json << EOF
{
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
      "${MASTER1_IP}",
      "${MASTER2_IP}",
      "${MASTER3_IP}",
      "${VIP_KUBEAPI_INSIDE}",
      "${VIP_KUBEAPI_OUTSIDE}",
      "${CLUSTER_KUBERNETES_SVC_IP}",
      "*.${DOMAIN}",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "ShangHai",
            "L": "SahgnHai",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF

# Generate kubernetes.pem and kubernetes-key.pem
cd $CA_DIR
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
echo ".........................................................................."
echo "INFO: Create kuernetes.pem and kubernetes-key.pem successd..."


############################## Create certificate file for  kube-controller-manager  ######################################
# Create the  kube-controller-manager  certificate signature request file
cat > $CA_DIR/kube-controller-manager-csr.json <<EOF
{
    "CN": "system:kube-controller-manager",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "${MASTER1_IP}",
      "${MASTER2_IP}",
      "${MASTER3_IP}"
    ],
    "names": [
      {
        "C": "CN",
	"ST": "ShangHai",
        "L": "ShangHai",
        "O": "system:kube-controller-manager",
        "OU": "System"
      }
    ]
}
EOF

# Generate  kube-controller-manager.pem and  kube-controller-manager-key.pem
cd $CA_DIR
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
echo ".........................................................................."
echo "INFO: Create kube-controller-manager.pem and  kube-controller-manager-key.pem successd..."


############################## Create certificate file for kube-scheduler  ######################################
# Create the  kube-scheduler  certificate signature request file
cat > $CA_DIR/kube-scheduler-csr.json <<EOF
{
    "CN": "system:kube-scheduler",
    "hosts": [
      "127.0.0.1",
      "${MASTER1_IP}",
      "${MASTER2_IP}",
      "${MASTER3_IP}"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "system:kube-scheduler",
        "OU": "System"
      }
    ]
}
EOF

# Generate kube-scheduler.pem and kube-scheduler-key.pem
cd $CA_DIR
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes  kube-scheduler-csr.json | cfssljson -bare kube-scheduler
echo ".........................................................................."
echo "INFO: Create kube-scheduler.pem and kube-scheduler-key.pem successd..."


############################## Create certificate file for kubectl ######################################
# Create the admin certificate signature request file
cat > $CA_DIR/admin-csr.json << EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "SahgnHai",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}
EOF

# Generate admin.pem and admin-key.pem
cd $CA_DIR
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin
echo ".........................................................................."
echo "INFO: Create admin.pem and admin-key.pem successd..."


############################## Create certificate file for kube-proxy ######################################
# Create the kube-proxy certificate signature request file
cat > $CA_DIR/kube-proxy-csr.json << EOF
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "SahgnHai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

# Generate kube-proxy.pem and kube-proxy-key.pem
cd $CA_DIR
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
echo ".........................................................................."
echo "INFO: Create  kube-proxy.pem and kube-proxy-key.pem successd..."


############################## Create certificate file for etcd ######################################
# Create the etcd certificate signature request file
cat > $CA_DIR/etcd-csr.json << EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ETCD1_IP}",
    "${ETCD2_IP}",
    "${ETCD3_IP}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "SahgnHai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

# Generate etcd.pem and etcd-key.pem
cd $CA_DIR
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
echo ".........................................................................."
echo "INFO: Create  etcd.pem and etcd-key.pem successd..."


############################## Create certificate file for network ######################################
# Create the network certificate signature request file
cat > $CA_DIR/flannel-csr.json << EOF
{
  "CN": "flanneld",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

# Generate flannel.pem and flannel-key.pem
cd $CA_DIR
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes flannel-csr.json | cfssljson -bare flannel
echo ".........................................................................."
echo "INFO: Create  flannel.pem and flannel-key.pem successd..."


############################## Remove sufix .json and .csr file ######################################
cd $CA_DIR
rm -rf *csr* && rm -rf *json


############################## sync ca files for kubernetes ######################################
#master
ansible master_k8s_vgs -m  shell -a "sudo yum install rsync -y"  > /dev/null 2>&1
ansible master_k8s_vgs -m  synchronize -a "src=/etc/k8s/ssl/  dest=/etc/k8s/ssl/ mode=push  mode=push delete=yes rsync_opts=-avz" -b
ansible master_k8s_vgs -m shell -a "rm -rf /etc/k8s/ssl/{kube-proxy*,admin*}" -b

#worker
ansible worker_k8s_vgs -m  shell -a "sudo yum install rsync -y"  > /dev/null 2>&1
ansible worker_k8s_vgs -m  synchronize -a "src=/etc/k8s/ssl/  dest=/etc/k8s/ssl/ mode=push  mode=push delete=yes rsync_opts=-avz" -b
ansible worker_k8s_vgs -m shell -a "rm -rf /etc/k8s/ssl/{kube-controller-manager*,kubernetes*,kube-scheduler*,etcd*,admin*}" -b



