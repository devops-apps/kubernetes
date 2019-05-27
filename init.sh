## Setting environment variables
group=devops
user=devops

## Initializes the system and installation the network tools
sudo yum install net-tools vim openssl-devel zlib-devel bios-devel perc-devel telnet gcc-c++ bind-utils net-untils curl-devel wget -y

## Update the  Linux yum source repository
cd   /etc/yum.repos.d
mv  CentOS-Base.repo   CentOS-Base.repo.bak
wget http://mirrors.aliyun.com/repo/Centos-7.repo
mv Centos-7.repo CentOS-Base.repo
yum clean all
yum makecache

## Optimize SSH key login
groupadd $group
useradd -g $group $user
sed -i  's/^#Port 22/Port 60022/g'  /etc/ssh/sshd_config
sed -i  '/#RSAAuthentication yes/s/^#RSAAuthentication yes/RSAAuthentication yes/g'  /etc/ssh/sshd_config
sed -i '/#PubkeyAuthentication yes/s/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sed -i "/#AuthorizedKeysFile/s/^#//g" /etc/ssh/sshd_config
sed -i "/PermitRootLogin yes/s/yes/no/g" /etc/ssh/sshd_config
sed -i  '/PasswordAuthentication yes/a\AllowUsers devops root' /etc/ssh/sshd_config

## Network optimization
grub2-mkconfig -o /boot/grub2/grub.cfg
net.ifnames=0 biosdevname=0

## Kernel optimization
sudo sed -i  '/1024/s/1024/4096/g' /etc/security/limits.d/20-nproc.conf
sudo cp -f /etc/security/limits.conf /etc/security/limits.conf.bak
cat > /etc/security/limits.conf<<EOF
* soft nofile 1024000
* hard nofile 1024000
* soft nproc 65535
* hard nproc 65535
EOF


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

---
