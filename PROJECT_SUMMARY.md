# Inception-of-Things (IoT) Project Summary

## General Guidelines
- All work must be done in virtual machines.
- Organize your repository with folders at the root: `p1`, `p2`, `p3` (mandatory), and `bonus` (optional).
- Place scripts in a `scripts` folder and configuration files in a `confs` folder within each part.

---

## Mandatory Parts

### Part 1: K3s and Vagrant (`p1`)
- Set up 2 Vagrant-managed VMs with minimal resources (1 CPU, 512–1024 MB RAM).
- Name VMs as `<login>S` (Server) and `<login>SW` (ServerWorker).
- Assign static IPs: Server (192.168.56.110), ServerWorker (192.168.56.111) on `eth1`.
- Enable passwordless SSH access.
- Install K3s: Server in controller mode, ServerWorker in agent mode.
- Install and configure `kubectl`.

### Part 2: K3s and Three Simple Applications (`p2`)
- Use one VM with K3s in server mode.
- Deploy 3 web applications of your choice in K3s.
- Use Ingress to route based on the `HOST` header:
  - `app1.com` → app1
  - `app2.com` → app2 (with 3 replicas)
  - Any other host → app3 (default)
- All apps must be accessible via 192.168.56.110.

### Part 3: K3d and Argo CD (`p3`)
- Install K3d (requires Docker) on a VM (no Vagrant).
- Write a script to install all required packages/tools.
- Create two namespaces: `argocd` (for Argo CD) and `dev` (for your app).
- Set up Argo CD to automatically deploy an application from your public GitHub repository.
- The app must have two versions (v1, v2) and be available as a public Docker image (use Wil’s or your own).
- Demonstrate updating the app version via GitHub and Argo CD sync.

---

## Bonus Part (`bonus`)
- Add a local GitLab instance to the setup in Part 3.
- Create a `gitlab` namespace.
- Integrate GitLab with your cluster and ensure everything from Part 3 works with GitLab.
- Only evaluated if the mandatory part is perfect.

---

## Submission
- Submit your work in a Git repository with the required folder structure.
- Only the contents of your repository will be evaluated.
