# RAMUP Installation Guides — Every Cloud Provider

Complete step-by-step tutorials for creating a VPS and installing RAMUP on every major cloud provider.

## Table of Contents

- [VPS Providers (SSH)](#vps-providers)
  - [DigitalOcean](#digitalocean) · [Vultr](#vultr) · [Hetzner](#hetzner) · [Linode](#linode--akamai)
  - [AWS EC2](#aws-ec2) · [Google Cloud](#google-cloud-gcp) · [Oracle Cloud](#oracle-cloud) · [Azure](#microsoft-azure)
  - [Contabo](#contabo) · [Alibaba Cloud](#alibaba-cloud-ecs) · [Scaleway](#scaleway) · [UpCloud](#upcloud)
  - [OVHcloud](#ovhcloud) · [Hostinger](#hostinger) · [Kamatera](#kamatera) · [CloudSigma](#cloudsigma)
  - [InterServer](#interserver) · [RackNerd](#racknerd) · [A2 Hosting](#a2-hosting) · [DreamHost](#dreamhost)
- [PaaS Providers (Docker)](#paas-providers)
  - [Render](#render) · [Railway](#railway) · [Fly.io](#flyio) · [Koyeb](#koyeb) · [Heroku](#heroku)
  - [DO App Platform](#digitalocean-app-platform) · [Cloud Run](#google-cloud-run) · [App Runner](#aws-app-runner)
  - [Azure Container Instances](#azure-container-instances) · [Modal](#modal)

---

# VPS Providers

## DigitalOcean

### Step 1: Create a Droplet
1. Go to [digitalocean.com](https://www.digitalocean.com/) → sign up / log in
2. Click **"Create"** → **"Droplets"**
3. Choose a region (pick closest to your users)
4. Choose image: **Ubuntu 22.04 LTS**
5. Choose plan: **$6/mo** (1GB RAM) recommended
6. Authentication: **SSH Key** (recommended) or Password
7. Click **"Create Droplet"** → wait ~30 seconds

### Step 2: Connect
```bash
ssh root@your-droplet-ip
```

### Step 3: Install
```bash
curl -sL ramup.io/install | bash
```

### Step 4: Verify
```bash
ramup status
```

---

## Vultr

### Step 1: Create an Instance
1. Go to [vultr.com](https://www.vultr.com/) → sign up / log in
2. Click **"+"** → **"Deploy New Instance"**
3. Type: **Cloud Compute - Shared CPU**
4. Location: pick closest
5. Image: **Ubuntu 22.04 LTS**
6. Plan: **$5/mo** (1GB RAM, 25GB NVMe)
7. Add SSH key or set password
8. Click **"Deploy Now"** → wait ~1 minute

### Step 2-4: Same as DigitalOcean
```bash
ssh root@your-vultr-ip
curl -sL ramup.io/install | bash
ramup status
```

---

## Hetzner

### Step 1: Create a Server
1. Go to [hetzner.com/cloud](https://www.hetzner.com/cloud) → sign up
2. Click **"New Project"** → **"Add Server"**
3. Location: Falkenstein or Helsinki (EU) or Ashburn (US)
4. Image: **Ubuntu 22.04**
5. Type: **CX22** (2GB RAM, €3.29/mo) — best value in Europe
6. Add SSH key
7. Click **"Create & Buy Now"**

### Step 2-4:
```bash
ssh root@your-hetzner-ip
curl -sL ramup.io/install | bash
ramup status
```

---

## Linode / Akamai

### Step 1: Create a Linode
1. Go to [linode.com](https://www.linode.com/) → sign up
2. Click **"Create"** → **"Linode"**
3. Location: pick closest
4. Image: **Ubuntu 22.04 LTS**
5. Plan: **Nanode 1GB** ($5/mo)
6. Set password or add SSH key
7. Click **"Create Linode"**

### Step 2-4:
```bash
ssh root@your-linode-ip
curl -sL ramup.io/install | bash
ramup status
```

---

## AWS EC2

### Step 1: Launch an Instance
1. Go to [console.aws.amazon.com](https://console.aws.amazon.com/) → search **"EC2"**
2. Click **"Launch Instance"**
3. Name: `ramup-test`
4. AMI: **Ubuntu Server 22.04 LTS** (free tier eligible)
5. Instance type: **t2.micro** (1GB, free 12 months) or **t4g.micro** (ARM, better)
6. Key pair: create new → **download the .pem file!**
7. Network: **Allow SSH traffic** from your IP
8. Click **"Launch Instance"**

### Step 2: Set Key Permissions
```bash
chmod 400 your-key.pem
```

### Step 3: Connect
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### Step 4: Install
```bash
sudo bash -c "$(curl -sL ramup.io/install)"
ramup status
```

**Tip:** Use gp3 EBS volumes for faster swap.

---

## Google Cloud (GCP)

### Step 1: Create a VM
1. Go to [console.cloud.google.com](https://console.cloud.google.com/) → **Compute Engine** → **VM instances**
2. Click **"Create Instance"**
3. Name: `ramup-test`
4. Region: closest to you
5. Machine type: **e2-micro** (1GB, free forever)
6. Boot disk: **Ubuntu 22.04 LTS**
7. Click **"Create"**

### Step 2: Connect
Click **"SSH"** button next to your instance, OR:
```bash
gcloud compute ssh ramup-test --zone=your-zone
```

### Step 3-4:
```bash
curl -sL ramup.io/install | bash
ramup status
```

---

## Oracle Cloud

### Step 1: Create an Instance
1. Go to [cloud.oracle.com](https://www.cloud.oracle.com/) → sign up (free!)
2. **Compute** → **Instances** → **"Create Instance"**
3. Image: **Ubuntu 22.04**
4. Shape: **VM.Standard.A1.Flex** (4 cores, 24GB RAM — Always Free!)
5. Add SSH public key
6. Click **"Create"**

### Step 2-4:
```bash
ssh -i your-key ubuntu@your-oracle-ip
curl -sL ramup.io/install | bash
ramup status
```

**Best free tier ever!** 4 ARM cores + 24GB RAM, forever free.

---

## Microsoft Azure

### Step 1: Create a VM
1. Go to [portal.azure.com](https://portal.azure.com/) → search **"Virtual machines"**
2. Click **"Create"** → **"Azure Virtual Machine"**
3. Name: `ramup-test`
4. Image: **Ubuntu Server 22.04 LTS**
5. Size: **Standard_B1s** (1GB, free tier eligible)
6. Authentication: SSH key or password
7. Inbound: **Allow SSH (22)**
8. Click **"Review + Create"** → **"Create"**

### Step 2-4:
```bash
ssh azureuser@your-azure-ip
sudo bash -c "$(curl -sL ramup.io/install)"
ramup status
```

---

## Contabo
```bash
# 1. Order at contabo.com → VPS S (4GB, €4.99/mo)
# 2. SSH in:
ssh root@your-contabo-ip
# 3. Install:
curl -sL ramup.io/install | bash
ramup status
```

## Alibaba Cloud (ECS)
```bash
# 1. Create ECS at alibabacloud.com → Ubuntu 22.04 → ESSD storage
# 2. SSH in:
ssh root@your-alibaba-ip
# 3. Install:
curl -sL ramup.io/install | bash
ramup status
```

## Scaleway
```bash
# 1. Create at scaleway.com → DEV1-S (4GB, €7.99/mo)
ssh root@your-scaleway-ip
curl -sL ramup.io/install | bash
ramup status
```

## UpCloud
```bash
# 1. Create at upcloud.com → 1GB plan (€7/mo)
ssh root@your-upcloud-ip
curl -sL ramup.io/install | bash
ramup status
```

## OVHcloud
```bash
# 1. Order at ovhcloud.com → Starter VPS (€3.50/mo)
ssh root@your-ovh-ip
curl -sL ramup.io/install | bash
ramup status
```

## Hostinger
```bash
# 1. Order at hostinger.com/vps → KVM 1 ($5.99/mo)
ssh root@your-hostinger-ip
curl -sL ramup.io/install | bash
ramup status
```

## Kamatera
```bash
# 1. Create at kamatera.com (30-day free trial!)
ssh root@your-kamatera-ip
curl -sL ramup.io/install | bash
ramup status
```

## CloudSigma
```bash
# 1. Create at cloudsigma.com → Ubuntu 22.04
ssh root@your-cloudsigma-ip
curl -sL ramup.io/install | bash
ramup status
```

## InterServer
```bash
# 1. Order at interserver.net → 1GB VPS ($6/mo, price-locked forever)
ssh root@your-interserver-ip
curl -sL ramup.io/install | bash
ramup status
```

## RackNerd
```bash
# 1. Order at racknerd.com → deals as low as $10/year!
ssh root@your-racknerd-ip
curl -sL ramup.io/install | bash
ramup status
```

## A2 Hosting
```bash
# 1. Order at a2hosting.com → Runway 1 ($6.99/mo)
ssh root@your-a2-ip
curl -sL ramup.io/install | bash
ramup status
```

## DreamHost
```bash
# 1. Order at dreamhost.com → VPS Basic ($10/mo)
ssh root@your-dreamhost-ip
curl -sL ramup.io/install | bash
ramup status
```

---

# PaaS Providers

For PaaS (no SSH), build RAMUP into your Docker image:

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl
RUN curl -sL ramup.io/install | bash
COPY . /app
WORKDIR /app
CMD ["./start.sh"]
```

## Render
1. Go to [render.com](https://render.com/) → sign up with GitHub
2. **"New"** → **"Web Service"** → connect your repo
3. Runtime: **Docker** → Instance type: Free or Starter ($7/mo)
4. Click **"Create Web Service"**

## Railway
1. Go to [railway.app](https://railway.app/) → sign up with GitHub
2. **"New Project"** → **"Deploy from GitHub Repo"**
3. Select repo → Railway auto-detects Dockerfile → deploys

## Fly.io
```bash
curl -L https://fly.io/install.sh | sh
fly auth login
fly launch
fly deploy
```

## Koyeb
1. Go to [koyeb.com](https://www.koyeb.com/) → sign up
2. **"Create App"** → **"Docker"** → enter repo URL
3. Instance: Nano (free) → **"Deploy"**

## Heroku
```bash
curl https://cli-assets.heroku.com/install.sh | sh
heroku login
heroku create my-app
git push heroku main
```

## DigitalOcean App Platform
1. [cloud.digitalocean.com](https://cloud.digitalocean.com/) → **Apps** → **"Create App"**
2. Connect GitHub → Dockerfile → **"Launch App"**

## Google Cloud Run
```bash
gcloud builds submit --tag gcr.io/PROJECT/app
gcloud run deploy app --image gcr.io/PROJECT/app --memory 512Mi
```

## AWS App Runner
1. AWS Console → **App Runner** → **"Create service"**
2. Source: GitHub → Dockerfile → **"Create & deploy"**

## Azure Container Instances
1. Azure Portal → **Container Instances** → **"Create"**
2. Image: your Docker image → Linux → 1 CPU, 1GB → **"Create"**

## Modal
```bash
pip install modal
modal setup
# Create app.py with modal.Image.from_dockerfile("Dockerfile")
modal deploy app.py
```

---

# Free Tier Cheat Sheet

| Provider | Free Offering | RAM | With RAMUP |
|----------|--------------|-----|-----------|
| Oracle Cloud | Always Free | 24GB ARM / 1GB AMD | 24GB / ~4.2GB |
| AWS | 12 months | 1GB (t2.micro) | ~4.2GB |
| GCP | Forever | 1GB (e2-micro) | ~4.2GB |
| Azure | 12 months | 1GB (B1s) | ~4.2GB |
| Vultr | $250 credit / 30 days | Any | Any |
| Hetzner | €20 credit | Any | Any |
