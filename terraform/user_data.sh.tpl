#!/bin/bash
sudo apt update -y
sudo apt install -y openjdk-21-jdk git maven

git clone ${repo_url} /home/ubuntu/

cd techeazy-devops
mvn package
sudo java -jar target/*.jar &

sleep 30 # waiting for app to start

# Log file creation
echo "App deployed successfully at $(date)" > /var/log/app-deploy.log

# Upload logs to S3
aws s3 cp /var/log/syslog s3://${bucket_name}/syslog-$(date +%s).log
aws s3 cp /var/log/app-deploy.log s3://${bucket_name}/app-deploy-$(date +%s).log