packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "aws" {
  region        = "us-east-1"
  source_ami    = "ami-0b0ea68c435eb488d"
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"

  ami_name = "packer-app-{{timestamp}}"
}

build {
  sources = ["source.amazon-ebs.aws"]

  provisioner "shell" {
    inline = [
      "echo 'Provisioning minimal AWS build'",
      "sudo apt-get update -y"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
