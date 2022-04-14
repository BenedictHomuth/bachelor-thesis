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

module "iam_policies" {
  source = "./modules/iam"
}

module "elb" {
  source = "./modules/elastic-load-balancer"
  name = "k3s-load-balancer"
  security_groups = [ module.security_groups.web, module.security_groups.outbound_traffic]
  health_check_target = "HTTP:80/health"
}

locals {
  security_groups = [ module.security_groups.web, module.security_groups.kubernetes, module.security_groups.ssh, module.security_groups.outbound_traffic]
}

module "control_plane_k3s"{
  source = "./modules/k8s-Control-Plane"
  vpc_sg_ids = local.security_groups
  iam_instance_profile = module.iam_policies.iam_policy
  user_data = var.kubernetes_control_plane_setup
  instance_name = "k3s Control-Plane"
}

module "worker-asg-pool" {
  source = "./modules/k8s-Worker-ASG"
  vpc_sg_ids = local.security_groups
  iam_instance_profile = module.iam_policies.iam_policy
  user_data = var.kubernetes_worker_setup
  loadbalancer_id = [module.elb.loadbalancer_id]
}


