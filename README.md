# DevSecOps Control Server — Infrastructure as Code

Immutable AWS infrastructure using **Packer** for AMI builds and **Terraform** for deployment. Builds a hardened Ubuntu 22.04 control server with Nginx, Docker, Jenkins, AWS CLI, and SSM Agent baked into the image.

---

## Architecture

┌─────────────┐      ┌──────────────┐      ┌────────────────────┐
│  Packer      │─────▶│  AMI         │─────▶│  EC2 Instance      │
│  (build AMI) │      │  (snapshot)  │      │  (Terraform deploy)│
└─────────────┘      └──────────────┘      └────────────────────┘


**AMI Build Phases:**

| Phase | Description |
|-------|-------------|
| 1 | Upload config files (Nginx, app, systemd units, scripts) |
| 2 | System update and base packages |
| 3 | Install and enable Nginx |
| 4 | Deploy staged configs to final locations |
| 5a | Install Docker CE |
| 5b | Install AWS CLI v2 |
| 5c | Install SSM Agent |
| 5d | Install Jenkins (Java 21 + WAR) |
| 6 | Security hardening (SSH lockdown, UFW, cleanup) |

---

## Prerequisites

- [Packer](https://developer.hashicorp.com/packer/downloads) >= 1.9
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- AWS credentials configured (`aws configure` or environment variables)
- An SSH key pair for EC2 access

---

## Repository Structure

devops-intro-project/
├── packer-templates/
│   └── control-server/
│       ├── build.sh                    # Build automation script
│       ├── control-server.pkr.hcl      # Packer HCL2 template
│       ├── variables.pkr.hcl           # Packer variable definitions
│       ├── builders/                   # Builder configs
│       ├── files/                      # Files staged into AMI
│       │   ├── nginx/                  # Nginx configs and snippets
│       │   ├── app/                    # Application configs
│       │   ├── systemd/               # Systemd unit files
│       │   └── scripts/               # Utility scripts
│       ├── provisioners/              # Provisioner configs
│       ├── scripts/                   # Build-time scripts
│       ├── logs/                      # Build logs (auto-generated)
│       └── terraform/                 # Infrastructure deployment
│           ├── main.tf
│           ├── variables.tf
│           ├── terraform.tfvars
│           └── terraform.auto.tfvars.json  # AMI ID (auto-generated)
├── jenkins-config/                    # Jenkins configuration files
└── .github/                           # GitHub workflows

---

## Quick Start

```bash
cd packer-templates/control-server

# 1. Initialize Terraform providers
./build.sh tf-init

# 2. Build the AMI and deploy the instance in one step
./build.sh build-and-apply
#That's it. The script builds the AMI, extracts the AMI ID, writes it to terraform.auto.tfvars.json, and runs terraform apply.

# Build Commands Reference
# All commands are run from packer-templates/control-server/:


## Packer Commands 

# Format all HCL files
./build.sh fmt

# Validate the Packer template
./build.sh validate

# Build the AMI (writes AMI ID to terraform.auto.tfvars.json)
./build.sh build

# Build only the amazon-ebs source (skip other builders)
./build.sh build-only

# Build with full debug logging (PACKER_LOG=1)
./build.sh debug
Terraform Commands

# Initialize Terraform (download providers, set up backend)
./build.sh tf-init

# Preview infrastructure changes
./build.sh tf-plan

# Apply infrastructure changes
./build.sh tf-apply
Combined Commands

# Full pipeline: build AMI → init Terraform → apply
./build.sh build-and-apply
Cleanup

# Remove logs, manifests, and auto-generated tfvars
./build.sh clean


## Usage Examples
# First-Time Setup

cd packer-templates/control-server

# Validate everything before building
./build.sh fmt
./build.sh validate

# Initialize Terraform
./build.sh tf-init

# Build and deploy
./build.sh build-and-apply
Iterating on the AMI

# Edit control-server.pkr.hcl, then:
./build.sh validate
./build.sh build

# Review what Terraform will change
./build.sh tf-plan

# Deploy the updated AMI
./build.sh tf-apply
Debugging a Failed Build

# Run with full Packer debug logging
./build.sh debug

# Logs are saved to logs/build-<timestamp>.log
ls -la logs/


## Tearing Down Infrastructure

cd packer-templates/control-server/terraform
terraform destroy


## Cleaning Up Old AMIs
# List AMIs created by Packer
aws ec2 describe-images --owners self \
  --query 'Images[*].[ImageId,Name,CreationDate]' --output table

# Deregister an old AMI
aws ec2 deregister-image --image-id ami-0123456789abcdef0
Connecting to the Server
SSH

ssh -i ~/.ssh/control-server-key ubuntu@<PUBLIC_IP>


## Post-Deploy: Jenkins Setup
Jenkins starts automatically on boot. Complete the setup wizard:

# SSH into the instance, then grab the initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
Open http://<PUBLIC_IP>:8080, paste the password, and follow the wizard.

## Configuration
Packer Variables (variables.pkr.hcl)
Variable	Default	Description
aws_region	us-east-1	AWS region for AMI build
instance_type	t3.micro	Temporary build instance type
ami_prefix	control-server	AMI name prefix
ssh_username	ubuntu	SSH user for provisioning
vpc_id	""	VPC ID (uses default if empty)
subnet_id	""	Subnet ID (uses default if empty)
Terraform Variables (terraform/terraform.tfvars)
Variable	Description
instance_type	Deployed instance type (e.g., m7i-flex.large)
ami_id	Auto-populated by build.sh from Packer manifest
What's Baked into the AMI
Component	Version	Port
Ubuntu	22.04 LTS (Jammy)	—
Nginx	Latest apt	80/443
Docker CE	Latest apt	—
Jenkins	2.558 (WAR)	8080
AWS CLI	v2 (latest)	—
SSM Agent	Latest snap	—
OpenJDK	21	—

Security hardening included:

SSH root login disabled

Password authentication disabled

UFW firewall enabled (SSH, Nginx, Jenkins 8080)

Unattended security upgrades enabled

Build artifacts cleaned from /tmp