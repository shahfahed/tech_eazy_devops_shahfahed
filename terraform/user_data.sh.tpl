#!/bin/bash
sudo apt-get update -y

# java-21, git and maven installation
sudo apt-get install -y openjdk-21-jdk git maven

# awscli installation
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install -y unzip
unzip awscliv2.zip
sudo ./aws/install
sudo rm -rf awscliv2.zip aws

git clone ${repo_url} /home/ubuntu/app

cd /home/ubuntu/app/
mvn package
sudo java -jar target/*.jar &

sleep 30 # waiting for app to start

# Log file creation
echo "App deployed successfully at $(date)" > /var/log/app-deploy.log

# Upload logs to S3
aws s3 cp /var/log/syslog s3://${bucket_name}/syslog-$(date +%s).log
aws s3 cp /var/log/app-deploy.log s3://${bucket_name}/app-deploy-$(date +%s).log