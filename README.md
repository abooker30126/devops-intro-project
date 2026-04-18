<<<<<<< HEAD
👋 Hi, I’m Tony Booker

AI Security • Cloud Security • Autonomous Systems • Drone Engineering

I’m a security‑minded engineer pursuing my Master’s in Artificial Intelligence, specializing in autonomous vehicle flight security. My work sits at the intersection of AI, cloud security, and autonomous systems, where I focus on securing next‑generation workloads — from LLM pipelines to autonomous flight platforms.

I’m currently building skills and projects around:

AI security operations

Cloud security engineering

Autonomous drone systems & flight safety

AI forensics & adversarial testing

Container and API security

Automation, scripting, and workflow orchestration

My long‑term mission is to help shape the future of secure autonomous flight, ensuring that AI‑driven systems are resilient, trustworthy, and safe.


🚀 What I’m Working On...
Advancing my graduate research in autonomous vehicle flight security

Hands‑on labs in AI forensics, container vulnerabilities, and cloud incident response

Exploring PyRIT (Azure) and other automated AI risk‑identification and offensive testing  frameworks

Building and securing custom unmanned FPV drone systems platforms (part 107 certified remote pilot)

Developing automation workflows for security operations


🧠 Technical Interests
AI/ML Security

Cloud Security (Azure, AWS)

API & Gateway Security

Autonomous Systems

SOAR & workflow automation

Threat modeling for AI workloads

Secure MLOps pipelines


🛠️ Tools & Technologies
Security & Cloud: Prisma (AIRS), XSOAR‑style automation, container security, API gateways
AI & Data: Python, PyTorch, LLM evaluation, AI forensics
Automation: Scripting, workflow engines, CI/CD
Hardware & Flight: Custom drone builds, flight controllers, telemetry systems


🥁 Outside of Tech
When I’m not deep in AI security, you’ll probably find me:

Playing the drums — rhythm keeps me grounded

Building and flying drones — experimenting with autonomous flight, sensors, and safety systems

Learning new ways to merge AI with real‑world robotics

These hobbies fuel my curiosity and directly influence my work in autonomous systems.


📫 Let’s Connect
I’m always open to collaborating on AI security, cloud engineering, or autonomous systems projects.
If you’re working on something in that space, I’d love to talk.

------------------------------------------------------------------------------------------------------------------------
# DevSecOps JENKINS CI/CD Control Server — Infrastructure as Code 

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
=======
# DevOps Intro Project

I built this as part of Udacity's Intro to DevOps Nanodegree program (Master's in Artificial Intelligence core). A hands-on practice project for learning core DevOps concepts including infrastructure automation, virtual machine provisioning, and continuous integration - updated for Ubuntu 22. 

---

## Table of Contents

- [Repository Structure](#repository-structure)
- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Setting up your local machine](#setting-up-your-local-machine)
- [Part I: Building a box with Packer](#part-i-building-a-box-with-packer)
- [Part II: Cloning, developing, and running the web application](#part-ii-cloning-developing-and-running-the-web-application)
- [Troubleshooting](#troubleshooting)
- [Expected Learning Outcomes](#expected-learning-outcomes)
- [About Me](#about-me)
>>>>>>> bd943412ed4e132961ed0e359542dd68dff18cd6

---

## Repository Structure

<<<<<<< HEAD
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


## Security hardening included:

# -  SSH root login disabled

# - Password authentication disabled

# - UFW firewall enabled (SSH, Nginx, Jenkins 8080)

# - Unattended security upgrades enabled

# - Build artifacts cleaned from /tmp
=======
```
devops-intro-project/
├── .gitignore
├── CODEOWNERS
├── README.md
├── jenkins-config/
│   ├── config.xml
│   ├── example-job.tar.gz
│   ├── install_jenkins_plugins.sh
│   ├── jenkins
│   └── users/
│       └── vagrant/
│           └── config.xml
└── packer-templates/
    ├── application-server.json
    ├── control-server.json
    ├── http/
    │   └── preseed.cfg
    ├── scripts/
    │   ├── application.sh
    │   ├── cleanup.sh
    │   ├── graphite.sh
    │   ├── jenkins.sh
    │   ├── nginx.sh
    │   ├── update.sh
    │   ├── vagrant.sh
    │   └── virtualbox.sh
    └── virtualbox/
        └── Vagrantfile
```

---

## Project Overview

This project walks you through the foundational DevOps workflow:

1. **Provision** a reproducible virtual machine using [Packer](https://www.packer.io/) to build a base image
2. **Manage** the VM lifecycle with [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/)
3. **Deploy** and test a Node.js web application inside the VM using Grunt

By the end of this project you will have a working local DevOps pipeline from infrastructure-as-code all the way to running automated tests.

---

## Prerequisites

### Prior Knowledge
These instructions assume familiarity with Git and GitHub. If you are not comfortable with those tools, please complete Udacity's [How to Use Git and GitHub](https://www.udacity.com/course/how-to-use-git-and-github--ud775) course before proceeding.

### System Requirements
| Requirement | Minimum |
|-------------|---------|
| OS | macOS, Windows 10/11, or Linux (64-bit) |
| RAM | 4 GB (8 GB recommended) |
| Disk Space | ~10 GB free |
| CPU | Hardware virtualisation (VT-x / AMD-V) enabled in BIOS |

### Environment Variables / PATH
After installing the required tools, you will need to ensure that your computer can find the executables to run them. For this, you might need to modify the PATH environment variable. A good overview is at [superuser.com](https://superuser.com/questions/284342/what-are-path-and-other-environment-variables-and-how-can-i-set-or-use-them). You may need to search the web for instructions on how to set the PATH variable for your specific operating system and version.

---

## Setting up your local machine

* Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* Install [Vagrant](https://www.vagrantup.com/downloads.html)
* Install [Packer](https://www.packer.io/downloads.html)
* Fork this repo to your own account
* Clone the forked repo to your local machine using this command: `git clone http://github.com/<account-name>/devops-intro-project devops`, replacing `<account-name>` with your GitHub username.

---

## Part I: Building a box with Packer

* Run `cd packer-templates`
* Run `packer build -only=virtualbox-iso application-server.json`. You may see various timeouts and errors, as shown below. If you do, retry the command until the ISO download succeeds:

```
read: operation timed out
==> virtualbox-iso: ISO download failed.
Build 'virtualbox-iso' errored: ISO download failed.

checksums didn't match expected
==> virtualbox-iso: ISO download failed.
Build 'virtualbox-iso' errored: ISO download failed.

==> Some builds didn't complete successfully and had errors:
--> virtualbox-iso: ISO download failed.
```

* Run `cd virtualbox`
* Run `vagrant box add ubuntu-14.04.6-server-amd64-appserver_virtualbox.box --name devops-appserver`
* Run `vagrant up`
* Run `vagrant ssh` to connect to the server

---

## Part II: Cloning, developing, and running the web application

* On your local machine go to the root directory of the cloned repository
* Run `git clone https://github.com/chef/devops-kungfu.git devops-kungfu`
* Open http://localhost:8080 from your local machine to see the app running.
* In the VM, run `cd devops-kungfu`
* To install app specific node packages, run `sudo npm install`. You may see several errors; they can be ignored for now.
* Now you can run tests with the command `grunt -v`. The tests will run, then quit with an error.

---

### Troubleshooting

**Ubuntu version / checksum errors**

If you encounter errors with Ubuntu version numbers not being available or checksum errors on Ubuntu, it means that this repository has not yet been updated for the latest Ubuntu version. Feel free to mention this in the [forum](https://discussions.udacity.com/c/nd012-p1-intro-to-devops/nd012-the-devops-environment). Meanwhile, you can fix this error for yourself by editing the contents of the `application-server.json` and `control-server.json` template files inside the `packer-templates` folder.

* Find the newest version number and checksum from the [Ubuntu website for this release](http://releases.ubuntu.com/trusty/)
* Edit `PACKER_BOX_NAME` and `iso_checksum` in the template files to match that version number and checksum.

> **Note on Ubuntu 14.04 (Trusty):** Ubuntu 14.04 reached end-of-life in April 2019. If you want to use a modern, supported Ubuntu release (e.g. 20.04 LTS or 22.04 LTS), you will need to update the ISO URL, checksum, and any OS-specific provisioning scripts inside `packer-templates/` to target the newer release. The [Ubuntu releases page](http://releases.ubuntu.com/) lists current ISO files and their SHA256 checksums.

**Vagrant `vagrant up` fails**

* Ensure hardware virtualisation (VT-x / AMD-V) is enabled in your BIOS/UEFI settings.
* Make sure no other hypervisor (e.g. Hyper-V on Windows) is running at the same time as VirtualBox.

**`grunt -v` exits with an error**

This is expected behaviour for the practice exercise — the tests are designed to fail so you can observe the CI feedback loop in action.

---

## Expected Learning Outcomes

By completing this project you will be able to:

- Use **Packer** to build a repeatable machine image from a JSON template
- Use **Vagrant** to spin up, connect to, and destroy a virtual machine
- Understand the role of provisioning scripts in automating server configuration
- Clone and run a Node.js application inside a VM
- Execute automated tests with **Grunt** and interpret the results
- Troubleshoot common infrastructure-as-code issues (ISO checksums, PATH, networking)

---

<details>
<summary>👤 About Me</summary>

## 👋 Hi, I'm Tony Booker

**AI Security • Cloud Security • Autonomous Systems • Drone Engineering**

Securing the future of autonomous flight through AI and cloud security innovation.

---

### About

I'm a security-minded engineer pursuing my Master's in Artificial Intelligence, specializing in autonomous vehicle flight security. My work sits at the intersection of AI, cloud security, and autonomous systems.

**My Mission:** To help shape the future of secure autonomous flight, ensuring that AI-driven systems are resilient, trustworthy, and safe.

---

### 🧠 Technical Skills

**AI/ML Security**
- Adversarial ML testing and robustness evaluation
- LLM security and prompt injection analysis
- AI forensics and model interpretation
- PyRIT and other red teaming frameworks

**Cloud Security (AWS, Azure)**
- AWS Config Rules and compliance automation
- Identity & Access Management (IAM) optimization
- Container security and vulnerability scanning
- CloudTrail monitoring and incident response
- Infrastructure-as-Code security (Terraform, CloudFormation)

**API & Gateway Security**
- OAuth 2.0 / OpenID Connect implementation
- API gateway policies and rate limiting
- GraphQL security considerations
- RESTful security best practices

**Autonomous Systems & Flight Safety**
- Drone flight controller programming
- Sensor integration and telemetry systems
- Safety-critical system design
- Real-world robotics and embedded systems
- FAA Part 107 Flight Operations

**Security Operations & Automation**
- SOAR platform orchestration (XSOAR-style automation)
- Workflow engines and CI/CD security
- Threat modeling for AI workloads
- Secure MLOps pipeline development

---

### 🛠️ Tools & Technologies

| Category | Tools & Frameworks |
|----------|-------------------|
| **Security & Cloud** | Prisma (AIRS), XSOAR automation, Terraform, AWS Config, HashiCorp Vault |
| **AI & Data** | Python, PyTorch, PyRIT, LLM evaluation frameworks, TensorFlow |
| **Automation** | Scripting (Bash, Python), Workflow engines, GitHub Actions, CI/CD |
| **Container & API** | Docker, Kubernetes, API Gateway security, Falco |
| **Hardware & Flight** | Custom drone builds, Pixhawk controllers, MAVLink telemetry, PX4 firmware |

---

### 📜 Certifications

- ✈️ **FAA Part 107 Commercial Drone Pilot** — Certified for commercial UAS operations
- 🎓 **Master's in Artificial Intelligence** (In Progress) — Focus on autonomous systems security
- 📚 Additional certifications in cloud security and DevSecOps available upon request

---

### 🥁 Interests & Hobbies

When I'm not deep in AI security, you'll find me:

- 🎸 **Playing drums and bass guitar** — rhythm keeps me grounded
- 🚁 **Building and experimenting** with autonomous flight, sensors, and safety systems
- 📹 **Flying FPV and cinematic drones** — combining engineering with creative storytelling
- 🤖 **Learning new ways** to merge AI with real-world robotics

These hobbies directly fuel my curiosity and influence my professional work in autonomous systems.

---

### 📬 Get In Touch

I'm always open to collaborating on:
- 🔒 AI security and adversarial testing projects
- ☁️ Cloud security engineering and compliance automation
- 🚁 Autonomous systems and flight safety innovations
- 🔧 DevSecOps tooling and secure development practices

**Let's connect:**
- 🐙 [GitHub](https://github.com/abooker30126) — Code and projects
- 📧 Email — tony.booker@rocketmail.com

---

**Last Updated:** April 18, 2026

</details>
>>>>>>> bd943412ed4e132961ed0e359542dd68dff18cd6
