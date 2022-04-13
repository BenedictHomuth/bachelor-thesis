resource "aws_security_group" "web_traffic" {
  name        = "web_traffic"
  description = "Allow HTTP and HTTPS inbound connections"
  vpc_id = var.vpc_id

  tags = {
    Name = "Web Traffic 80, 443"
  }
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_traffic.id
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_traffic.id
}

resource "aws_security_group" "kubernetes" {
  name        = "kubernetes_ports"
  description = "Opens the required Kubernetes ports 6443 (kubectl), 8472 (flannel overlay network)"
  vpc_id = var.vpc_id

  tags = {
    Name = "Kubernetes Ports"
  }
}

resource "aws_security_group_rule" "kubectl" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kubernetes.id
}

resource "aws_security_group_rule" "flannel_overlay_network" {
  type              = "ingress"
  from_port         = 8472
  to_port           = 8472
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kubernetes.id
}

resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Allow ssh connections on port 22"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SSH connection"
  }
}

resource "aws_security_group" "outbound_traffic" {
  name        = "outbound_traffic"
  description = "Opens all ports and protocols for outgoing traffic"
  vpc_id = var.vpc_id

  tags = {
    Name = "Outbound Traffic"
  }
}

resource "aws_security_group_rule" "all_traffic_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.outbound_traffic.id
}