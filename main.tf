provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region

}


resource "aws_ssm_parameter" "cloudwatch" {
  name  = "AmazonCloudWatch-linux"
  type  = "String"
  value = file("rule.json")
}


resource "aws_iam_role_policy" "cloudwatch" {
  name = "CW-role-policy"
  role = aws_iam_role.cloudwatch.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter"
        ],
        "Resource" : "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
      }
    ]
  })
}

resource "aws_iam_role" "cloudwatch" {
  name        = "cloudwatch_role"
  description = "The role for pushing metric in cloudwatch"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "cloudwatch_profile"
  role = aws_iam_role.cloudwatch.name
}

data "aws_ami" "latest_ami_built_by_packer" {
  owners      = [data.aws_caller_identity.current.account_id]
  most_recent = true
  filter {
    name   = "name"
    values = ["ami_generated_by_packer*"]
  }
}

resource "aws_launch_template" "for_asg" {

  image_id      = data.aws_ami.latest_ami_built_by_packer.id
  instance_type = var.instance_type
  name          = "LaunchTemplateForASG"
  tags = {
    "Name" = "Instance from ${data.aws_ami.latest_ami_built_by_packer.id} "
  }
  user_data = base64encode(<<EOF
  #!/bin/bash
  yum install amazon-cloudwatch-agent -y
  cd /opt/aws/amazon-cloudwatch-agent/bin
  ./amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 c ssm:AmazonCloudWatch-linux -s
  systemctl enable amazon-cloudwatch-agent
  systemctl start amazon-cloudwatch-agent
  EOF
  )
  key_name = var.key_name
  iam_instance_profile {
    name = "cloudwatch_profile"
  }
}


resource "aws_autoscaling_group" "asg" {
  name               = "MyTestASG"
  desired_capacity   = 2
  max_size           = 5
  min_size           = 1
  availability_zones = data.aws_availability_zones.available.names
  launch_template {
    id      = aws_launch_template.for_asg.id
    version = "$Latest"
  }
}






data "aws_availability_zones" "available" {
  state = "available"
}

output "ami_name" {
  value = data.aws_ami.latest_ami_built_by_packer.id
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}

output "availabilityzone" {
  value = data.aws_availability_zones.available.names
}
#arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
