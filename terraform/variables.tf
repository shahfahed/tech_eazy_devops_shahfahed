variable "region" {
    description = "region where infra should be deployed"
}
variable "ami_id" {
  description = "Ubuntu 24.04 AMI for ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
}

variable "key_name" {
  description = "EC2 key pair name"
}

variable "name_tag" {
  description = "Instance tag"
}

variable "repo_url" {
  description = "Git repo URL"
}
