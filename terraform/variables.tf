variable "aws_region" {
  description = "AWS region for the assessment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project resource naming prefix"
  type        = string
  default     = "startuptech"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "Trusted public IP address allowed to SSH to bastion"
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0)) && var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "Provide a trusted public IP in CIDR notation, such as 203.0.113.10/32."
  }
}

variable "key_name" {
  description = "Name of an existing EC2 key pair"
  type        = string
}
