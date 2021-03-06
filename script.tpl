#!/bin/bash
sudo apt-get update
sudo apt-get install -y git binutils make
sudo mkdir -p /var/www/html
git clone https://github.com/aws/efs-utils
cd efs-utils && make deb
sudo apt-get install -y ./build/amazon-efs-utils*deb
efs_id="${efs_id}"
echo $efs_id:/ /var/www/html efs defaults,_netdev 0 0 >> /etc/fstab
sudo mount -a
