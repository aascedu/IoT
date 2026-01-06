I made this file to keep track of the cmds or ways to create the host that will have Vagrant installed.

Create the QEMU image :
`qemu-img create -f qcow2 ~/goinfre/iot-vm.qcow2 60G`

Then the host with QEMU :
```
  qemu-system-x86_64 \
  -enable-kvm \
  -m 8G \
  -smp 20 \
  -cpu max \
  -hda ~/goinfre/iot-vm.qcow2 \
  -cdrom ~/Downloads/ubuntu-24.04-server.iso \
  -boot d \
  -vga virtio \
  -nic user,hostfwd=tcp::2222-:22
```
Then to launch the VM :
```
qemu-system-x86_64 \
  -enable-kvm \
  -m 8192 \
  -smp 20 \
  -cpu max \
  -hda ~/goinfre/iot-vm.qcow2 \
  -nic user,hostfwd=tcp::2222-:22,hostfwd=tcp::8888-:8888 \
  -vga virtio
```
```
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update -y
sudo apt install -y vagrant virtualbox
```

then from the 42 session you can copy files with :  
`rsync -e "ssh -p 2222" [src] [dst]`

For part 3 if you want to route to correct Hostname you can use these ressources / commands :

https://argo-cd.readthedocs.io/en/stable/getting_started/
https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#traefik-v30
https://argo-cd.readthedocs.io/en/stable/operator-manual/server-commands/additional-configuration-method/

```
chromium \
        --host-resolver-rules="MAP argocd.local 127.0.0.1" \
        --ignore-certificate-errors \
        --new-window
```