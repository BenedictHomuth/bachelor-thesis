variable "vpc_id" {
  type        = string
  default     = "vpc-068569df5cf25a092"
  description = "Standard VPC deployed in terraform test"
}

variable "docker_setup" {
  type = string
  default = <<-EOF
    #!/bin/bash
    #  -ex -> exits, when error accours and shows log
    set -ex
    sudo yum install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user
  EOF
  description = "Sets up docker, starts it and adds user (ec2-user) to docker group"
}
