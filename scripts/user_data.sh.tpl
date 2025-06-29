#!/bin/bash
sudo apt update -y
sudo apt install -y openjdk-21-jdk git maven

cd /home/ubuntu

git clone ${repo_url}

cd techeazy-devops
mvn package

sudo mkdir /home/ubuntu/backend
sudo cp target/*.jar /home/ubuntu/backend

sudo java -jar /home/ubuntu/backend/*.jar &