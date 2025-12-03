#! /bin/bash

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --node-ip 192.168.56.110 --flannel-iface eth1