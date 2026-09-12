# Assignment 1 \- VPC & Networking

## What I Built

A custom AWS network built from scratch, with a public and private subnet, correct routing for internet access, and EC2 instances deployed in each, proving proper network segmentation.

### Architecture

Internet

   |

Internet Gateway

   |

Public Subnet (10.0.1.0/24) \- public-ec2 (public IP)

   |

   |— NAT Gateway (in public subnet, using an Elastic IP)

   |

Private Subnet (10.0.2.0/24) \- private-ec2 (no public IP)

All of this sits inside a custom VPC: `10.0.0.0/16`.

## Steps Taken

### 1\. Secured the AWS account

- Confirmed MFA was enabled on the root account.  
- Created an IAM admin user for day-to-day work instead of using root.

### 2\. Created the VPC

- Custom VPC, CIDR `10.0.0.0/16`.

### 3\. Created two subnets

- `public-subnet` \- `10.0.1.0/24`, AZ `us-east-1a`.  
- `private-subnet` \- `10.0.2.0/24`, AZ `us-east-1a`.

### 4\. Set up internet access

- Created an Internet Gateway and attached it to the VPC.  
- Allocated an Elastic IP.  
- Created a NAT Gateway in the public subnet, using that Elastic IP, this is what lets the private subnet reach the internet (e.g. for updates) without being directly reachable from it.

### 5\. Configured routing

- `public-rt`: route `0.0.0.0/0` \-\> Internet Gateway. Associated with `public-subnet`.  
- `private-rt`: route `0.0.0.0/0` \-\> NAT Gateway. Associated with `private-subnet`.

### 6\. Launched EC2 instances

- `public-ec2`: launched in `public-subnet`, auto-assign public IP enabled. Security group (`public-ec2-sg`) allows SSH (port 22\) from my IP only, and HTTP (port 80\) from anywhere.  
- `private-ec2`: launched in `private-subnet`, auto-assign public IP **disabled**. Security group (`private-ec2-sg`) allows SSH (port 22\) only from `public-ec2-sg` meaning only the public instance can reach it, nothing from the internet.

### 7\. Tested connectivity

- SSH'd from my Mac into `public-ec2` using its public IP confirmed reachable from the internet.  
- Copied my key onto `public-ec2`, then SSH'd from *inside* `public-ec2` into `private-ec2` using its private IP confirmed the private instance is reachable only from inside the VPC, not directly from the internet.

## What I Learnt

- The difference between a VPC's CIDR range (e.g. `/16`) and a subnet's CIDR range (e.g. `/24`) the VPC is the whole address space, subnets are smaller slices carved out of it.  
- Why a NAT Gateway needs to live in the **public** subnet even though its job is to serve the private subnet, it needs its own route to the internet via the Internet Gateway to forward traffic on behalf of private instances.  
- How route tables control traffic direction per subnet — a subnet is only "public" or "private" because of which route table it's associated with, not anything inherent about the subnet itself.  
- Security groups are stateful and reference-based — you can set a security group's source to be *another security group* rather than an IP range, which is how you restrict private instance access to only the public instance rather than any external IP.  
- The difference between an EC2 instance's public IP, private IP, and private DNS name, and when each is used.

## Challenges and How I Solved Them

- **VPC defaulted to the account's default VPC** when launching EC2 instances instead of my custom `networking-vpc` — had to explicitly select the right VPC and subnet each time in Network Settings rather than trusting the default.  
- **SSH kept failing with "Permission denied (publickey)"** on both EC2 instances — traced this back to the instances being launched with an old key pair (`network-key`) that didn't match the `.pem` file I actually had. Fixed by creating a fresh key pair (`vpc-key`), and relaunching both instances with the correct key selected.  
- **Accidentally tried to create a duplicate security group** with the same name as an existing one, which failed the instance launch — fixed by selecting "Select existing security group" instead of "Create security group" when relaunching.  
- **Tried to SSH into the private EC2 directly from my Mac** using its private IP, which just hung indefinitely — private IPs are only reachable from inside the VPC, so I had to SSH into the public EC2 first, copy my key onto it, and SSH into the private instance from there.  
- **Ended up with two unused Elastic IPs** after switching the NAT Gateway's EIP allocation method from Automatic to Manual — released the unattached one afterward to avoid unnecessary charges.

