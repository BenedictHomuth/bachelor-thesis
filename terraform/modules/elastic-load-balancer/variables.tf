variable "availability_zones" {
  type = list(string)
  description = "AZ's of the loadbalancer"
  default = ["eu-central-1a"]
}

variable "security_groups" {
  type =list(string)
  description = "List of SG to apply"
  default = []
}

variable "health_check_target" {
  type = string
  description = "Endpoint to check if instance is healthy"
  default = null
}

variable "name" {
  type = string
  default = "Elastic Load Balancer"
}