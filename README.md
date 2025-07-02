# AWS EC2 Automated Deployment Project

This project automates the deployment of an application on an AWS EC2 instance using **Terraform** and a shell script.

---

## 📄 **Project Overview**

This solution does the following:

1️⃣ Spins up an EC2 with configurable instance type & repo.  
2️⃣ Installs required dependencies (Java 21, Git, Maven, AWS CLI).  
3️⃣ Clones app repository and deploys the application.  
4️⃣ Verifies that the app is reachable on port 80.  
5️⃣ Supports multiple stages (Dev, Prod) via separate configuration files.  
6️⃣ Creates a private S3 bucket and uploads EC2 logs and app logs to it.  
7️⃣ Lifecycle rule automatically deletes logs after 7 days to save storage cost.  
8️⃣ Supports two IAM roles:  
  • Read-only S3 role (used to list and verify uploaded logs).  
  • Write-only S3 role (attached to EC2 for uploading logs; no read permission).  
9️⃣ Stops EC2 instance automatically after a set time (to avoid cost).  

---

## ⚙️ **Prerequisites**

- AWS account with Free Tier
- EC2 instance (Ubuntu 24.04)
- IAM role
- Terraform
- AWS CLI

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
├── scripts
│   ├── deploy.sh
│   ├── dev_config.sh
│   ├── prod_config.sh
└── terraform
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    └── user_data.sh.tpl
```

---

## 🌟 **How It Works**

### Steps

**1.** Go into the **scripts** directory of the cloned repo.

   Update the configuration files with the following:

- Preferred region
- Ubuntu AMI ID for your region
- Instance type
- PEM key
- Instance tag
- Repo URL
- **Bucket name** (mandatory — validated by Terraform)

**2.** Execute the commands below.

```
sudo chmod +x deploy.sh
./deploy.sh <stage>     # Stages: Dev or Prod — Pass one of them
```

### Deployment Script `deploy.sh`

- Accepts a **Stage** argument (`Dev`, `Prod`).
- Sources configuration from `dev_config.sh` or `prod_config.sh` based on the input received.
- Executes Terraform commands.
- Tests if the app is reachable using `curl`.
- Outputs the public IP. You can test in your browser:

```
http://<public-ip>
```

### Terraform

- Creates an EC2 instance in the **default VPC**.
- Attaches a security group allowing SSH (port 22) and HTTP (port 80).
- Uses `terraform/user_data.sh.tpl` to install required packages and start the app automatically.

### User Data Script

The file `terraform/user_data.sh.tpl`:

- Updates packages.
- Installs Java 21, Git, Maven, AWS CLI.
- Clones the application repository.
- Packages the application using Maven and runs it on port 80.

---

## **Security Notes**

- No keys stored in the repo — uses IAM roles.
- EC2 instance uses a **write-only** role to upload logs to S3.
- Separate **read-only** role can be used to verify logs.
- Security group allows HTTP and SSH — you may restrict allowed IPs for tighter security.

---

## **FAQ**

**Q: Can I deploy to a different region?**  
Yes! Change the `provider "aws"` region in `main.tf` or set `AWS_DEFAULT_REGION`.

**Q: Can I change ports?**  
Yes. Update app code, user data script, and security group accordingly.

---

## **Contributing**

Feel free to fork this repo and improve it. Suggestions and PRs are welcome!

---

### Happy Automating!
