packer {
  required_version = ">= 1.9.0"

  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

############################################
# VARIABLES
############################################

variable "PACKER_BOX_NAME" {
  default = "ubuntu-22.04-server-amd64"
}

variable "AWS_ACCESS_KEY_ID" {
  type    = string
  default = env("AWS_ACCESS_KEY_ID")
}

variable "AWS_SECRET_ACCESS_KEY" {
  type    = string
  default = env("AWS_SECRET_ACCESS_KEY")
}

############################################
# AMAZON EBS BUILDER (ONLY BUILDER)
############################################

source "amazon-ebs" "aws" {
  region        = "us-east-1"
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"

  # Canonical Ubuntu 22.04 (Jammy) AMI filter
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }

  # AWS-safe timestamp (no colons)
  ami_name = "control-${var.PACKER_BOX_NAME}-${formatdate("YYYYMMDD-hhmmss", timestamp())}"

  tags = {
    Name = "control-${var.PACKER_BOX_NAME}"
  }
}

############################################
# BUILD + PROVISIONERS + MANIFEST
############################################

build {
  name = "control"

  sources = [
    "source.amazon-ebs.aws"
  ]

  provisioner "shell" {
    execute_command = "echo 'vagrant' | sudo -S -E bash '{{.Path}}'"
    scripts         = ["scripts/update.sh"]
  }

  provisioner "file" {
    source      = "jenkins-config"
    destination = "/tmp"
  }

  provisioner "shell" {
    execute_command = "echo 'vagrant' | sudo -S -E bash '{{.Path}}'"
    scripts = [
      "scripts/jenkins.sh",
      "scripts/graphite.sh",
      "scripts/nginx.sh",
      "scripts/cleanup.sh"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
