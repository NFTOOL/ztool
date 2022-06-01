#!/bin/bash
if  command -v docker &> /dev/null; then
echo "Start docker"
sudo systemctl start docker
sudo service docker start
echo "Stop running instance"
sudo docker ps -q --filter name=ztool | xargs -r sudo docker stop
echo "Remove old instance"
sudo docker image rm -f nft9/ztool:stable 2> /dev/null || true
sudo docker system prune -f
fi
echo "Done"
