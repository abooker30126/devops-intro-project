variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID from the Packer build (control-server)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m7i-flex.large"
}

variable "project_name" {
  description = "Name tag for all resources"
  type        = string
  default     = "control-server"
}

variable "environment" {
  description = "Deployment environment label"
  type        = string
  default     = "dev"
}

variable "key_name" {
  description = "Name for the AWS key pair"
  type        = string
  default     = "control-server-key"
}

variable "public_key" {
  description = "SSH public key material (contents of ~/.ssh/id_ed25519.pub)"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH — lock to your IP in production (e.g. [\"1.2.3.4/32\"])"
  type        = list(string)
}
