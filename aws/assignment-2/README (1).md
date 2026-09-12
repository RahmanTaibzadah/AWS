# Assignment 2 \- Application Load Balancer

## What I Built

Two EC2 instances running NGINX, sitting behind an Application Load Balancer (ALB), with traffic split evenly between them. The EC2 instances aren't reachable directly from the internet \- only through the ALB.

This builds on the VPC from Assignment 1, reusing the existing `networking-vpc` and public subnet, plus a second public subnet in a different Availability Zone.

### Architecture

Internet

   |

ALB (web-alb) — public-subnet (us-east-1a) \+ public-subnet-2 (us-east-1b)

   |

Target Group (web-tg) — health checks on "/"

   |

   |—— web-server-1 (us-east-1a)

   |—— web-server-2 (us-east-1b)

## Steps Taken

### 1\. Added a second public subnet

Created `public-subnet-2` (`10.0.3.0/24`) in `us-east-1b`, since an ALB requires subnets in at least two Availability Zones. Associated it with the existing `public-rt` route table so it routes through the Internet Gateway like the original public subnet.

### 2\. Launched two EC2 instances

- `web-server-1` in `public-subnet` (us-east-1a).  
- `web-server-2` in `public-subnet-2` (us-east-1b).

Both used the same key pair and were bootstrapped via EC2 user data to install and configure NGINX automatically on launch:

\#\!/bin/bash

apt update \-y

apt install \-y nginx

echo "\<h1\>Hello from Web Server 1\</h1\>" \> /var/www/html/index.html

systemctl enable nginx

systemctl start nginx

(Web Server 2 used the same script with its own message, so I could visually confirm which instance was responding.)

### 3\. Created the security groups

- `web-server-sg`: attached to both EC2 instances. Allows HTTP (port 80\) only from `alb-sg:` not from the internet directly.  
- `alb-sg`: attached to the ALB. Allows HTTP (port 80\) from anywhere, since this is the public-facing entry point.

### 4\. Created the Target Group

`web-tg` \- HTTP, port 80, health check path `/`. Registered both EC2 instances as targets.

### 5\. Created the ALB

`web-alb` \- Internet-facing, spanning both public subnets across the two Availability Zones. HTTP:80 listener forwarding to `web-tg`.

### 6\. Tested

Visited the ALB's DNS name in a browser and refreshed repeatedly, the response alternated between "Hello from Web Server 1" and "Hello from Web Server 2," confirming the ALB was distributing traffic across both instances. Confirmed both targets showed as "Healthy" in the target group.

## What I Learnt

- An ALB needs subnets in **at least two Availability Zones,** a single-AZ VPC setup (like the one from Assignment 1\) isn't enough on its own.  
- How target group health checks work, an EC2 instance can be running perfectly, but if its security group doesn't allow traffic from the ALB's security group, the target group will mark it "Unhealthy" and the ALB won't send it traffic.  
- Security groups can be swapped on a running EC2 instance without relaunching it  useful for fixing misconfigurations without starting over.  
- EC2 **user data** scripts let you fully configure an instance (install packages, write files, start services) automatically at launch, rather than SSHing in manually afterward.  
- The difference between a target group being "associated" with a load balancer (which only happens once the ALB itself is created and pointed at it) versus the target group just existing on its own.

## Challenges and How I Solved Them

- **Accidentally started building a brand new VPC** when trying to create a second subnet, instead of adding a subnet to the existing `networking-vpc,` caught this before proceeding, and used the plain "Create subnet" screen instead of the "Create VPC" wizard.  
- **New EC2 instances kept defaulting to the account's default VPC** instead of `networking-vpc` had to manually reselect the correct VPC and subnet each time in Network Settings rather than trusting the pre-filled default.  
- **Target group showed 0 registered targets** after creation the instances hadn't actually been registered during the wizard. Fixed by using "Register targets" directly on the target group page afterward.  
- **Both targets showed "Unhealthy"** even after registering them, traced this back to `web-server-sg` not allowing inbound HTTP from the ALB's security group. Added a rule allowing HTTP from `alb-sg` specifically (not from "Anywhere"), which fixed it.  
- **One target stayed unhealthy after the first fix** turned out `web-server-2` had been left with `private-ec2-sg` attached (left over from Assignment 1\) instead of `web-server-sg`. Fixed by changing its security group directly from the instance's Security tab.

