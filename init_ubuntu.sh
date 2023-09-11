#!/bin/bash

# 更新系统包
apt update

# 安装 net-tools
apt install -y net-tools

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

# 将SSH公钥添加到 ubuntu 用户的 .ssh/authorized_keys
SSH_KEY="SSH-RSA YOUR_PUBLIC_KEY_HERE"
AUTH_KEYS="/home/ubuntu/.ssh/authorized_keys"
mkdir -p /home/ubuntu/.ssh
touch $AUTH_KEYS
if ! grep -q "$SSH_KEY" $AUTH_KEYS; then
  echo "$SSH_KEY" >> $AUTH_KEYS
fi
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 600 $AUTH_KEYS

# 设置历史记录数为20000
echo "HISTFILESIZE=20000" >> /etc/environment
echo "HISTSIZE=20000" >> /etc/environment

# 脚本结束
echo "Initialization complete."
