#!/bin/bash
sudo apt update -y
sudo apt install -y openjdk-21-jdk git maven

cd /home/ubuntu

git clone ${repo_url}

cd techeazy-devops
mvn package
sudo java -jar target/*.jar &