# AWS EC2 Automated Deployment Project with GitHub Actions

This project automates the deployment of an application on an AWS EC2 instance using **Terraform**, **shell script** and **GitHub Actions**.

---

## 📄 **Project Overview**

This solution does the following:

- Spins up EC2 instances.  
  • Supports multiple stages (Dev, Prod) via separate configuration files.  
- Installs required dependencies.  
  • (Java 21, Git, Maven, AWS CLI).  
- Clones app repository and deploys the application on first EC2.    
- Verifies that the app is reachable on port 80.  
- Creates a private S3 bucket and uploads EC2 logs and app logs to it.    
- Lifecycle rule automatically deletes logs after 7 days to save storage cost.  
- Supports two IAM roles:  
  • Write-only S3 role (attached to EC2 for uploading logs; no read permission). - Attached to First EC2  
  • Read-only S3 role (used to list and verify uploaded logs). - Attached to second EC2  
- Stops EC2 instance automatically after a set time (to avoid cost).  
- Uses GitHub Actions to automate provisioning, deployment, and validation.  

---

## ⚙️ **Prerequisites**

- AWS account (Free Tier)
- Terraform
- AWS CLI
- GitHub repository with secrets configured  
  • AWS_ACCESS_KEY_ID  
  • AWS_SECRET_ACCESS_KEY  

---

## 📁 **Directory Structure**

```
.
├── README.md
├── .github
│   └── workflows
│       └── automate.yaml
├── scripts
│   ├── deploy.sh
│   ├── dev_config.sh
│   ├── prod_config.sh
└── terraform
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    ├── user_data_2.sh
    ├── user_data_2.sh
    └── user_data.sh.tpl
```

---

## 🌟 **How It Works**

### Steps

- Choose stage by pushing a tag:
  - deploy-dev → Dev configs
  - deploy-prod → Prod configs

- Executes on Dev ENV by default when changes pushed to main.


**Workflow (automate.yaml)**

- Triggered on push to main and on deploy-* tags.
- Sets stage variable dynamically.
- Configures AWS credentials securely using GitHub secrets.
- Runs deploy.sh, which:
  - Sources correct config file.
  - Runs Terraform to provision EC2, S3, IAM roles.
  - Uploads logs to S3.
  - Verifies application health using curl.

---
## ✅ Security Highlights

- No hard-coded AWS keys (uses secrets).
- Private S3 bucket.
- IAM roles with least privilege:
- Write-only role (first EC2).
- Read-only role (second EC2).
- Lifecycle policy on S3 to auto-delete logs after 7 days.
---

## **Contributing**

Feel free to fork this repo and improve it. Suggestions and PRs are welcome!

---

### Happy Automating!
