#!/bin/bash
if ! command -v docker &> /dev/null; then
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
sudo docker run -p 80:8686 --rm --name ztool -v $PWD/data:/home/ztooluser/data:Z --cap-add=SYS_ADMIN nft9/ztool:stable &