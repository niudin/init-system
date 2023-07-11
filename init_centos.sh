#!/bin/bash

##check user##
if [[ $UID != 0 ]];then
        echo -e "\033[41;05m Sorry, this script must be run as root! \033[0m"
        exit 1
fi


#init limits
grep -rl '655360' /etc/security/limits.conf &>/dev/null
if [ $? -eq 1 ];then
cat >> /etc/security/limits.conf <<EOF
* soft    nofile  655360
* hard    nofile  655360
* soft    nproc   655360
* hard    nproc   655360
EOF
fi

#set history
if [ ! -f /etc/profile.d/history.sh ];then
cat >> /etc/profile.d/history.sh << EOF
export HISTSIZE=20000
export HISTTIMEFORMAT="%F %T "
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
unset HISTCONTROL
EOF
init q
fi


     disable_srv() {
       sed -i 's/enforcing/disabled/g' /etc/selinux/config 
       systemctl disable postfix --now
       systemctl disable firewalld --now
       systemctl disable rpcbind.socket --now
       systemctl disable rpcbind.service --now
       setenforce 0
     }

     pkg(){
       yum -y install epel-release
       yum groupinstall 'Development tools' base -y
       yum -y update
      }

     init_iptables() {
       yum -y install iptables iptables-services
       cp /usr/libexec/iptables/iptables.init /etc/init.d/iptables
       iptables -F
       iptables -AINPUT -s 127.0.0.1 -jACCEPT
       iptables -AINPUT -p tcp -m tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j REJECT --reject-with tcp-reset
       iptables -AINPUT -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK SYN -m state --state NEW -j REJECT --reject-with tcp-reset
       iptables -AINPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
       iptables -AINPUT -p icmp -m icmp --icmp-type 8 -m limit --limit 1/sec --limit-burst 10 -j ACCEPT
       iptables -AINPUT -p tcp -m multiport --dport 22,80,443,61188 -jACCEPT
       iptables -PINPUT DROP
       iptables-save > /etc/sysconfig/iptables
       systemctl daemon-reload
       systemctl enable iptables --now
     }

     init_sysctl() {
       net.ipv4.tcp_max_tw_buckets = 50000
       net.ipv4.tcp_syncookies = 1
       net.ipv4.tcp_max_syn_backlog = 65535
       net.ipv4.tcp_synack_retries = 2
       net.ipv4.tcp_slow_start_after_idle = 0
       net.core.somaxconn = 65535
       fs.file-max = 600000
       fs.nr_open  = 600000
       net.ipv4.ip_local_port_range = 10000 65000
       sysctl -p
      }
