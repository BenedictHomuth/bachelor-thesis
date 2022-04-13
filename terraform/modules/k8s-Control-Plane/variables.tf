variable "region" {
    type = string
    description =  "Sets the aws region to deploy to"
    default = "eu-central-1"
}

variable "availability_zone" {
  type = string
  description = "Set the availability zones to deploy to"
  default = "eu-central-1a"
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

variable "iam_instance_profile" {
  type = string
  description = "You can set instance 'iam' roles here"
  default = null
}

variable "instance_name" {
  type = string
  default = null
}