variable "region" {
    type = string
    description =  "Sets the aws region to deploy to"
    default = "eu-central-1"
}

variable "availability_zones" {
  type = list(string)
  description = "Set the availability zones to deploy to"
  default = ["eu-central-1a"]
}

variable "vpc_id" {
  type = string
  description = "ID of vpc to use"
  default =  "vpc-068569df5cf25a092" # Standard vpc
}

variable "vpc_sg_ids"{
  type = list(string)
  description = "Specify the seucrity group ids, that the instance will use"
  default = []
}

variable "internet_gateway" {
  type = string
  description = "ID of igw to use"
  default = "igw-095014f130674b374"
}

variable "lauch_config_name_prefix" {
  type = string
  description = "Prefix for worker nodes"
  default = "worker-"
}

variable "instance_type" {
  type = string
  description = "Sets the instance type to use"
  default = "t4g.micro" 
}

variable "ami_id" {
    type = string
    description = "Choose your Amazon Machine Image"
    default = "ami-0ab6e1041842e4895"
}

variable "user_data" {
  type  = string
  description = "Start up scripts etc."
  default = null
}

variable "elb_name" {
  type = string
  description = "Loadbalancer Name"
  default = "Worker LB"
}

variable "asg_min_instances" {
  type = number
  description = "Minimum amount of instances in the auto scaling group"
  default = 2
}

variable "asg_max_instances" {
  type = number
  description = "Maximum amount of instances in the auto scaling group"
  default = 4
}

variable "asg_desired_instances" {
  type = number
  description = "Desireds amount of instances in the auto scaling group"
  default = 2
}

variable "tag-name-asg" {
  type = string
  description = "Name of the ASG"
  default = "k3s Worker ASG"
}

variable "iam_instance_profile" {
  type = string
  description = "You can set instance 'iam' roles here"
  default = null
}