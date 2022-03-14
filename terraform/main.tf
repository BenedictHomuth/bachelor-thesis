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
  vpc_security_group_ids = [aws_security_group.terraform_public.id]
  key_name               = "terraform_test"
  user_data              = var.docker_setup

  tags = {
    Name = "EC2 Test Instance amd64"
  }
}

resource "aws_instance" "test_ec2_arm64" {
  ami                    = "ami-0e7c558a3101e32ba" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type          = "t4g.micro"
  vpc_security_group_ids = [aws_security_group.terraform_public.id]
  key_name               = "terraform_test"
  user_data              = var.docker_setup

  tags = {
    Name = "EC2 Test Instance arm64"
  }
}


# Creating a security group
resource "aws_security_group" "terraform_public" {
  name        = "terraform_public_ssh"
  description = "Allows for ssh into the ec2 test instance"
  vpc_id      = var.vpc_id
}

# Rules for the Security Group
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
