provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow-ssh-http"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket = "${var.name_tag}-ec2-logs"
  # String interploation
  tags = {
    Name = var.name_tag+"-ec2-logs"
    # Direct string interpolation from ver above 0.12
  }
}

resource "aws_iam_role" "ec2_role" {
  name = var.name_tag+"-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    tag-key = var.name_tag+"-ec2-role"
  }
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = var.name_tag+"-ec2-policy"
  role = aws_iam_role.ec2_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.logs_bucket.bucket}/*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name_tag}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    repo_url    = var.repo_url
    bucket_name = aws_se_bucket.logs_bucket.bucket
    })

  tags = {
    Name = var.name_tag
  }
}