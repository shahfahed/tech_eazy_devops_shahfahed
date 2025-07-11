# AWS EC2 Automated Deployment Project with GitHub Actions

This project automates the deployment of an application on an AWS EC2 instance using **Terraform**, **shell script** and **GitHub Actions**.

---

## 📄 **Project Overview**

This solution does the following:

1️⃣ Spins up EC2 instances.  
  • Supports multiple stages (Dev, Prod) via separate configuration files.  
2️⃣ Installs required dependencies.  
  • (Java 21, Git, Maven, AWS CLI).  
3️⃣ Clones app repository and deploys the application on first EC2.  
4️⃣ Verifies that the app is reachable on port 80.  
5️⃣ Creates a private S3 bucket and uploads EC2 logs and app logs to it.    
6️⃣ Lifecycle rule automatically deletes logs after 7 days to save storage cost.  
7️⃣ Supports two IAM roles:  
  • Write-only S3 role (attached to EC2 for uploading logs; no read permission). - Attached to First EC2  
  • Read-only S3 role (used to list and verify uploaded logs). - Attached to second EC2  
8️⃣ Stops EC2 instance automatically after a set time (to avoid cost).  
9️⃣ Uses GitHub Actions to automate provisioning, deployment, and validation.
---

## ⚙️ **Prerequisites**

- AWS account (Free Tier)
- Terraform
- AWS CLI
- GitHub repository with secrets configured  
  • AWS_ACCESS_KEY_ID  
  • AWS_SECRET_ACCESS_KEY  

### Install Terraform and AWS CLI

```
# Terraform installation

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform

# AWS CLI installation
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install -y unzip
unzip awscliv2.zip
sudo ./aws/install

# Clean workspace (Optional)
sudo rm -rf awscliv2.zip aws
```

---

## 📁 **Directory Structure**

```
.
├── README.md
├── .github
    └── workflows
        └── automate.yaml
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


### Terraform

- Creates EC2 instances in the **default VPC**.
- Attaches security groups allowing SSH (port 22) and HTTP (port 80).
- Uses userdata scripts to install required packages and start the app automatically.

### Userdata Scripts

The file `terraform/user_data.sh.tpl`:

- Updates packages.
- Installs Java 21, Git, Maven, AWS CLI.
- Clones the application repository.
- Packages the application using Maven and runs it on port 80.

The file `terraform/user_data_2.sh`:

- Updates packages.
- Installs AWS CLI.

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
