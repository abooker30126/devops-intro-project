#!/usr/bin/env bash
set -euxo pipefail

echo "=== Installing Java 17 ==="
sudo apt-get update -y || true
sudo apt-get install -y openjdk-17-jdk

echo "=== Creating Jenkins user ==="
sudo id jenkins &>/dev/null || sudo useradd -m -d /var/lib/jenkins -s /usr/sbin/nologin jenkins

echo "=== Creating Jenkins directories ==="
sudo mkdir -p /var/lib/jenkins /var/log/jenkins /var/cache/jenkins
sudo chown -R jenkins:jenkins /var/lib/jenkins /var/log/jenkins /var/cache/jenkins

echo "=== Downloading Jenkins LTS WAR ==="
sudo wget -q -O /usr/share/jenkins.war https://get.jenkins.io/war-stable/latest/jenkins.war
sudo chmod 644 /usr/share/jenkins.war

echo "=== Creating systemd service ==="
sudo tee /etc/systemd/system/jenkins.service > /dev/null <<EOF
[Unit]
Description=Jenkins CI Server
After=network.target

[Service]
User=jenkins
Group=jenkins
ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /usr/share/jenkins.war
Restart=always
RestartSec=10
Environment="JENKINS_HOME=/var/lib/jenkins"
WorkingDirectory=/var/lib/jenkins

# Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

echo "=== Enabling and starting Jenkins ==="
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "=== Jenkins installation complete ==="
