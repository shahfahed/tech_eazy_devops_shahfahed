variable "region" {
    description = "region where infra should be deployed"
    default     = "ap-south-1"
}
variable "ami_id" {
  description = "Ubuntu 24.04 AMI for ap-south-1"
  default     = "ami-0f918f7e67a3323f0"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
  default     = "mb-lap-key"
}

variable "name_tag" {
  description = "Instance tag"
  default     = "techeazy"
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string

  validation {
    condition = length(var.bucket_name) > 0
    error_message = "Error: You must provide a non-empty bucket_name variable."
  }
}

variable "repo_url" {
  description = "Git repo URL"
  default     = "https://github.com/techeazy-consulting/techeazy-devops.git"
}
