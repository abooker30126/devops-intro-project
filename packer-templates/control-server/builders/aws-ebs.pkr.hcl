source "amazon-ebs" "control" {
  region                      = var.aws_region
  instance_type               = var.instance_type
  ssh_username                = var.ssh_username
  associate_public_ip_address = true

  vpc_id            = var.vpc_id != "" ? var.vpc_id : null
  subnet_id         = var.subnet_id != "" ? var.subnet_id : null
  security_group_id = var.security_group_id != "" ? var.security_group_id : null

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  ami_name        = "${var.ami_name_prefix}-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
  ami_description = var.ami_description

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = var.ami_volume_size
    volume_type           = var.ami_volume_type
    delete_on_termination = true
  }

  tags = {
    Name      = var.ami_name_prefix
    Role      = "control"
    OS        = "ubuntu-22.04"
    ManagedBy = "packer"
  }

  run_tags = {
    Name      = "${var.ami_name_prefix}-build"
    ManagedBy = "packer"
  }
}
