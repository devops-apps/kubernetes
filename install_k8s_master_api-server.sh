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
K8S_BIN_PATH=${K8S_INSTALL_PATH}/sbin
K8S_LOG_DIR=${K8S_INSTALL_PATH}/logs
K8S_CONF_PATH=/etc/k8s/kubernetes
CA_DIR=/etc/k8s/ssl
SOFTWARE=/root/software
VERSION=v1.12.0
DOWNLOAD_URL=https://github.com/devops-apps/download/raw/master/kubernetes/kubernetes-server-${VERSION}-linux-amd64.tar.gz
ETCD_ENDPOIDS=https://10.10.10.22:2379,https://10.10.10.23:2379,https://10.10.10.24:2379
ETH_INTERFACE=eth1
LISTEN_IP=$(ifconfig | grep -A 1 ${ETH_INTERFACE} |grep inet |awk '{print $2}')
USER=k8s
SERVICE_CIDR=10.254.0.0/22
NODE_PORT_RANG=8400-9400


### 1.Check if the install directory exists.
if [ ! -d "$K8S_INSTALL_PATH" ]; then
     mkdir -p $K8S_INSTALL_PATH
     mkdir -p $K8S_BIN_PATH
else
     if [ ! -d "$K8S_BIN_PATH" ]; then
          mkdir -p $K8S_BIN_PATH
     fi
fi

if [ ! -d "$K8S_LOG_DIR" ]; then
     mkdir -p $K8S_LOG_DIR
     mkdir -p $K8S_LOG_DIR/$KUBE_NAME
else
     if [ ! -d "$K8S_LOG_DIR/$KUBE_NAME" ]; then
          mkdir -p $K8S_LOG_DIR/$KUBE_NAME
     fi
fi

if [ ! -d "$K8S_CONF_PATH" ]; then
     mkdir -p $K8S_CONF_PATH
fi

### 2.Create aduit-policy-file for kube-apiserver
cat>${K8S_CONF_PATH}/audit-policy.yaml<<EOF
apiVersion: audit.k8s.io/v1beta1
kind: Policy
rules:
  # The following requests were manually identified as high-volume and low-risk, so drop them.
  - level: None
    resources:
      - group: ""
        resources:
          - endpoints
          - services
          - services/status
    users:
      - 'system:kube-proxy'
    verbs:
      - watch

  - level: None
    resources:
      - group: ""
        resources:
          - nodes
          - nodes/status
    userGroups:
      - 'system:nodes'
    verbs:
      - get

  - level: None
    namespaces:
      - kube-system
    resources:
      - group: ""
        resources:
          - endpoints
    users:
      - 'system:kube-controller-manager'
      - 'system:kube-scheduler'
      - 'system:serviceaccount:kube-system:endpoint-controller'
    verbs:
      - get
      - update

  - level: None
    resources:
      - group: ""
        resources:
          - namespaces
          - namespaces/status
          - namespaces/finalize
    users:
      - 'system:apiserver'
    verbs:
      - get

  # Don't log HPA fetching metrics.
  - level: None
    resources:
      - group: metrics.k8s.io
    users:
      - 'system:kube-controller-manager'
    verbs:
      - get
      - list

  # Don't log these read-only URLs.
  - level: None
    nonResourceURLs:
      - '/healthz*'
      - /version
      - '/swagger*'

  # Don't log events requests.
  - level: None
    resources:
      - group: ""
        resources:
          - events

  # node and pod status calls from nodes are high-volume and can be large, don't log responses for expected updates from nodes
  - level: Request
    omitStages:
      - RequestReceived
    resources:
      - group: ""
        resources:
          - nodes/status
          - pods/status
    users:
      - kubelet
      - 'system:node-problem-detector'
      - 'system:serviceaccount:kube-system:node-problem-detector'
    verbs:
      - update
      - patch

  - level: Request
    omitStages:
      - RequestReceived
    resources:
      - group: ""
        resources:
          - nodes/status
          - pods/status
    userGroups:
      - 'system:nodes'
    verbs:
      - update
      - patch

  # deletecollection calls can be large, don't log responses for expected namespace deletions
  - level: Request
    omitStages:
      - RequestReceived
    users:
      - 'system:serviceaccount:kube-system:namespace-controller'
    verbs:
      - deletecollection

  # Secrets, ConfigMaps, and TokenReviews can contain sensitive & binary data,
  # so only log at the Metadata level.
  - level: Metadata
    omitStages:
      - RequestReceived
    resources:
      - group: ""
        resources:
          - secrets
          - configmaps
      - group: authentication.k8s.io
        resources:
          - tokenreviews
  # Get repsonses can be large; skip them.
  - level: Request
    omitStages:
      - RequestReceived
    resources:
      - group: ""
      - group: admissionregistration.k8s.io
      - group: apiextensions.k8s.io
      - group: apiregistration.k8s.io
      - group: apps
      - group: authentication.k8s.io
      - group: authorization.k8s.io
      - group: autoscaling
      - group: batch
      - group: certificates.k8s.io
      - group: extensions
      - group: metrics.k8s.io
      - group: networking.k8s.io
      - group: policy
      - group: rbac.authorization.k8s.io
      - group: scheduling.k8s.io
      - group: settings.k8s.io
      - group: storage.k8s.io
    verbs:
      - get
      - list
      - watch

  # Default level for known APIs
  - level: RequestResponse
    omitStages:
      - RequestReceived
    resources:
      - group: ""
      - group: admissionregistration.k8s.io
      - group: apiextensions.k8s.io
      - group: apiregistration.k8s.io
      - group: apps
      - group: authentication.k8s.io
      - group: authorization.k8s.io
      - group: autoscaling
      - group: batch
      - group: certificates.k8s.io
      - group: extensions
      - group: metrics.k8s.io
      - group: networking.k8s.io
      - group: policy
      - group: rbac.authorization.k8s.io
      - group: scheduling.k8s.io
      - group: settings.k8s.io
      - group: storage.k8s.io

  # Default level for all other requests.
  - level: Metadata
    omitStages:
      - RequestReceived
EOF

### 3.Install kube-apiserver binary of kubernetes.
if [ ! -f "$SOFTWARE/kubernetes-server-${VERSION}-linux-amd64.tar.gz" ]; then
     wget $DOWNLOAD_URL -P $SOFTWARE >>/tmp/install.log  2>&1
fi
cd $SOFTWARE && tar -xzf kubernetes-server-${VERSION}-linux-amd64.tar.gz -C ./
cp -fp kubernetes/server/bin/$KUBE_NAME $K8S_BIN_PATH
ln -sf  $K8S_BIN_PATH/$KUBE_NAM /usr/local/bin
chown -R $USER:$USER $K8S_INSTALL_PATH
chmod -R 755 $K8S_INSTALL_PATH

### 4.Install the kube-apiserver service.
cat >/usr/lib/systemd/system/${KUBE_NAME}.service<<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
User=${USER}
Type=notify
WorkingDirectory=${K8S_INSTALL_PATH}
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
  --enable-bootstrap-token-auth=true \\
  --token-auth-file=${K8S_CONF_PATH}/token.csv \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --service-node-port-range=${NODE_PORT_RANG} \\
  --tls-cert-file=${CA_DIR}/kubernetes.pem \\
  --tls-private-key-file=${CA_DIR}/kubernetes-key.pem \\
  --client-ca-file=${CA_DIR}/ca.pem \\
  --service-account-key-file=${CA_DIR}/ca-key.pem \\
  --etcd-cafile=${CA_DIR}/ca.pem \\
  --etcd-certfile=${CA_DIR}/etcd.pem \\
  --etcd-keyfile=${CA_DIR}/etcd-key.pem \\
  --etcd-servers=${ETCD_ENDPOIDS} \\
  --kubelet-certificate-authority=${CA_DIR}/ca.pem \\
  --kubelet-client-certificate=${CA_DIR}/kubernetes.pem \\
  --kubelet-client-key=${CA_DIR}/kubernetes-key.pem \\
  --kubelet-https=true \\
  --enable-swagger-ui=true \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=15 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=${K8S_LOG_DIR}/${KUBE_NAME}/audit.log \\
  --audit-policy-file=${K8S_CONF_PATH}/audit-policy.yaml \\
  --storage-backend=etcd3 \\
  --max-mutating-requests-inflight=2000 \\
  --max-requests-inflight=4000 \\
  --event-ttl=168h \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=${K8S_LOG_DIR}/${KUBE_NAME} \\
  --v=2

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
