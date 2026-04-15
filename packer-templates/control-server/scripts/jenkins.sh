#!/usr/bin/env bash
set -euxo pipefail

echo "=== Installing Java 17 (required for Jenkins) ==="
sudo apt-get update -y || true
sudo apt-get install -y openjdk-17-jdk

echo "=== Creating Jenkins user ==="
sudo useradd -m -d /var/lib/jenkins -s /bin/bash jenkins || true

echo "=== Creating Jenkins directories ==="
sudo mkdir -p /var/lib/jenkins
sudo mkdir -p /var/log/jenkins
sudo mkdir -p /var/cache/jenkins

sudo chown -R jenkins:jenkins /var/lib/jenkins /var/log/jenkins /var/cache/jenkins

echo "=== Downloading Jenkins LTS WAR ==="
sudo wget -q -O /usr/share/jenkins.war https://get.jenkins.io/war-stable/latest/jenkins.war

echo "=== Creating systemd service ==="
sudo tee /etc/systemd/system/jenkins.service > /dev/null <<EOF
[Unit]
Description=Jenkins Continuous Integration Server
After=network.target

[Service]
User=jenkins
Group=jenkins
ExecStart=/usr/bin/java -jar /usr/share/jenkins.war
Restart=always
Environment="JENKINS_HOME=/var/lib/jenkins"

[Install]
WantedBy=multi-user.target
EOF

echo "=== Reloading systemd and starting Jenkins ==="
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "=== Jenkins installation complete (WAR-based) ==="
