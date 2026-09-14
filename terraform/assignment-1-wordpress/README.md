# Terraform Assignment 1 \- Deploy WordPress Using Terraform

## What I Built

A fully working WordPress site, provisioned entirely through Terraform, no manual server setup. Running `terraform apply` creates a security group and an EC2 instance, and the instance automatically installs and configures Apache, MySQL, PHP, and WordPress itself on boot via a user data script.

## How My Terraform Code Is Structured

- **`main.tf`** \- the core configuration:  
  - AWS provider block (region set via variable)  
  - `aws_security_group.wordpress_sg` \- allows HTTP (80), HTTPS (443), and SSH (22)  
  - `aws_instance.wordpress` \- the EC2 instance itself, referencing the security group and using a `user_data` heredoc script to install and configure the full WordPress stack automatically  
- **`variables.tf`** \- all the configurable inputs, each with a sensible default so the project runs out of the box:  
  - `aws_region`, `instance_type`, `ami_id`, `key_name`  
- **`outputs.tf`** \- prints the useful details after deployment:  
  - `instance_id`, `public_ip`, `wordpress_url` (a ready-to-click link built from the public IP)

### The user data script does the following on first boot:

1. Updates packages and installs Apache, MySQL, PHP, and the PHP-MySQL connector  
2. Starts and enables both Apache and MySQL  
3. Creates a MySQL database and user for WordPress  
4. Downloads and extracts the latest WordPress release  
5. Copies WordPress into Apache's web root and sets correct file ownership  
6. Configures `wp-config.php` with the database credentials  
7. Restarts Apache to serve the site

## What I Learnt

- **Terraform's core workflow**: `init` \-\> `plan` \-\> `apply`. `init` downloads the provider plugins and sets up the working directory; `plan` is a dry run that shows exactly what will change before anything happens; `apply` actually creates the resources. Getting used to always reviewing `plan` output before `apply` felt like a genuinely important habit, not just a formality.  
- **Variables make configuration reusable** \- pulling the AMI ID, instance type, and key name out of `main.tf` into `variables.tf` means the same code could be redeployed with different settings without touching the core logic.  
- **Outputs give you immediate feedback** \- rather than going to the AWS console to find the instance's public IP after deployment, `terraform apply` prints it directly, along with a ready WordPress URL.  
- **AMI IDs are not stable long-term identifiers** \- they're specific to a region and get replaced as Canonical (Ubuntu's publisher) releases updated images. Hardcoding one you found somewhere online can silently stop working. AWS's SSM Parameter Store (`/aws/service/canonical/ubuntu/...`) is a more reliable way to always get the current AMI ID for a given Ubuntu version.  
- **`terraform apply`'s confirmation step is a genuine safety net** \- since it shows the full plan one more time and requires typing `yes`, it stops you from accidentally deploying something you didn't mean to.

## Challenges and How I Solved Them

- **Pasted an AWS Access Key/Secret directly into a chat while getting help** \- realized this was a security risk (any exposed credential should be treated as compromised) and rotated it immediately: deleted the exposed key in IAM and generated a fresh one, then configured the AWS CLI with the new one instead.  
- **`terraform init` and `terraform plan` kept getting interrupted mid-run**, pasting multi-line commands into the terminal occasionally sent stray control characters (like accidental Ctrl+C signals) that killed the process partway through. Fixed by opening a fresh terminal window and running commands one at a time, waiting for each to fully finish before typing the next.  
- **`terraform apply` failed with "InvalidParameterCombination: The specified instance type is not eligible for Free Tier"**, this account's free tier is tied to `t3.micro`, not `t2.micro` as I'd originally set. Updated `variables.tf` to use `t3.micro` instead.  
- **The AMI ID I'd hardcoded didn't exist**, running an `aws ec2 describe-images` lookup for a fresh Ubuntu 24.04 AMI kept returning `None` with a few different filter attempts. Solved it by querying AWS's official SSM parameter for Canonical's current Ubuntu 24.04 AMI instead, which reliably returns a valid, up-to-date AMI ID for the region.  
- **The WordPress site didn't load immediately after `terraform apply` finished**, the EC2 instance itself comes up quickly, but the user data script (installing Apache, MySQL, PHP, downloading WordPress) takes a minute or two to actually finish running in the background. Waiting roughly a minute before visiting the public IP resolved it.

