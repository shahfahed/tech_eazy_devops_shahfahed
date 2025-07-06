#!/bin/bash

set -e
# If any command in the script returns a non-zero exit code (error), immediately stop the script execution.
# Helps avoid continuing after failures [a safety feature].

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
cd ../terraform
terraform init

echo "Applying Terraform..."
terraform apply --auto-approve

echo "Waiting 4 minutes to allow instance setup..."
sleep 240

ec2_id=$(terraform output -raw ec2_id)
ec2_public_ip=$(terraform output -raw public_ip)
ec2_logs_bucket=$(terraform output -raw s3_bucket_name)

echo "EC2 instance created at IP: $ec2_public_ip"
echo "S3 bucket name: $ec2_logs_bucket"

echo "Testing app on port 80..."
curl -I http://$ec2_public_ip

echo "Sleeping 300 seconds before stopping instance for cost saving..."
sleep 300

echo "Stopping instance..."
aws ec2 stop-instances --instance-ids $ec2_id

echo "Done ✅"