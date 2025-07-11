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
  bucket        = var.bucket_name
  force_destroy = true
  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs_bucket.id

  rule {
    id     = "log-expire"
    status = "Enabled"

    expiration {
      days = 7
    }

    filter {
      prefix = "" # If blank lc rule applies to all objects
    }
  }
}

resource "aws_iam_role" "s3_putobject_role" {
  name = "${var.name_tag}-s3-putobject-role"
  
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
    Name = "${var.name_tag}-s3-putobject-role"
  }
}

resource "aws_iam_role_policy" "s3_putobject_policy" {
  name = "${var.name_tag}-s3-putobject-policy"
  role = aws_iam_role.s3_putobject_role.id

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

resource "aws_iam_instance_profile" "s3_putobject_profile" {
  name = "${var.name_tag}-s3-putobject-instance-profile"
  role = aws_iam_role.s3_putobject_role.name
}

resource "aws_iam_role" "s3_readonly_role" {
  name = "${var.name_tag}-s3-readonly"

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
    Name = "${var.name_tag}-read-s3-role"
  }
}

resource "aws_iam_role_policy_attachment" "s3_readonly_policy" {
  role = aws_iam_role.s3_readonly_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "s3_readonly_profile" {
  name = "${var.name_tag}-s3-readonly-instance-profile"
  role = aws_iam_role.s3_readonly_role.name
}

resource "aws_instance" "ec2" {
  count = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  iam_instance_profile = count.index == 0 ? aws_iam_instance_profile.s3_putobject_profile.name : aws_iam_instance_profile.s3_readonly_profile.name

  user_data = count.index == 0 ? templatefile("${path.module}/user_data.sh.tpl", {
    repo_url    = var.repo_url
    bucket_name = var.bucket_name
    }) : file(user_data_2.sh)

  tags = {
    Name = (
        count.index == 0 ? "${var.name_tag}-s3-write" : "${var.name_tag}-s3-read"
    )
  }
}