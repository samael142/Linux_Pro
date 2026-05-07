#!/bin/bash

NFS_SERVER="127.0.0.1"

apt update && apt install nfs-common -y
mkdir -p /mnt/nfs_client
echo "${NFS_SERVER}:/srv/nfs_share /mnt/nfs_client nfs _netdev,auto,nofail,vers=3 0 0" >> /etc/fstab
mount -a
