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

module "security_groups" {
  source = "./modules/security-groups"
}

module "ssm_policies" {
  source = "./modules/ssm"
}

locals {
  security_groups =[ module.security_groups.sg_web, module.security_groups.sg_kubernetes, module.security_groups.sg_ssh, module.security_groups.outbound_traffic]
}

module "control_plane_k3s"{
  source = "./modules/k8s-Control-Plane"
  vpc_sg_ids = local.security_groups
  user_data = var.kubernetes_control_plane_setup
  iam_instance_profile = module.ssm_policies.ssm_parameter_policy
  instance_name = "Controler"
}

module "worker-asg-pool-with-loadbalancer" {
  source = "./modules/k8s-Worker-ASG"
  user_data = var.kubernetes_worker_setup  
  vpc_sg_ids = local.security_groups
  iam_instance_profile = module.ssm_policies.ssm_parameter_policy
}


