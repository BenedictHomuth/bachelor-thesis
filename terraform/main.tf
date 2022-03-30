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

resource "aws_instance" "test_ec2_amd64" {
  ami                    = "ami-00e76d391403fc721" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.terraform_public.id, aws_security_group.webserver_public.id, aws_security_group.kubernetes_public.id, aws_security_group.kubernetes_node_ports.id]
  key_name               = "terraform_test"
  user_data              = var.docker_setup

  tags = {
    Name = "amd64 K8s Worker"
  }
}

resource "aws_instance" "test_ec2_arm64" {
  ami                    = "ami-0e7c558a3101e32ba" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type          = "t4g.micro"
  vpc_security_group_ids = [aws_security_group.terraform_public.id, aws_security_group.webserver_public.id, aws_security_group.kubernetes_public.id, aws_security_group.kubernetes_node_ports.id]
  key_name               = "terraform_test"
  user_data              = var.kubernetes_setup

  tags = {
    Name = "arm64 K8s Master"
  }
}


# Security Group Terraform
resource "aws_security_group" "terraform_public" {
  name        = "terraform_public_ssh"
  description = "Allows for ssh into the ec2 test instance"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "public_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0 
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.terraform_public.id
}

resource "aws_security_group_rule" "public_in_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.terraform_public.id
}


# Security Group WEB
resource "aws_security_group" "webserver_public" {
  name        = "webserver_public"
  description = "Allows for http connections on port 80"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "public_web_in" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.webserver_public.id
}

resource "aws_security_group_rule" "public_web_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0 
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.webserver_public.id
}


# Security group kubernetes
resource "aws_security_group" "https_public" {
  name        = "https_public"
  description = "Allows for https connections on port 443"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "public_in_https" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.https_public.id
}

resource "aws_security_group_rule" "public_https_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0 
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.https_public.id
}


# Security group kubernetes
resource "aws_security_group" "kubernetes_public" {
  name        = "kubernetes_public"
  description = "Allows for tcp connections on port 6443"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "public_in_kubernetes" {
  type        = "ingress"
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.kubernetes_public.id
}

resource "aws_security_group_rule" "public_kubernetes_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0 
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.kubernetes_public.id
}


# Security group kubernetes node ports
resource "aws_security_group" "kubernetes_node_ports" {
  name        = "kubernetes_public_node_ports"
  description = "Allows for tcp node-port connections on port 30000 - 32767"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "public_in_kubernetes_node_ports" {
  type        = "ingress"
  from_port   = 32323
  to_port     = 32323
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.kubernetes_node_ports.id
}

resource "aws_security_group_rule" "public_kubernetes_out_node_ports" {
  type        = "egress"
  from_port   = 0
  to_port     = 0 
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.kubernetes_node_ports.id
}