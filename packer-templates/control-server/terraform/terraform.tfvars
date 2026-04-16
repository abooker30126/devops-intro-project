instance_type = "m7i-flex.large"
aws_region    = "us-east-1"
project_name  = "control-server"
environment   = "dev"
key_name      = "control-server-key"

# ⚠️  REQUIRED — paste your SSH public key:
#   cat ~/.ssh/tf-packer.pub
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCreA4VmZmKLbIQyed/Oz9Gl24i5Hp2M7I0JtPQyEycwDX5BguWmLYboujKLz9SEeWH1YCe7n7tQ7qpLeqpbTiZALkTlm+nJjxPZrSleEAqvlNVKBHFFbHqTGXtRRjusUggMu5ag7X7U4OtMgpTxh1QbEDDTY4/IDotx4icSkyvUOWsu/f4vN5k02d0MDmGXtQPyIjBubcQhU1MOhK5P2Z71S6P55RaZteD82cL2DHr1qQmX0EroaQZ5CayyMFZCGUly3Pq9N4uD8SOq7hU9a1YNSXCmsWUR1a6LUJJWqk127rTsn6CaFwYZI4MBreVAGtpXfJrXLZnjA4sood1z4Kn imported-openssh-key"

# ⚠️  SECURITY — lock SSH to your IP:
#   curl -s ifconfig.me
#   Then set: ["YOUR_IP/32"]
allowed_ssh_cidrs = ["174.163.165.42/32"]
