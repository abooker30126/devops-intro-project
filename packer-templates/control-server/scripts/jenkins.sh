#!/usr/bin/env bash
set -euxo pipefail

# Jenkins version — must match the version used in control-server.pkr.hcl Phase 5d
JENKINS_VERSION="2.558"
JENKINS_WAR_URL="https://github.com/jenkinsci/jenkins/releases/download/jenkins-${JENKINS_VERSION}/jenkins.war"

echo "=== Installing Java 17 ==="
sudo apt-get update -y || true
sudo apt-get install -y openjdk-17-jdk

echo "=== Creating Jenkins user ==="
sudo id jenkins &>/dev/null || sudo useradd -m -d /var/lib/jenkins -s /usr/sbin/nologin jenkins

echo "=== Creating Jenkins directories ==="
sudo mkdir -p /var/lib/jenkins /var/log/jenkins /var/cache/jenkins /usr/share/java
sudo chown -R jenkins:jenkins /var/lib/jenkins /var/log/jenkins /var/cache/jenkins

echo "=== Downloading Jenkins WAR ${JENKINS_VERSION} ==="
sudo wget -q -O /usr/share/java/jenkins.war "${JENKINS_WAR_URL}"
sudo chmod 644 /usr/share/java/jenkins.war

echo "=== Creating systemd service ==="
sudo tee /etc/systemd/system/jenkins.service > /dev/null <<EOF
[Unit]
Description=Jenkins CI Server
After=network.target

[Service]
User=jenkins
Group=jenkins
ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /usr/share/java/jenkins.war --httpPort=8080
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

echo "=== Jenkins ${JENKINS_VERSION} installation complete ==="
