# Automated EC2 Deployment with Monitoring and Alerts

## Overview

This project extends the previous EC2 automation by adding log monitoring and alerting using AWS CloudWatch and SNS. It supports multiple environments (dev, qa, prod) using environment-based GitHub Actions pipelines.

## Features

1. **EC2 Log Monitoring**:
   - CloudWatch Agent is installed and configured via `user_data.sh`.
   - Logs from `/home/ubuntu/app.log` are streamed to CloudWatch Logs.

2. **CloudWatch Alarms**:
   - CloudWatch metric filters detect "ERROR" or "Exception" in logs.
   - Alarms notify through SNS if error patterns are detected.

3. **SNS Notifications**:
   - SNS topic (`app-alerts-topic`) sends alert emails.

## Terraform Structure

- **main.tf / variables.tf / outputs.tf**: Main Terraform code (non-modular version).
- **cloudwatch_agent_config.json**: Configuration file for the CloudWatch agent.
- **GitHub Actions Pipelines**: Separate workflows for dev, qa, and prod environments.
- **IAM Policies**: Combined IAM role for CloudWatch and S3 permissions.

## Usage

### Terraform Setup

```bash
terraform init
terraform plan -var="stage=dev"
terraform apply -var="stage=dev"
```

### Simulate Error for Testing

```bash
ssh -i "your-key.pem" ubuntu@<EC2-Public-IP>
echo "ERROR: Simulated failure on $(date)" >> /home/ubuntu/app.log
```

### Check Email

Confirm the SNS subscription via email. Once the error is logged, wait for a few minutes and you should receive an alert email.

## Environment Pipelines

- **dev**: Triggered on push to `dev` branch.
- **qa**: Triggered on push to `qa` branch.
- **prod**: Triggered on push to `main` branch.

Each environment has a separate GitHub Actions workflow YAML file.

## Notes

- Ensure your GitHub secrets include AWS credentials.
- Alarms may show "Insufficient Data" initially. Simulate logs to activate.

## 📁 **Directory Structure**

```
.
├── README.md
├── .github
│   └── workflows
│       └── dev.yaml
│       └── prod.yaml
├── scripts
│   ├── deploy.sh
│   ├── dev_config.sh
│   ├── prod_config.sh
└── terraform
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    ├── user_data_2.sh
    └── user_data.sh.tpl
```

## ✅ Security Highlights

- No hard-coded AWS keys (uses secrets).
- Private S3 bucket.
- IAM roles with least privilege:
- Lifecycle policy on S3 to auto-delete logs after 7 days.

## **Contributing**

Feel free to fork this repo and improve it. Suggestions and PRs are welcome!


### Happy Automating!