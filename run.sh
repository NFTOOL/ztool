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
echo "Download tools"
sudo docker pull nft9/ztool:stable


echo "Tunning system"

sudo bash -c 'cat>/etc/sysctl.conf<<EOF
fs.file-max=999999
fs.nr_open=999999
net.ipv4.ip_local_port_range=1024 65000
net.ipv4.tcp_keepalive_time=60
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_intvl=90
net.ipv4.tcp_max_syn_backlog=100000
net.core.somaxconn = 100000
net.core.netdev_max_backlog = 100000
EOF'

sudo bash -c 'cat>/etc/security/limits.conf<<EOF
* hard nofile 999999
* soft nofile 999999
* hard nproc  999999
* soft nproc  999999
EOF'

sudo sysctl fs.inotify.max_user_instances=8192
sudo sysctl fs.inotify.max_user_watches=1048576
ulimit -n 99999
ulimit -u 99999
sudo sysctl -p

#end tunning

sudo mkdir -p /mnt/ztool/profiles
sudo chmod 777 /mnt/ztool/profiles

echo "Start tool"
sudo docker run --shm-size=10gb -v /mnt/ztool/profiles:/home/ztooluser/profiles:Z -v /dev/shm:/dev/shm -p 80:8686 --rm --name ztool --dns="1.1.1.1" --dns="1.0.0.1" --cap-add=SYS_ADMIN nft9/ztool:stable
