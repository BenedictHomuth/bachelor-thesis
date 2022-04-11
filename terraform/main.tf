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

module "control_plane_k3s"{
  source = "./modules/k8s-Control-Plane"
  user_data = var.kubernetes_control_plane_setup
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  instance_name = "Controler"
}

module "worker-asg-pool-with-loadbalancer" {
  source = "./modules/k8s-Worker-ASG"
  user_data = var.kubernetes_worker_setup  
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
}


