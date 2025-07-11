#!/bin/bash
sudo apt-get update -y

# awscli installation
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install -y unzip
unzip awscliv2.zip
sudo ./aws/install
sudo rm -rf awscliv2.zip aws