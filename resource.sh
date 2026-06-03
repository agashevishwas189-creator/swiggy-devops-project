#!/bin/bash
set -e

# Logs
exec > >(tee /var/log/user-data.log)
exec 2>&1

apt-get update -y

# Basic packages
apt-get install -y wget curl gnupg lsb-release ca-certificates unzip software-properties-common

# Java 21
apt-get install -y openjdk-21-jdk

# Docker
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Jenkins Repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update -y

# Jenkins
apt-get install -y jenkins
systemctl enable jenkins
systemctl start jenkins

# Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
 | gpg --dearmor \
 | tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
 | tee /etc/apt/sources.list.d/trivy.list

apt-get update -y
apt-get install -y trivy

# SonarQube
docker volume create sonarqube_data
docker volume create sonarqube_logs
docker volume create sonarqube_extensions

docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  sonarqube:lts-community

# Verification output
java -version
docker --version
trivy --version
systemctl status jenkins --no-pager