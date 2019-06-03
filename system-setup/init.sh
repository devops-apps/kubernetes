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
USER=k8s


########## Init settings of system ##########
# Install the system dependencies package.
yum install -y epel-release >>/dev/null 2>&1
yum install -y conntrack ipvsadm ipset jq sysstat curl iptables libseccomp ntp telnet >>/dev/null 2>&1

# Disable the system firewall.
systemctl stop firewalld >>/dev/null 2>&1
systemctl disable firewalld >>/dev/null 2>&1

# Shut down the system swap partition.
swapoff -a  >>/dev/null 2>&1
sed -i 's/.*swap.*/#&/' /etc/fstab

# Disable the system selinux.
setenforce  0 
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux  >>/dev/null 2>&1
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config  >>/dev/null 2>&1
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux >>/dev/null 2>&1
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config  >>/dev/null 2>&1
echo ".........................................................................."
echo "INFO: Install successd of system ..."


########## Optimization kernel of system ##########
# Load the Linux kernel module.
sudo modprobe br_netfilter 
sudo modprobe ip_vs
sudo modprobe ip_conntrack 

# Setting kubernetes  kernel parameters.
sudo sed -i '/net.ipv4.ip_forward=/d' /etc/sysctl.conf
sudo sed -i '/net.bridge.bridge-nf-call-iptables=/d'  /etc/sysctl.conf
sudo sed -i '/net.bridge.bridge-nf-call-ip6tables=/d'  /etc/sysctl.conf
sudo sed -i '/net.ipv4.ip_forward=/d'  /etc/sysctl.conf
sudo sed -i '/net.ipv4.tcp_tw_recycle=/d'  /etc/sysctl.conf
sudo sed -i '/vm.swappiness=/d'  /etc/sysctl.conf
sudo sed -i '/vm.overcommit_memory=/d'  /etc/sysctl.conf
sudo sed -i '/vm.panic_on_oom=/d'  /etc/sysctl.conf
sudo sed -i '/fs.inotify.max_user_watches=/d'  /etc/sysctl.conf
sudo sed -i '/fs.file-max=/d'  /etc/sysctl.conf
sudo sed -i '/fs.nr_open=/d'  /etc/sysctl.conf
sudo sed -i '/net.ipv6.conf.all.disable_ipv6=/d'  /etc/sysctl.conf
sudo sed -i '/net.netfilter.nf_conntrack_max=/d'  /etc/sysctl.conf
cat >/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720 
EOF
sysctl -p /etc/sysctl.d/kubernetes.conf

# Setting system time zone.
timedatectl set-timezone Asia/Shanghai
timedatectl set-local-rtc 0
systemctl restart rsyslog 
systemctl restart crond
ntpdate cn.pool.ntp.org
echo ".........................................................................."
echo "INFO: Set successd of system ..."


############ Check the service running user and working directory. ##############
# create user if not exists
egrep "^$USER" /etc/passwd > /dev/null
if [ $? -ne 0 ]; then
     groupadd $USER
     useradd -g $USER -d /var/lib/k8s -c "Kubernetes Service" -m -s /sbin/nogin  $USER
fi
