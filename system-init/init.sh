#!/bin/bash
#
# Description: This is sysytem optimization scripts about centos !
################################################################
# Author：Kevin li
# Blog: https://blog.51cto.com/blief
# QQ: 2658757934
# Date: 2019.5.28
################################################################

[ `id -u` -ne 0  ] && echo "The user no permission exec the scripts, Please use root is exec it..." && exit 0

# Variable settings
PATH=/bin:/sbin:/usr/bin:/usr/sbin && export PATH
SIZE=8G
PORT=8989
USER_DEVOPS=gamaxwin
SSH_DEVOPS=/home/${USER_DEVOPS}/.ssh
DATA=/data
DISK_NAME=/dev/sdb
KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnJ0UYNQYpRei2rtYNlbxcJhpOtvhnLPPyAMqo3gpQ2jGJ75ASlu1F1sID84qytgZi0KlQFngYTIh5Lsn7nAy/TT9stVwLOLC1P7b8YgXsfBUNhRcfC1RDasdAyHns+W3hxSHcSGS/hUA33T3sT3f/ltucl7telUSKOL+9p6AI7ckPMn2j9zKqLAaTDZKKUZ4gSSnnX9T7PQX91y94raynrS8HvKK6jBUmlWbYhALj1Zhfj840gmLxo8y91i5WvfieZ+DvjfH5Y89leSv8W5uVZC8PDkIw3aJ7YFvJZi4RIwFl2zKtDt4KhwIm9evfZfM4t9fuLCIHxrc4ZrJ+3asd devops user"
MEM_STATUS=$(free -m | grep Swap | awk -F ":" '{print $1}')
DISK_STATUS=$(ls -l ${DISK_NAME}* | wc -l)


read -p "Initialize the system to the default state, the operation will lead to data loss,please make sure the operation? please input [y/n]:" STATE

#./start
if [ "$STATE" = "y" ]; then

############################# Initializes the disk /dev/vdb ####################################
read -p "Do you want format the disk $DISK_NMAE, please input [y/n]:" INPUT
if [ "$INPUT" = "y" ]; then
     if [ $DISK_STATUS -gt 1 ]; then
          echo ".........................................................................."
          echo "INFO: The disk $DISK_NMAE is already format..."
          echo ".........................................................................."
     else       
          #install lvm2 tools
          yum install lvm2 -y  >>/dev/null 2>&1
          #create swap  partition
          if [ "$MEM_STATUS" = "Swap" ]; then
               echo ".........................................................................."
	       echo -e "INFO: The swap memory of system has already add... Don't Repeat to add !"
               echo ".........................................................................."
               #Create Primary partition
               echo -ne "n\np\n1\n\n\nt\n8e\nw\nEOF\n" |fdisk $DISK_NAME  >>/dev/null 2>&1
               #Create lvm and formatting
               pvcreate ${DISK_NMAE}1 >>/dev/null 2>&1
               vgcreate vg01 ${DISK_NMAE}1 >>/dev/null 2>&1
               lvcreate -l 100%VG -n data  vg01 >>/dev/null 2>&1
               mkfs.xfs /dev/vg01/data >>/dev/null 2>&1
               echo "INFO: Create lv volume success..."
               echo ".........................................................................."
               echo "INFO: The disk initializes success..."
               echo ".........................................................................."
          else
               echo -ne "n\np\n1\n\n+$SIZE\nt\n\n82\nw\nEOF\n" |fdisk $DISK_NAME  >>/dev/null 2>&1
	       #formatting swap
	       mkswap ${DISK_NMAE}1 >>/dev/null 2>&1
	       echo "INFO: Create swap volume success..."
               #Create Primary partition
               echo -ne "n\np\n2\n\n\nt\n2\n8e\nw\nEOF\n" |fdisk $DISK_NAME  >>/dev/null 2>&1
               #Create lvm and formatting
               pvcreate ${DISK_NMAE}2 >>/dev/null 2>&1
               vgcreate vg01 ${DISK_NMAE}2 >>/dev/null 2>&1
               lvcreate -l 100%VG -n data  vg01 >>/dev/null 2>&1
               mkfs.xfs /dev/vg01/data >>/dev/null 2>&1
               echo ".........................................................................."
               echo "INFO: Create lv volume success..."
               echo ".........................................................................."
               echo "INFO: The disk initializes success..."
               echo ".........................................................................."
	  fi
     fi
fi
if [ "$INPUT" = "n" ]; then
     echo "INFO: Don't format the disk..."
     echo ".........................................................................."
fi


############################# Automatic mount partition to the system  ##########################
#mount  partition to system
if [ -d $DATA ]; then
     echo "the data directory  is already create..." >>/dev/null 2>&1
else
     mkdir $DATA
fi
read -p "Do you want mount the disk, please input [y/n]:" ANSWER
if [ "$ANSWER" = "y" ]; then
     sudo cp -f /etc/fstab /etc/fstab.bak
     sudo sed -i  '\/dev\/vdb1 /d' /etc/fstab
     sudo sed -i  '\/dev\/vg01\/data /d' /etc/fstab
     echo -e "/dev/vdb1               swap                    swap    defaults    0 0" >> /etc/fstab
     echo -e "/dev/vg01/data          /data                   xfs     defaults    0 0" >> /etc/fstab
     echo "INFO: The partitions is mount success..."
     echo ".........................................................................."
fi
if [ "$ANSWER" = "n" ]; then
     echo "INFO: Don't need mounted any disk..."
     echo ".........................................................................."
fi     


############################# Initializes the server system #########################
#Add devops user to the system
if [ -d $SSH_DEVOPS ]; then
     echo "the devops user is already create..."  >>/dev/null 2>&1
else
     groupadd $USER_DEVOPS
     useradd -g $USER_DEVOPS $USER_DEVOPS
fi

#Add ssh Public Key.
#devops
if [ -d $SSH_DEVOPS ]; then
     echo "the gamaxwin ssh public key is already create..."  >>/dev/null 2>&1
     echo ".........................................................................."
else
     sudo -u $USER_DEVOPS -H mkdir $SSH_DEVOPS
     sudo -u $USER_DEVOPS -H echo -e "$KEY" > $SSH_DEVOPS/authorized_keys
     sudo chown -R $USER_DEVOPS:$USER_DEVOPS $SSH_DEVOPS
     sudo chmod 0700 $SSH_DEVOPS
     sudo chmod 0600 $SSH_DEVOPS/authorized_keys
fi
echo "INFO:initializes the server system success!"
echo ".........................................................................."

#Add sudo permissions to devops in /etc/sudoers file .
sudo cp -r  /etc/sudoers /etc/sudoers.bak
sudo sed -i  '/Cmnd_Alias USERSHELL/d'  /etc/sudoers
sudo sed -i  "/$USER_DEVOPS/d" /etc/sudoers
sudo sed -i  '/Defaults    requiretty/s/^Defaults/#Defaults/g'  /etc/sudoers 
sudo sed -i  "s:\/usr/bin:&\:/usr/local/sbin:"  /etc/sudoers
sudo sed -i  "/## Allow root to run any commands anywhere/a\\$USER_DEVOPS        ALL=(ALL)       NOPASSWD: ALL"  /etc/sudoers

#Configure SSH server and client to use EFS logon while Public Key Authentication.
sudo sed -i  "/Port 8989/s/^Port 8989/Port $PORT/g"  /etc/ssh/sshd_config
sudo sed -i  '/#RSAAuthentication yes/s/^#RSAAuthentication yes/RSAAuthentication yes/g'  /etc/ssh/sshd_config
sudo sed -i '/#PubkeyAuthentication yes/s/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i "/#AuthorizedKeysFile/s/^#//g" /etc/ssh/sshd_config
sudo sed -i "/PermitRootLogin yes/s/yes/no/g" /etc/ssh/sshd_config
sudo sed -i  "/AllowUsers $USER_DEVOPS/d"  /etc/ssh/sshd_config
sudo sed -i  "/^PasswordAuthentication yes/a\\AllowUsers $USER_DEVOPS"  /etc/ssh/sshd_config
sudo service sshd reload  >>/dev/null 2>&1

# Close Selinux and Iptables and ipv6
systemctl stop firewalld.service >>/dev/null 2>&1
systemctl disable firewalld.service >>/dev/null 2>&1
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0 >>/dev/null 2>&1
sed -i "s:centos/swap rhgb:& ipv6.disable=1 :" /etc/sysconfig/grub 
grub2-mkconfig -o /boot/grub2/grub.cfg >>/dev/null 2>&1


############################# Update and Optimizing the server system #########################
#Optimizing the file system
sudo sed -i  '/1024/s/1024/4096/g' /etc/security/limits.d/20-nproc.conf
sudo cp -f /etc/security/limits.conf /etc/security/limits.conf.bak
cat > /etc/security/limits.conf<<EOF
* soft nofile 1024000
* hard nofile 1024000
* soft nproc 65535
* hard nproc 65535
EOF

#Optimizing the system kernel
sudo  cp -f /etc/sysctl.conf /etc/sysctl.conf.bak
cat > /etc/sysctl.conf<<EOF
#Old config
net.ipv4.ip_forward = 0
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
#vm.swappiness = 0
vm.swappiness = 1
net.ipv4.neigh.default.gc_stale_time= 120
net.ipv4.conf.all.rp_filter= 0
net.ipv4.conf.default.rp_filter= 0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.all.arp_announce= 2
net.ipv4.conf.lo.arp_announce= 2
#New add config 
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
fs.file-max = 1024000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 32768
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_wmem = 8192 131072 16777216
net.ipv4.tcp_rmem = 32768 131072 16777216
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.ip_local_port_range = 1024 65535
net.core.somaxconn = 65535
EOF
echo "INFO: Update and optimizing the server system success !"
echo ".........................................................................."

############################ Reboot server system #############################
read -p "Initializes system success!, But it is need reboot now, please input [y/n]:" ID
if [ "$ID" = "y" ]; then
     reboot now
fi
if [ "$ID" = "n" ]; then
     exit 0
fi

fi
#./End

if [ "$STATE" = "n" ]; then
     exit 0
fi
