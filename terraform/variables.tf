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

variable "kubernetes_control_plane_setup" {
  type = string
  default = <<-EOF
    #!/bin/bash

    set -ex

    URL=http://169.254.169.254/latest/meta-data/public-ipv4
    wget $URL -qO text.txt
    MASTERIP=`cat text.txt`
    rm text.txt
    
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --node-name k3s-master --tls-san $MASTERIP --node-external-ip=$MASTERIP
    # curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --node-taint CriticalAddonsOnly=true:NoExecute --node-name k3s-master-01 --tls-san $MASTERIP --node-external-ip=$MASTERIP

    
    aws ssm put-parameter --name '/k3s/control-plane-ip' --value $MASTERIP --type String --region eu-central-1 --overwrite

    # kubeconfig=$(sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/$MASTERIP/')
    kubeconfig=$(sudo cat /etc/rancher/k3s/k3s.yaml | sed "s/127.0.0.1/$MASTERIP/g")


    aws ssm put-parameter --name '/k3s/node-token' --value $(sudo cat /var/lib/rancher/k3s/server/node-token) --type String --region eu-central-1 --overwrite
    aws ssm put-parameter --name '/k3s/kubeconfig' --value "$kubeconfig" --type String --region eu-central-1 --overwrite
    
  EOF
  description = "Sets up kubernetes master node"
}

variable "kubernetes_worker_setup" {
  type = string
  default = <<-EOF
    #!/bin/bash

    set -ex
    sleep 40s
    TOKEN=$(aws ssm get-parameter --name '/k3s/node-token' --region eu-central-1 --output text --query Parameter.Value)
    MASTERIP=$(aws ssm get-parameter --name '/k3s/control-plane-ip' --region eu-central-1 --output text --query Parameter.Value)
    curl -sfL https://get.k3s.io | K3S_URL=https://$MASTERIP:6443 K3S_TOKEN=$TOKEN sh -
  EOF
  description = "Sets up kubernetes worker node"
}