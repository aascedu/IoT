# Inception-of-Things (IoT)

![42 School](https://img.shields.io/badge/School%20project-000000?style=for-the-badge&logo=42&logoColor=white)
![Vagrant](https://img.shields.io/badge/Vagrant-1868F2?style=for-the-badge&logo=vagrant&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)

![K3s](https://img.shields.io/badge/K3s-FFC61C?style=for-the-badge&logo=k3s&logoColor=black)
![K3d](https://img.shields.io/badge/K3d-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![VirtualBox](https://img.shields.io/badge/VirtualBox-183A61?style=for-the-badge&logo=virtualbox&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo_CD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)
![GitLab](https://img.shields.io/badge/GitLab-FC6D26?style=for-the-badge&logo=gitlab&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

> 42 School project: Kubernetes from zero to GitOps

## 🎯 Overview

This 42 school project guides you through setting up a multi-node Kubernetes cluster using K3s on Vagrant-managed VMs, deploying multiple web applications with Ingress routing, and automating deployments with K3d and Argo CD. The bonus part involves integrating a self-hosted GitLab instance for a complete DevOps pipeline.

**Project deliverables:**
- 🖥️ Multi-node K3s cluster (Vagrant)
- 🌐 Multi-app deployment with Ingress routing
- 🔄 GitOps auto-deploy with Argo CD
- 🏆 Self-hosted GitLab integration (bonus)
## 📦 Project Parts

| Part | Goal | Tech |
|------|------|------|
| **P1** | First Kubernetes cluster | Vagrant + K3s + 2 VMs |
| **P2** | Deploy 3 apps with routing | K3s + Ingress |
| **P3** | Auto-deploy from Git | K3d + Argo CD  |
| **Bonus** | Full DevOps pipeline | GitLab + CI/CD |

## 📋 Quick Nav

- [Requirements](#-requirements)
- [Structure](#-structure)
- [Getting Started](#-getting-started)
- [Docs](#-documentation)

## ⚙️ Requirements

- VirtualBox, Vagrant, Docker
- 4GB RAM, 20GB disk
- Basic CLI knowledge

## 🗂️ Structure

```
p1/     → 2-node K3s cluster
p2/     → Apps + Ingress routing
p3/     → K3d + Argo CD automation
bonus/  → GitLab CI/CD
docs/   → Guides & cheatsheets
```

## 🚀 Getting Started

```bash
# Part 1
cd p1
vagrant up

# Part 2
cd p2
vagrant up

# Part 3
cd p3
./scripts/setup.sh

# Bonus
cd bonus
./scripts/setup.sh
```

## 📚 Documentation

Additional documentation can be found in the `docs/` directory:

- [Vagrant Cheatsheet](docs/vagrant-cheatsheet.md)
- [VirtualBox Clipboard Fix](docs/virtualbox-clipboard-fix.md)
- [VM Development Setup](docs/vm-dev-setup.md)

## 📄 License

This project is part of the 42 School curriculum.

---

**Note:** All work must be done in virtual machines. Ensure you have sufficient system resources before starting.
