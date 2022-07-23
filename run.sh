#!/bin/bash
if ! command -v "docker" > /dev/null 2>&1; then
echo "Install docker"
curl -fsSL https://get.docker.com/ | sh
fi
echo "Start docker"
sudo systemctl start docker
sudo service docker start
echo "Stop running instance"
sudo docker ps -q --filter name=ztool | xargs -r sudo docker stop
echo "Remove old instance"
sudo docker image rm -f nft9/ztool:stable 2> /dev/null || true
echo "Create data directory"
sudo mkdir -p ./data && sudo chmod +x ./data

echo "Tunning system"

sudo bash -c 'cat>/etc/sysctl.conf<<EOF
# SWAP settings
#vm.swappiness=0
#vm.overcommit_memory=1

fs.file-max=999999
fs.nr_open=999999

net.ipv4.ip_local_port_range=1024 65000
net.ipv4.tcp_keepalive_time=60
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_intvl=10
net.ipv4.tcp_max_syn_backlog=100000

net.netfilter.nf_conntrack_tcp_timeout_established=600
net.netfilter.nf_conntrack_tcp_timeout_time_wait=10
net.netfilter.nf_conntrack_tcp_timeout_close=10
net.netfilter.nf_conntrack_tcp_timeout_fin_wait=10
net.netfilter.nf_conntrack_tcp_timeout_last_ack=10
net.netfilter.nf_conntrack_tcp_timeout_syn_recv=10
net.netfilter.nf_conntrack_tcp_timeout_syn_sent=10
net.netfilter.nf_conntrack_tcp_timeout_close_wait=10
net.nf_conntrack_max = 655360


net.core.somaxconn = 100000
net.core.netdev_max_backlog = 100000

# Timeout in seconds to close client connections in
# TIME_WAIT after receiving FIN packet.
net.ipv4.tcp_fin_timeout = 10

# Disable SYN cookie flood protection
net.ipv4.tcp_syncookies = 0
#net.ipv4.tcp_timestsmps= 0

# 16MB per socket - which sounds like a lot,
# but will virtually never consume that much.
#net.core.rmem_max=16777216
#net.core.wmem_max=16777216

# Various network tunables
net.ipv4.tcp_max_syn_backlog=65535
net.ipv4.tcp_max_tw_buckets=400000
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_tw_reuse= 1
#net.ipv4.tcp_tw_recycle = 1

net.ipv4.tcp_wmem=8192 436600 873200
net.ipv4.tcp_rmem = 32768 436600 873200

# ARP cache settings for a highly loaded docker swarm
#net.ipv4.neigh.default.gc_thresh1=8096
#net.ipv4.neigh.default.gc_thresh2=12288
#net.ipv4.neigh.default.gc_thresh3=16384

# monitor file system events
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
#max threads count
kernel.threads-max=3261780
EOF'

sudo bash -c 'cat>/etc/security/limits.conf<<EOF
* hard nofile 999999
* soft nofile 999999
* hard nproc  999999
* soft nproc  999999
EOF'

sudo sysctl -p

#end tunning

sudo mkdir -p /mnt/ztool/profiles
sudo chmod 777 /mnt/ztool/profiles

echo "Download tools"
sudo docker pull nft9/ztool:stable

echo "Start tool"
sudo docker run \
  --sysctl net.ipv4.ip_local_port_range="1024 65535" \
  --sysctl net.ipv4.tcp_keepalive_time="60" \
  --sysctl net.ipv4.tcp_keepalive_probes="3" \
  --sysctl net.ipv4.tcp_keepalive_intvl="10" \
  --sysctl net.ipv4.tcp_max_syn_backlog="100000" \
  --sysctl net.core.somaxconn="100000" \
  --sysctl net.ipv4.tcp_fin_timeout=10 \
  --sysctl net.netfilter.nf_conntrack_tcp_timeout_established=600 \
  --sysctl net.netfilter.nf_conntrack_tcp_timeout_time_wait=10 \
  --sysctl net.netfilter.nf_conntrack_tcp_timeout_close_wait=10 \
  --sysctl net.netfilter.nf_conntrack_tcp_timeout_close=10 \
  --sysctl net.netfilter.nf_conntrack_tcp_timeout_fin_wait=10 \
  --sysctl net.ipv4.tcp_syncookies=0 \
  --sysctl net.ipv4.tcp_tw_reuse=1 \
  --sysctl net.ipv4.tcp_syn_retries=2 \
  --sysctl net.ipv4.tcp_synack_retries=2 \
  --shm-size=10gb \
  -v /mnt/ztool/profiles:/home/ztooluser/profiles:Z \
  -v /dev/shm:/dev/shm \
  -p 80:8686 \
  -e XARGS="--auto --debug" \
  --rm \
  --name ztool \
  --dns="1.1.1.1" \
  --dns="1.0.0.1" \
  --cap-add=SYS_ADMIN \
  nft9/ztool:stable --auto --debug --loop --task_delay=20 --batch_delay=100 --task_ids=628f283a0414cde414815bad --max_cpu=90 --max_ram=80 --limit_minutes=600
