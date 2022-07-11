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
echo "Start tool"
ulimit -n 99999
sudo mkdir -p /mnt/ztool/profiles
sudo chmod 777 /mnt/ztool/profiles

sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

sudo sysctl fs.inotify.max_user_instances=8192
sudo sysctl fs.inotify.max_user_watches=1048576
sudo sysctl -p

sudo docker run --shm-size=10gb -v /mnt/ztool/profiles:/home/ztooluser/profiles:Z -v /dev/shm:/dev/shm -p 80:8686 --rm --name ztool --dns="1.1.1.1" --dns="1.0.0.1" --cap-add=SYS_ADMIN nft9/ztool:stable
