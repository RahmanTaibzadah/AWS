# Networking Assignment — Domain \+ EC2 \+ NGINX \+ DNS

## What I Built

A live website reachable at **nginx.rahmantaibzadah.co.uk**, served by NGINX running on an AWS EC2 instance, with DNS pointing my custom domain at the server's public IP.

This ties together the core networking concepts from the module: IP addressing, DNS resolution, routing, ports, and firewalls (security groups).

### Architecture

Browser  \-\>  DNS (Cloudflare A record)  \-\>  EC2 Public IP  \-\>  NGINX (port 80\)

## Steps Taken

### 1\. Bought a domain

Registered `rahmantaibzadah.co.uk` through Cloudflare.

### 2\. Launched an EC2 instance

- AMI: Ubuntu Server 24.04 LTS (HVM), SSD Volume Type  
- Instance type: t2.micro (free tier)  
- Created a new key pair (`network-key.pem`) for SSH access  
- Security group: allowed inbound SSH (port 22\) and HTTP (port 80\)

### 3\. Installed and ran NGINX

Connected via SSH:

ssh \-i "network-key.pem" ubuntu@\<ec2-public-dns\>

Installed and started NGINX:

sudo apt update

sudo apt install \-y nginx

sudo systemctl enable nginx

sudo systemctl start nginx

sudo systemctl status nginx

Confirmed it was reachable by visiting `http://<EC2_PUBLIC_IP>` directly showed the default NGINX welcome page.

### 4\. Configured DNS

In Cloudflare, added an A record:

| Name | Type | Content | Proxy status |
| :---- | :---- | :---- | :---- |
| nginx | A | 16.171.29.21 (EC2 public IP) | DNS only |

Set to **DNS only** (not proxied) so I was testing the raw connection to my own server rather than Cloudflare's proxy.

### 5\. Tested end to end

Visited `http://nginx.rahmantaibzadah.co.uk` in a browser, it resolved through DNS to the EC2 instance and loaded the NGINX welcome page.

## Screenshots

**EC2 instance running:** ![EC2 instance]()

**DNS A record in Cloudflare:** ![DNS record]()

**NGINX loading via my domain:** ![NGINX welcome page]()

## What I Learnt

- How DNS A records map a human-readable domain to a machine's IP address, and how propagation works.  
- Why security groups (AWS's firewall) need explicit inbound rules, NGINX can be running perfectly and still be unreachable if port 80 isn't opened.  
- The difference between an EC2 instance's **Public DNS** (used for SSH) and its **Public IPv4 address** (used for the A record).  
- That GitHub no longer accepts account passwords for git operations over HTTPS, you need a Personal Access Token instead.  
- Cloudflare's proxy ("orange cloud") sits in front of your server and can mask whether your DNS record is actually correct, switching to "DNS only" (grey cloud) was important for testing the raw connection first.

## Challenges and How I Solved Them

- **Picked the wrong AMI at first** — accidentally selected an Ubuntu image bundled with SQL Server. Fixed by searching the AMI catalog directly for "Ubuntu Server 24.04" to get the plain image.  
- **Ran commands inside the EC2 SSH session by mistake** instead of on my local machine when trying to clone my GitHub repo, realised the shell prompt (`ubuntu@ip-...`) was different from my local prompt, and used `exit` to get back to my Mac.  
- **GitHub password prompt didn't work,** GitHub requires a Personal Access Token instead of an account password for git over HTTPS, especially since I signed up via Google and had no traditional password. Generated a token under Developer Settings  Personal access tokens and used that instead.  
- **DNS record defaulted to "Proxied"** had to edit the A record and switch it to "DNS only" so I could test the direct connection to my EC2 instance without Cloudflare's proxy layer in the way.

