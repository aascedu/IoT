install_server()
{
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --node-ip 192.168.56.110
    sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/token
}

install_agent()
{
    SERVER_TOKEN=$(cat /vagrant/token)
    echo $SERVER_TOKEN
    curl -sfL https://get.k3s.io | K3S_TOKEN=$SERVER_TOKEN K3S_URL=https://192.168.56.110:6443 sh -s - --node-ip 192.168.56.111
}

if [ "$1" = "server" ]; then
    install_server
else
    install_agent
fi