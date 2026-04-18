#!/bin/bash -eux

# NOTE: This script is part of the legacy Ubuntu 14.04 (EOL) build.
# Ubuntu 14.04 uses Upstart rather than systemd; Jenkins is started via
# an Upstart configuration installed alongside the WAR.

# Jenkins version — pinned to match the modern control-server template
JENKINS_VERSION="2.558"
JENKINS_WAR_URL="https://github.com/jenkinsci/jenkins/releases/download/jenkins-${JENKINS_VERSION}/jenkins.war"

# JDK 8 is the highest version available by default on Ubuntu 14.04
apt-get install -y software-properties-common
add-apt-repository ppa:openjdk-r/ppa
apt-get update
apt-get install -y \
  openjdk-8-jre \
  openjdk-8-jre-headless \
  openjdk-8-jdk \
  dos2unix \
  zip \
  unzip

# Create Jenkins user, directories, and WAR location
useradd -r -s /bin/false -d /var/lib/jenkins jenkins || true
mkdir -p /var/lib/jenkins /var/log/jenkins /usr/share/java
chown -R jenkins:jenkins /var/lib/jenkins /var/log/jenkins

# Download pinned Jenkins WAR
wget -q -O /usr/share/java/jenkins.war "${JENKINS_WAR_URL}"
chmod 644 /usr/share/java/jenkins.war
chown root:root /usr/share/java/jenkins.war

# Create Upstart init configuration for Ubuntu 14.04
cat <<'EOF' > /etc/init/jenkins.conf
description "Jenkins CI Server"
start on (net-device-up and local-filesystems and runlevel [2345])
stop on runlevel [!2345]
respawn
respawn limit 15 5
setuid jenkins
setgid jenkins
env JENKINS_HOME=/var/lib/jenkins
exec /usr/bin/java -Djava.awt.headless=true \
     -jar /usr/share/java/jenkins.war \
     --httpPort=8080 --prefix=/jenkins
EOF

# copy premade configuration files
# jenkins default config (used only as documentation reference with Upstart)
cp -f /tmp/jenkins-config/jenkins /etc/default
# fix dos newlines for Windows users
dos2unix /etc/default/jenkins
# install some extra plugins
/bin/bash /tmp/jenkins-config/install_jenkins_plugins.sh
# jenkins security and pipeline plugin config
cp -f /tmp/jenkins-config/config.xml /var/lib/jenkins
# set up username for vagrant
mkdir -p /var/lib/jenkins/users/vagrant
cp /tmp/jenkins-config/users/vagrant/config.xml /var/lib/jenkins/users/vagrant
# example job
mkdir -p /var/lib/jenkins/jobs
cd /var/lib/jenkins/jobs
tar zxvf /tmp/jenkins-config/example-job.tar.gz

# set permissions or else jenkins can't run jobs
chown -R jenkins:jenkins /var/lib/jenkins

# start jenkins via Upstart
initctl start jenkins || true
