# Vagrant Cheatsheet & Documentation

## What is Vagrant?

Vagrant is an open-source tool for building and managing virtual machine environments in a single workflow. It provides easy-to-configure, reproducible, and portable work environments built on top of industry-standard technology and controlled by a single consistent workflow.

---

## Installation

- **Install VirtualBox** (or another provider):  
  https://www.virtualbox.org/wiki/Downloads

- **Install Vagrant:**  
  https://www.vagrantup.com/downloads

---

## Basic Workflow

1. **Initialize a Vagrant environment:**
   ```
   vagrant init [box-name]
   ```
   Example:
   ```
   vagrant init ubuntu/bionic64
   ```

2. **Start and provision the VM:**
   ```
   vagrant up
   ```

3. **SSH into the VM:**
   ```
   vagrant ssh
   ```

4. **Suspend the VM:**
   ```
   vagrant suspend
   ```

5. **Halt (shutdown) the VM:**
   ```
   vagrant halt
   ```

6. **Destroy the VM:**
   ```
   vagrant destroy
   ```

---

## Vagrantfile Basics

- The `Vagrantfile` is the configuration file for your Vagrant environment.
- It uses Ruby syntax, but you don't need to know Ruby to use basic Vagrant features.
- The file describes how Vagrant should create and configure your virtual machine(s).

### Example minimal `Vagrantfile` and Explanation

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
end
```

**Explanation:**
- `Vagrant.configure("2") do |config| ... end`: This is the main block that sets up the configuration. The `"2"` is the configuration version (always use "2" for modern Vagrant).
- `config.vm.box = "ubuntu/bionic64"`: Specifies the base box image to use for the VM.

---

### Vagrantfile Syntax & Common Configuration Options

Below are common configuration options, each with an explanation:

- **Set VM box:**
  ```ruby
  config.vm.box = "ubuntu/bionic64"
  ```
  *Specifies the base image (box) to use for the VM.*

- **Forward ports:**
  ```ruby
  config.vm.network "forwarded_port", guest: 80, host: 8080
  ```
  *Forwards port 80 inside the VM to port 8080 on your host machine. Useful for accessing web servers running in the VM.*

- **Sync folders:**
  ```ruby
  config.vm.synced_folder "./host_folder", "/home/vagrant/guest_folder"
  ```
  *Syncs a folder from your host (`./host_folder`) to the guest VM (`/home/vagrant/guest_folder`).*

- **Provision with shell script:**
  ```ruby
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y nginx
  SHELL
  ```
  *Runs the given shell commands inside the VM after it is created. This is called "provisioning" and is used to automatically install software or configure the VM.*

---

#### More Vagrantfile Syntax Examples

- **Set a private network IP:**
  ```ruby
  config.vm.network "private_network", ip: "192.168.33.10"
  ```
  *Assigns a static private IP address to the VM.*

- **Use a shell script file for provisioning:**
  ```ruby
  config.vm.provision "shell", path: "setup.sh"
  ```
  *Runs the `setup.sh` script from your project directory inside the VM.*

- **Specify a provider (like VirtualBox):**
  ```ruby
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 2
  end
  ```
  *Customizes provider-specific settings, such as memory and CPU allocation for VirtualBox.*

---

---

## Useful Commands

| Command                        | Description                                 |
|--------------------------------|---------------------------------------------|
| `vagrant box list`             | List all downloaded boxes                   |
| `vagrant box add <box>`        | Download a box                              |
| `vagrant box remove <box>`     | Remove a box                                |
| `vagrant status`               | Show status of the VM                       |
| `vagrant reload`               | Restart VM and apply changes in Vagrantfile |
| `vagrant provision`            | Re-run the provisioning scripts             |
| `vagrant snapshot save <name>` | Save a VM snapshot                          |
| `vagrant snapshot restore <name>` | Restore a VM snapshot                    |

---

## Networking

- **Port Forwarding:**  
  Map a port from your host to the guest VM.
  ```ruby
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  ```

- **Private Network:**  
  Assign a private IP to the VM.
  ```ruby
  config.vm.network "private_network", ip: "192.168.33.10"
  ```

- **Public Network:**  
  Bridge the VM to your local network.
  ```ruby
  config.vm.network "public_network"
  ```

---

## Synced Folders

- By default, the folder with your `Vagrantfile` is synced to `/vagrant` in the VM.
- You can customize synced folders:
  ```ruby
  config.vm.synced_folder "./data", "/home/vagrant/data"
  ```

---

## Provisioning

- **Shell scripts:**  
  Run commands automatically on `vagrant up` or `vagrant provision`.
  ```ruby
  config.vm.provision "shell", path: "setup.sh"
  ```

- **Other provisioners:**  
  Vagrant supports Ansible, Chef, Puppet, Docker, etc.

---

## Boxes

- **Find boxes:**  
  https://app.vagrantup.com/boxes/search

- **Add a box manually:**
  ```
  vagrant box add ubuntu/bionic64
  ```

---

## Tips & Tricks

- **Update Vagrant boxes:**
  ```
  vagrant box update
  ```

- **Clean up unused boxes:**
  ```
  vagrant box prune
  ```

- **Force reload and provision:**
  ```
  vagrant reload --provision
  ```

- **Specify provider (e.g., VirtualBox, VMware):**
  ```
  vagrant up --provider=virtualbox
  ```

---

## Troubleshooting

- **Check VM status:**
  ```
  vagrant status
  ```

- **View VM logs:**
  ```
  vagrant up --debug
  ```

- **Remove and recreate environment:**
  ```
  vagrant destroy -f
  vagrant up
  ```

---

## References

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Vagrant Cloud Boxes](https://app.vagrantup.com/boxes/search)

---