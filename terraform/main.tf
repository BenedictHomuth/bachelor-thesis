terraform {
  required_providers{
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3"{
    bucket = "tf-remote-state-bh"
    key    = "terraform/state/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}



#####
### SSM
###

resource "aws_ssm_parameter" "param_node_token" {
  type = "String"
  name = "/k3s/node-token"
  value = "inital"
}

resource "aws_ssm_parameter" "param_control_plane_ip" {
  type = "String"
  name = "/k3s/control-plane-ip"
  value = "initial"
}

resource "aws_ssm_parameter" "param_kubeconfig" {
  type = "String"
  name = "/k3s/kubeconfig"
  value = "initial"
}

resource "aws_iam_role" "ssm_role" {
  name = "test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm_instance_profile"
  role = "${aws_iam_role.ssm_role.name}"
}

resource "aws_iam_role_policy" "ssm_policy" {
  name = "ssm_policy"
  role = "${aws_iam_role.ssm_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ssm:DeleteParameter",
                "ssm:GetParameterHistory",
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "ssm:DeleteParameters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ssm:DescribeParameters",
            "Resource": "*"
        }
    ]
}
  EOF
}


resource "aws_instance" "k3s-master" {
  ami                    = "ami-0e7c558a3101e32ba" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type          = "t4g.micro"
  vpc_security_group_ids = [aws_security_group.allow_http.id, aws_security_group.allow_https.id, aws_security_group.allow_kubernetes.id, aws_security_group.allow_ssh.id]
  key_name               = "terraform_test"
  user_data              = var.kubernetes_master_setup
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  tags = {
    Name = "k3s-master"
  }
}

resource "aws_instance" "k3s-worker" {
  ami                    = "ami-0e7c558a3101e32ba" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type          = "t4g.micro"
  vpc_security_group_ids = [aws_security_group.allow_http.id, aws_security_group.allow_https.id, aws_security_group.allow_kubernetes.id, aws_security_group.allow_ssh.id]
  key_name               = "terraform_test"
  user_data              = var.kubernetes_worker_setup
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  tags = {
    Name = "k3s-worker"
  }
}




####
## SECURITY GROUPS
####
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound connections"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP Security Group"
  }
}

resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "Allow https connections"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow https Security Group"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh connections"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow ssh Security Group"
  }
}

resource "aws_security_group" "allow_kubernetes" {
  name        = "allow_kubernetes"
  description = "Allow tcp/6443 connections"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow k8s/tcp/6443 Security Group"
  }
}

