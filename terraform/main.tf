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

####
## SECURITY GROUPS
####
resource "aws_security_group" "web_traffic" {
  name        = "web_traffic"
  description = "Allow HTTP and HTTPS inbound connections"
  vpc_id = var.vpc_id

  tags = {
    Name = "Web Traffic 80, 443"
  }
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_traffic.id
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_traffic.id
}

resource "aws_security_group" "kubernetes" {
  name        = "kubernetes_ports"
  description = "Opens the required Kubernetes ports 6443 (kubectl), 8472 (flannel overlay network)"
  vpc_id = var.vpc_id

  tags = {
    Name = "Kubernetes Ports"
  }
}

resource "aws_security_group_rule" "kubectl" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kubernetes.id
}

resource "aws_security_group_rule" "flannel_overlay_network" {
  type              = "ingress"
  from_port         = 8472
  to_port           = 8472
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kubernetes.id
}

resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Allow ssh connections on port 22"
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
    Name = "SSH connection"
  }
}

locals {
  nodeSecurityGroups = [aws_security_group.web_traffic.id, aws_security_group.kubernetes.id, aws_security_group.ssh.id]
}

resource "aws_instance" "k3s-master" {
  ami                    = "ami-0e7c558a3101e32ba" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type          = "t4g.micro"
  vpc_security_group_ids = local.nodeSecurityGroups
  key_name               = "terraform_test"
  user_data              = var.kubernetes_master_setup
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  tags = {
    Name = "k3s-master"
  }
}

resource "aws_instance" "k3s-worker-one" {
  ami                    = "ami-0e7c558a3101e32ba" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type          = "t4g.micro"
  vpc_security_group_ids = local.nodeSecurityGroups
  key_name               = "terraform_test"
  user_data              = var.kubernetes_worker_setup
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  tags = {
    Name = "k3s-worker-one"
  }
}

resource "aws_instance" "k3s-worker-two" {
  ami                    = "ami-0e7c558a3101e32ba" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type          = "t4g.micro"
  vpc_security_group_ids = local.nodeSecurityGroups
  key_name               = "terraform_test"
  user_data              = var.kubernetes_worker_setup
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  tags = {
    Name = "k3s-worker-two"
  }
}