#!/bin/bash

# Variables from templatefile:
# - cw_config_jason_url
# - app_repo_url
# - app_config_json_url
# - bucket_name
# - stage

# java-21, git and maven installation
sudo apt-get update -y
sudo apt-get install -y openjdk-21-jdk git maven jq

# awscli installation
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install -y unzip
unzip awscliv2.zip
sudo ./aws/install
sudo rm -rf awscliv2.zip aws

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Creating application log file and added dummy startup message
mkdir -p /home/ubuntu
touch /home/ubuntu/app.log
echo "Application started at $(date)" >> /home/ubuntu/app.log

# Download and apply CloudWatch Agent config
curl -o /opt/aws/amazon-cloudwatch-agent/etc/config.json "${cw_config_jason_url}"

# Start CloudWatch agent with config
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json \
  -s

# clone app repo
git clone ${app_repo_url} /home/ubuntu/app

# download app configuration file
curl  -o /home/ubuntu/app/config.json ${app_config_json_url}

cd /home/ubuntu/app/

# Build
mvn package

# Run app in background
sudo java -jar target/*.jar &
#nohup java -jar target/*.jar &

# Log file creation
echo "App deployed successfully at $(date)" > /var/log/app-deploy.log

# Upload logs to S3
aws s3 cp /var/log/cloud-init.log s3://${bucket_name}/logs/${stage}/cloud-init-$(date +%s).log
aws s3 cp /var/log/app-deploy.log s3://${bucket_name}/logs/${stage}/app-deploy-$(date +%s).log