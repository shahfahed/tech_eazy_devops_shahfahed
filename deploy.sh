#!/bin/bash

STAGE=$1

if [[ "$STAGE" == "Dev" ]]; then
  source ./dev_config.sh
elif [[ "$STAGE" == "Prod" ]]; then
  source ./prod_config.sh
  #source means load and execute that file in the current shell (not in a subshell).
else
  echo "Please specify stage: Dev or Prod"
  exit 1
fi

echo "Initializing Terraform..."
cd /home/ubuntu/terraform
terraform init

echo "Applying Terraform..."
terraform apply --auto-approve

INSTANCE_IP=$(terraform output -raw public_ip)
echo "EC2 instance created at IP: $INSTANCE_IP"

echo "Waiting 3 minutes to allow instance setup..."
sleep 180

echo "Testing app on port 80..."
curl -I http://$INSTANCE_IP

echo "Done ✅"

#echo "Sleeping 300 seconds before stopping instance for cost saving..."
#sleep 300

#echo "pull the instance ID..."
#instance_id = $(terraform state show aws_instance.ec2 | grep id | awk '{print $3}' | sed -n '2p' | tr -d '"')

#echo "Stopping instance..."
#aws ec2 stop-instances --instance-ids instance_id