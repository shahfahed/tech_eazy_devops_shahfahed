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

echo "Waiting 5 minutes to allow instance setup..."
sleep 300

putobject_ec2_id=$(terraform output -raw putobject_ec2_id)
putobject_ec2_public_ip=$(terraform output -raw putobject_ec2_public_ip)
ec2_logs_bucket=$(terraform output -raw s3_bucket_name)

echo "EC2 instance created at IP: $putobject_ec2_public_ip"
echo "S3 bucket name: $ec2_logs_bucket"

echo "Testing app on port 80..."
curl -I http://$putobject_ec2_public_ip

echo "Sleeping 3 minutes before stopping instance for cost saving..."
#sleep 180
sleep 60

echo "Stopping instance..."
aws ec2 stop-instances --instance-ids $putobject_ec2_id

echo "Infrastructure will go down in 60 seconds..."
sleep 60
terraform destroy --auto-approve

echo "Done ✅"