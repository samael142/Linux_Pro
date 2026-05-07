#!/bin/bash

apt update && apt install nfs-kernel-server -y
mkdir -p /srv/nfs_share
mkdir -p /srv/nfs_share/upload
chmod 777 /srv/nfs_share/upload
echo "/srv/nfs_share *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
exportfs -r
