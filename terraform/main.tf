provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

# Security Group
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

  ingress {
    description = "backend-port"
    from_port   = 8080
    to_port     = 8080
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

# S3 bucket
resource "aws_s3_bucket" "logs_bucket" {
  bucket        = var.bucket_name
  force_destroy = true
  tags = {
    Name = var.bucket_name
  }
}

# S3 bucket lifecycle rule
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

# PutObject Role
resource "aws_iam_role" "write_ec2_role" {
  name = "s3-putobject-role-${var.name_tag}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service  = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "${var.name_tag}-write_ec2_role"
  }
}

# PutObject Role Policy
resource "aws_iam_role_policy" "s3_putobject_policy" {
  name = "s3-putobject-policy-${var.name_tag}"
  role = aws_iam_role.write_ec2_role.id #for inline policy need to pass ID

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = [
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.logs_bucket.bucket}/*"
      },
    ]
  })
}

# CloudWatch Policy Attachment
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.write_ec2_role.name #for managed policy need to pass NAME
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Write Instance Profile
resource "aws_iam_instance_profile" "write_ec2_profile" {
  name = "s3-putobject-instance-profile-${var.name_tag}"
  role = aws_iam_role.write_ec2_role.name
}

# ReadOnly S3 Role
resource "aws_iam_role" "s3_readonly_role" {
  name = "s3-readonly-${var.name_tag}"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service  = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "${var.name_tag}-read-s3-role"
  }
}

# ReadOnly S3 Role Policy Attachment
resource "aws_iam_role_policy_attachment" "s3_readonly_policy" {
  role       = aws_iam_role.s3_readonly_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# ReadOnly Instance Profile
resource "aws_iam_instance_profile" "s3_readonly_profile" {
  name = "s3-readonly-instance-profile-${var.name_tag}"
  role = aws_iam_role.s3_readonly_role.name
}

# EC2 Instance
resource "aws_instance" "ec2" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  iam_instance_profile = count.index == 0 ? aws_iam_instance_profile.write_ec2_profie.name : aws_iam_instance_profile.s3_readonly_profile.name

  user_data = count.index == 0 ? templatefile("${path.module}/user_data.sh.tpl", {
    cw_config_jason_url = var.cw_config_jason_url
    app_repo_url        = var.app_repo_url
    app_config_json_url = var.app_config_json_url
    bucket_name         = var.bucket_name
    stage               = var.stage
    }) : file("${path.module}/user_data_2.sh")

  tags = {
    Name = (
        count.index == 0 ? "s3-write-${var.name_tag}" : "s3-read-${var.name_tag}"
    )
  }
}

# Log Group
resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = "/app/${var.stage}/logs"
  retention_in_days = 7
}

# SNS Topic
resource "aws_sns_topic" "alerts" {
  name = "app-alerts-topic-${var.name_tag}"
}

# SNS Subscription
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Log Metric
resource "aws_cloudwatch_log_metric_filter" "error_filter" {
  name           = "app-error-filter-${var.name_tag}"
  log_group_name = aws_cloudwatch_log_group.app_log_group.name
  pattern        = "?ERROR ?Exception"

  metric_transformation {
    name      = "AppErrorCount"
    namespace = "AppLogs"
    value     = "1"
  }
}

# metric Alaram
resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name          = "app-error-alarm-${var.name_tag}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.error_filter.metric_transformation[0].name
  namespace           = "AppLogs"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.alerts.arn]
}