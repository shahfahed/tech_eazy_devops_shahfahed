# AWS EC2 Automated Deployment Project

This project automates the deployment of an application on an AWS EC2 instance using **Terraform** and a shell script.

---

## 📄 **Project Overview**

This solution does the following:

1️⃣ Spins up an EC2 instance of a specific type in AWS.  
2️⃣ Installs required dependencies (Java 21, Git, Maven).  
3️⃣ Clones a GitHub repository and deploys the application.  
4️⃣ Verifies that the app is reachable on port 80.  
5️⃣ Supports multiple stages (Dev, Prod) via separate configuration files.  

---
## ⚙️ **Prerequisites**

- AWS account with Free Tier
- EC2 instance (ubuntu/debian)
- IAM role
- Terraform
- aws cli

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

### Deployment Script `deploy.sh`

- Accepts a **Stage** argument (`Dev`, `Prod`).
- Sources configuration from `dev_config.sh` or `prod_config.sh` based on the input received.
- Executes Terraform commands.
- Tests if the app is reachable using `curl`.
- Script will output the public IP. You can test in your browser:

```
http://<public-ip>
```

**Note**: Update the configuraion files with the following:

- Preferred region
- Ubuntu ami-id of the region specified above
- Instance type
- PEM key
- Instance tag
- Repo URL

### Terraform

- Creates an EC2 instance in the **default VPC**.
- Attaches a security group allowing SSH (port 22) and HTTP (port 80).
- Uses `user_data.sh.tpl` to install required packages and start the app automatically.

### User Data Script

The file `scripts/user_data.sh.tpl`:

- Updates packages.
- Installs Java 21, Git, and Maven.
- Clones the application repository.
- Packages the application based on pom.xml and runs the app on port 80.

---

## ✅ **Security Notes**

- No keys stored in the repo. Used IAM role.
- Security group allows HTTP and SSH — you may restrict IPs for tighter security.

---

## 💬 **FAQ**

**Q: Can I deploy to a different region?**  
Yes! Change `provider "aws"` region in `main.tf` or set `AWS_DEFAULT_REGION`.

**Q: Can I change ports?**  
Yes. Update app configuration and security group rules.

---

## 🙏 **Contributing**

Feel free to fork this repo and improve it. Suggestions and PRs are welcome!

---

### Happy Automating!
