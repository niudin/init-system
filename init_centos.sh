#!/bin/bash

# 安装 EPEL 仓库和基础开发工具
yum -y install epel-release
yum groupinstall 'Development Tools' 'Base' -y

# 更新系统包
yum update -y

# 安装 net-tools
yum install -y net-tools

# 检查 /etc/security/limits.conf 文件以更新文件句柄和进程数
if ! grep -q "655360" /etc/security/limits.conf; then
  tee -a /etc/security/limits.conf > /dev/null << EOL
* soft nofile 655360
* hard nofile 655360
* soft nproc 655360
* hard nproc 655360
EOL
fi

# 设置时区为香港
timedatectl set-timezone Asia/Hong_Kong

# 将SSH公钥添加到 centos 用户的 .ssh/authorized_keys
SSH_KEY="SSH-RSA YOUR_PUBLIC_KEY_HERE"
AUTH_KEYS="/home/centos/.ssh/authorized_keys"
mkdir -p /home/centos/.ssh
touch $AUTH_KEYS
if ! grep -q "$SSH_KEY" $AUTH_KEYS; then
  echo "$SSH_KEY" >> $AUTH_KEYS
fi
chown -R centos:centos /home/centos/.ssh
chmod 600 $AUTH_KEYS

# 设置历史记录数为20000
echo "HISTFILESIZE=20000" >> /etc/environment
echo "HISTSIZE=20000" >> /etc/environment

# 禁用不必要的服务和 SELinux
disable_srv() {
  sed -i 's/enforcing/disabled/g' /etc/selinux/config 
  systemctl disable postfix --now
  systemctl disable firewalld --now
  systemctl disable rpcbind.socket --now
  systemctl disable rpcbind.service --now
  setenforce 0
}

# 初始化 iptables
init_iptables() {
  yum -y install iptables iptables-services
  cp /usr/libexec/iptables/iptables.init /etc/init.d/iptables
  iptables -F
  iptables -A INPUT -s 127.0.0.1 -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j REJECT --reject-with tcp-reset
  iptables -A INPUT -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK SYN -m state --state NEW -j REJECT --reject-with tcp-reset
  iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -A INPUT -p icmp -m icmp --icmp-type 8 -m limit --limit 1/sec --limit-burst 10 -j ACCEPT
  iptables -A INPUT -p tcp -m multiport --dport 22,80,443,61188 -j ACCEPT
  iptables -P INPUT DROP
  iptables-save > /etc/sysconfig/iptables
  systemctl daemon-reload
  systemctl enable iptables --now
}

# 执行禁用服务和初始化 iptables 函数
disable_srv
#init_iptables

# 脚本结束
echo "Initialization complete."
