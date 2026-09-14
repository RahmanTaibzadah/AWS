variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for the WordPress server"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Ubuntu 24.04 LTS)"
  type        = string
  default     = "ami-025d99823a4caad37"
}

variable "key_name" {
  description = "Name of the existing EC2 key pair to use for SSH access"
  type        = string
  default     = "vpc-key"
}
