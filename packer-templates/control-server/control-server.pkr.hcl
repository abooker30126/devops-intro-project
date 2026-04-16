# ──────────────────────────────────────────────────────────────
# control-server.pkr.hcl
# Packer HCL2 template – AWS Ubuntu 22.04 Control Server AMI
# ──────────────────────────────────────────────────────────────

packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# ──────────────────────────────────────────────────────────────
# Variables
# ──────────────────────────────────────────────────────────────

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_prefix" {
  type    = string
  default = "control-server"
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

# ──────────────────────────────────────────────────────────────
# Locals
# ──────────────────────────────────────────────────────────────

locals {
  timestamp = formatdate("YYYYMMDD-HHmmss", timestamp())
  ami_name  = "${var.ami_prefix}-${local.timestamp}"
}

# ──────────────────────────────────────────────────────────────
# Source – Amazon EBS (Ubuntu 22.04 LTS)
# ──────────────────────────────────────────────────────────────

source "amazon-ebs" "control_server" {
  region        = var.aws_region
  instance_type = var.instance_type
  ami_name      = local.ami_name

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }

  vpc_id                      = var.vpc_id != "" ? var.vpc_id : null
  subnet_id                   = var.subnet_id != "" ? var.subnet_id : null
  associate_public_ip_address = true

  communicator = "ssh"
  ssh_username = var.ssh_username

  tags = {
    Name        = local.ami_name
    Environment = "production"
    OS          = "Ubuntu 22.04"
    ManagedBy   = "Packer"
    BuildTime   = local.timestamp
  }

  run_tags = {
    Name = "packer-builder-${var.ami_prefix}"
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }
}

# ──────────────────────────────────────────────────────────────
# Build – Provisioners (ordered correctly)
# ──────────────────────────────────────────────────────────────

build {
  name    = "control-server"
  sources = ["source.amazon-ebs.control_server"]

  # ═══════════════════════════════════════════════════════════
  # PHASE 1 — FILE PROVISIONERS (upload all files first)
  # ═══════════════════════════════════════════════════════════

  provisioner "file" {
    source      = "${path.root}/files/nginx/default.conf"
    destination = "/tmp/nginx-default.conf"
  }

  provisioner "file" {
    source      = "${path.root}/files/nginx/nginx.conf"
    destination = "/tmp/nginx.conf"
  }

  provisioner "file" {
    source      = "${path.root}/files/nginx/snippets/"
    destination = "/tmp/nginx-snippets"
  }

  provisioner "file" {
    source      = "${path.root}/files/app/"
    destination = "/tmp/app-config"
  }

  provisioner "file" {
    source      = "${path.root}/files/systemd/"
    destination = "/tmp/systemd-units"
  }

  provisioner "file" {
    source      = "${path.root}/files/scripts/"
    destination = "/tmp/scripts"
  }

  # ═══════════════════════════════════════════════════════════
  # PHASE 2 — System update & base packages
  # ═══════════════════════════════════════════════════════════

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "echo '>>> Phase 2: System update & base packages'",
      "sudo add-apt-repository -y universe",
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common wget unzip jq ssl-cert",
      "sudo mkdir -p /opt/app && sudo chown ${var.ssh_username}:${var.ssh_username} /opt/app"
    ]
  }

  # ═══════════════════════════════════════════════════════════
  # PHASE 3 — Install Nginx
  # ═══════════════════════════════════════════════════════════

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "echo '>>> Phase 3: Install Nginx'",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx"
    ]
  }

  # ═══════════════════════════════════════════════════════════
  # PHASE 4 — Deploy staged configs into final locations
  # ═══════════════════════════════════════════════════════════

  provisioner "shell" {
    inline = [
      "echo '>>> Phase 4: Deploy Nginx and app configuration'",
      "sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo cp /tmp/nginx-default.conf /etc/nginx/sites-available/default",
      "sudo mkdir -p /etc/nginx/snippets",
      "sudo cp -r /tmp/nginx-snippets/* /etc/nginx/snippets/ 2>/dev/null || true",
      "sudo mkdir -p /opt/app/config",
      "sudo cp -r /tmp/app-config/* /opt/app/config/ 2>/dev/null || true",
      "sudo cp /tmp/systemd-units/*.service /etc/systemd/system/ 2>/dev/null || true",
      "sudo systemctl daemon-reload",
      "sudo mkdir -p /opt/scripts",
      "sudo cp -r /tmp/scripts/* /opt/scripts/ 2>/dev/null || true",
      "sudo chmod +x /opt/scripts/*.sh 2>/dev/null || true",
      "sudo nginx -t"
    ]
  }

  # ═══════════════════════════════════════════════════════════
  # PHASE 5 — Install Docker, AWS CLI, SSM Agent, Jenkins
  # ═══════════════════════════════════════════════════════════

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "echo '>>> Phase 5a: Install Docker'",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ${var.ssh_username}"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '>>> Phase 5b: Install AWS CLI v2'",
      "curl -fsSL 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o '/tmp/awscliv2.zip'",
      "unzip -q /tmp/awscliv2.zip -d /tmp",
      "sudo /tmp/aws/install",
      "aws --version"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "echo '>>> Phase 5c: Install / enable SSM Agent'",
      "sudo snap install amazon-ssm-agent --classic || true",
      "sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service",
      "sudo systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service"
    ]
  }

  # ═══════════════════════════════════════════════════════════
  # PHASE 5d — Install Jenkins
  # ═══════════════════════════════════════════════════════════

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "echo '>>> Phase 5d: Install Jenkins'",

      "# Install Java 21 (Jenkins dependency)",
      "sudo apt-get install -y fontconfig openjdk-21-jre",

      "# Create Jenkins user and directories",
      "sudo useradd -r -s /bin/false -d /var/lib/jenkins jenkins",
      "sudo mkdir -p /var/lib/jenkins /var/log/jenkins /usr/share/java",
      "sudo chown jenkins:jenkins /var/lib/jenkins /var/log/jenkins",

      "# Download Jenkins WAR (GitHub mirror — CDN unreliable)",
      "sudo wget -q -O /usr/share/java/jenkins.war https://github.com/jenkinsci/jenkins/releases/download/jenkins-2.558/jenkins.war",
      "ls -lh /usr/share/java/jenkins.war",

      "# Create systemd service",
      "cat <<'UNIT' | sudo tee /etc/systemd/system/jenkins.service",
      "[Unit]",
      "Description=Jenkins Automation Server",
      "After=network.target",
      "",
      "[Service]",
      "Type=simple",
      "User=jenkins",
      "Environment=JENKINS_HOME=/var/lib/jenkins",
      "ExecStart=/usr/bin/java -jar /usr/share/java/jenkins.war --httpPort=8080",
      "Restart=on-failure",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "UNIT",

      "sudo systemctl daemon-reload",
      "sudo systemctl enable jenkins"
    ]
  }


  # ═══════════════════════════════════════════════════════════
  # PHASE 6 — Security hardening & cleanup
  # ═══════════════════════════════════════════════════════════
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "echo '>>> Phase 6: Hardening & cleanup'",
      "sudo sed -i 's/^#\\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sudo ufw allow 'Nginx Full'",
      "sudo ufw allow OpenSSH",
      "sudo ufw allow 8080/tcp", # ← NEW: Jenkins direct access
      "echo 'y' | sudo ufw enable",
      "sudo apt-get install -y unattended-upgrades",
      "sudo dpkg-reconfigure -f noninteractive unattended-upgrades",
      "sudo rm -rf /tmp/nginx-* /tmp/app-config /tmp/systemd-units /tmp/scripts /tmp/aws /tmp/awscliv2.zip",
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo cloud-init clean --logs",
      "echo '>>> Build complete!'"
    ]
  }

  # ═══════════════════════════════════════════════════════════
  # Post-processor – Manifest for CI/CD
  # ═══════════════════════════════════════════════════════════

  post-processor "manifest" {
    output     = "${path.root}/packer-manifest.json"
    strip_path = true
  }
}
