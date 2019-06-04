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
DOCKER-ROOT=/data/apps/docker
registry-mirrors1=https://docker.mirrors.ustc.edu.cn
registry-mirrors2=https://registry-mirrors.mo9.com


### 1.Uninstall the original docker package
sudo yum -y remove docker docker-client  docker-client-latest  docker-common docker-latest docker-latest-logrotate docker-selinux docker-engine-selinux docker-engine

### 2.Install docker-ce-17.03 docker package
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 bridge-utils >>/dev/null 2>&1
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo >>/dev/null 2>&1
sudo yum install -y --setopt=obsoletes=0 docker-ce-17.03.2.ce-1.el7.centos docker-ce-selinux-17.03.2.ce-1.el7.centos >>/dev/null 2>&1
sudo usermod -aG docker k8s >>/dev/null 2>&1


#### 3.Configuration the docker daemon.json

# Create the docker profile directory
if [ ! -d "/etc/docker" ]; then
     mkdir /etc/docker/ 
fi

# Touch the docker daemon.json file
cat >/etc/docker/daemon.json <<EOF
{
	"authorization-plugins": [],
	"dns": ["223.5.5.5","223.4.4.4"],
	"dns-opts": [],
	"dns-search": [],
	"exec-opts": [],
	"exec-root": "/data/apps/docker",
        "graph": "/data/apps/docker",
	"experimental": false,
	"storage-driver": "overlay2",
        "storage-opts": ["overlay2.override_kernel_check=true"  ],
	"labels": [],
	"live-restore": true,
	"log-driver": "syslog",
	"log-opts": {},
	"mtu": 0,
	"pidfile": "/var/run/docker/docker.pid",
	"cluster-store": "",
	"cluster-store-opts": {},
	"cluster-advertise": "",
	"max-concurrent-downloads": 20,
	"max-concurrent-uploads": 5,
	"shutdown-timeout": 15,
	"debug": true,
	"default-ulimit": ["65535:65535"],
	"hosts": ["tcp://127.0.0.1:2376","unix:///var/run/docker.sock"],
	"log-level": "INFO",
	"swarm-default-advertise-addr": "",
	"api-cors-header": "",
	"selinux-enabled": false,
	"userns-remap": "",
	"group": "",
	"cgroup-parent": "",
	"init": false,
	"init-path": "/usr/libexec/docker-init",
	"ipv6": false,
	"iptables": true,
	"ip-forward": false,
	"ip-masq": false,
	"userland-proxy": false,
	"userland-proxy-path": "/usr/libexec/docker-proxy",
	"ip": "0.0.0.0",
	"bridge": "",
	"fixed-cidr": "",
	"default-gateway": "",
	"icc": false,
	"raw-logs": false,
	"registry-mirrors": ["${registry-mirrors1}", "${registry-mirrors2}"],
	"seccomp-profile": "",
	"insecure-registries": [],
	"runtimes": {
		"cc-runtime": {
			"path": "/usr/bin/cc-runtime"
		},
		"custom": {
			"path": "/usr/local/bin/my-runc-replacement",
			"runtimeArgs": [
				"--debug"
			]
		}
	}
}
EOF


#### 4.Install docker service on worker of kubernetes
cat >/usr/lib/systemd/system/docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
EnvironmentFile=-/run/flannel/docker
ExecStart=/usr/bin/dockerd  $DOCKER_NETWORK_OPTIONS
ExecReload=/bin/kill -s HUP $MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF
