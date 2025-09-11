# VM Development Setup: VirtualBox + VS Code

## Goals
- Edit code on the host in VS Code
- Run commands and tooling inside the VM
- Reliable file access and minimal friction

## Recommended Workflow: VS Code Remote - SSH
This provides the smoothest experience: code lives on the VM, VS Code UI runs on the host, the VS Code server runs in the VM. You get IntelliSense, terminal, debugging, and extensions in the VM context without file sync hassles.

### 1) Networking: Give the VM a reachable IP

Option A — Bridged networking (recommended)
- VM gets an IP on your LAN, easy to SSH into from host.
```bash path=null start=null
# Power off the VM first, then set bridged on adapter 1
VBoxManage modifyvm "<VM-NAME>" --nic1 bridged --bridgeadapter1 <HOST_IFACE>

# Example: using host interface enp0s31f6
VBoxManage modifyvm "fokin-iot" --nic1 bridged --bridgeadapter1 enp0s31f6
```

Option B — NAT + port forwarding (alternative)
- Keep NAT and forward host port 2222 → guest port 22.
```bash path=null start=null
# VM must be powered off to modify NAT rules
# Remove any existing rule named ssh (ignore errors if not present)
VBoxManage modifyvm "<VM-NAME>" --natpf1 delete ssh

# Add a new rule: host 127.0.0.1:2222 -> guest 22
VBoxManage modifyvm "<VM-NAME>" --natpf1 "ssh,tcp,127.0.0.1,2222,,22"

# Connect from host
ssh <user>@127.0.0.1 -p 2222
```

### 2) Ensure SSH server is installed in the guest

Ubuntu/Debian guest
```bash path=null start=null
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
# If UFW is enabled
sudo ufw allow ssh
```

RHEL/CentOS/Rocky guest
```bash path=null start=null
sudo dnf install -y openssh-server
sudo systemctl enable --now sshd
# If firewalld is enabled
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload
```

Verify SSH is listening
```bash path=null start=null
# Inside the VM
ss -tlnp | grep :22 || sudo netstat -tlnp | grep :22
```

### 3) SSH key authentication (recommended)
```bash path=null start=null
# On host (create a key if you don't have one)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy the key to the VM (bridged example)
ssh-copy-id <user>@<vm-ip>

# Or, for NAT forwarding on port 2222
ssh-copy-id -p 2222 <user>@127.0.0.1
```

### 4) Connect with VS Code Remote - SSH
1. Install the "Remote - SSH" extension in VS Code.
2. Press Ctrl+Shift+P → "Remote-SSH: Add New SSH Host…"
3. Enter one of:
   - Bridged: `<user>@<vm-ip>`
   - NAT PF: `ssh -p 2222 <user>@127.0.0.1`
4. Choose the SSH config file to save into (usually `~/.ssh/config`).
5. From the green corner button (><) or Command Palette, connect to the saved host.
6. VS Code will install its server on the VM automatically.

Tip: After connecting, use the built-in terminal in VS Code — commands run inside the VM.

---

## Alternative Workflows (when they make sense)

Shared Folders (VirtualBox)
- Edit on host; files appear inside VM via a mount.
- Pros: Simple, no network needed. Cons: Permissions/perf quirks on large repos.
```bash path=null start=null
# Add a shared folder (host path -> name) while VM is powered off
VBoxManage sharedfolder add "<VM-NAME>" --name host_iot --hostpath /home/<host-user>/git/iot --automount

# Inside the VM (if not auto-mounted), mount manually
sudo mkdir -p /mnt/host_iot
sudo mount -t vboxsf host_iot /mnt/host_iot
# Persist via /etc/fstab (ensure vboxsf module is available)
```

SSHFS (host mounts VM dir)
- Files live on the VM, edited from host.
- Pros: Real-time, no explicit sync. Cons: Latency, can be flaky.
```bash path=null start=null
sudo apt install -y sshfs   # on host
mkdir -p ~/mnt/vm
sshfs <user>@<vm-ip>:/path/on/vm ~/mnt/vm
# Unmount when done
fusermount -u ~/mnt/vm || umount ~/mnt/vm
```

Rsync/SCP
- One-way or scripted two-way sync.
- Pros: Fast, explicit. Cons: Not live; needs hooks or watchers.
```bash path=null start=null
# Push host -> VM
rsync -avz --delete ~/git/iot/ <user>@<vm-ip>:/home/<user>/iot/

# Pull VM -> host
rsync -avz --delete <user>@<vm-ip>:/home/<user>/iot/ ~/git/iot/
```

VS Code in Browser (code-server)
- Run code-server on VM, access in browser.
- Pros: No desktop VS Code needed. Cons: Extra service to manage.

---

## Troubleshooting
- Clipboard not working? See docs/virtualbox-clipboard-fix.md and ensure Guest Additions version matches host VirtualBox.
- Can’t SSH? Verify networking mode, that ssh/sshd service is running, and firewalls permit port 22.
- VS Code fails to connect? Check ~/.ssh/config entries, key permissions (600), and first connect via plain ssh to trust the host.
- Shared folder errors (vboxsf): Ensure Guest Additions installed and vboxsf module available.

---

## Appendix: Example commands used for fokin-iot
```bash path=null start=null
# Switch to bridged networking (host iface enp0s31f6)
VBoxManage modifyvm "fokin-iot" --nic1 bridged --bridgeadapter1 enp0s31f6

# Start VM headless
VBoxManage startvm "fokin-iot" --type headless

# Query VM IP after boot (requires Guest Additions)
VBoxManage guestproperty enumerate "fokin-iot" | grep "Net.*V4.*IP"

# Once SSH is available
ssh <user>@<vm-ip>
```

See also: docs/virtualbox-clipboard-fix.md

