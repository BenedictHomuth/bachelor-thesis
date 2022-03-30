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

variable "kubernetes_setup" {
  type = string
  default = <<-EOF
    #!/bin/bash
    #  -ex -> exits, when error accours and shows log
    set -ex
    sudo yum install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user

    URL=http://169.254.169.254/latest/meta-data/public-ipv4
    wget $URL -qO text.txt
    MASTERIP=`cat text.txt`
    rm text.txt
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --node-taint CriticalAddonsOnly=true:NoExecute --node-name k3s-master-01 --tls-san $MASTERIP --node-external-ip=$MASTERIP
  EOF
  description = "Sets up kubernetes master and docker"
}