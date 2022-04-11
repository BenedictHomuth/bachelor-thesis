provider "aws" {
  region = var.region
}

resource "aws_route_table" "my_vpc_public" {
    vpc_id = var.vpc_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = var.internet_gateway
    }

    tags = {
        Name = "Public Subnets Route Table for My VPC"
    }
}

# Security Group
resource "aws_security_group" "asg_allow_http" {
  name        = "asg_allow_http"
  description = "Allow HTTP inbound connections"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "Allow HTTP Security Group"
  }
}

resource "aws_security_group" "asg_allow_https" {
  name        = "asg_allow_https"
  description = "Allow https connections"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "Allow https Security Group"
  }
}

resource "aws_security_group" "asg_allow_ssh" {
  name        = "asg_allow_ssh"
  description = "Allow ssh connections"
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
    Name = "Allow ssh Security Group"
  }
}

resource "aws_security_group" "asg_allow_kubernetes" {
  name        = "asg_allow_kubernetes"
  description = "Allow tcp/6443 connections"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 6443
    to_port     = 6443
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
    Name = "Allow k8s/tcp/6443 Security Group"
  }
}


resource "aws_launch_configuration" "worker" {
  name_prefix = var.lauch_config_name_prefix

  image_id = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile = var.iam_instance_profile

  security_groups = [ aws_security_group.asg_allow_http.id, aws_security_group.asg_allow_https.id, aws_security_group.asg_allow_ssh.id, aws_security_group.asg_allow_kubernetes.id]
  associate_public_ip_address = true

  user_data = var.user_data

  lifecycle {
    create_before_destroy = true
  }
}

# Load Balancing
resource "aws_security_group" "sg_elb_http" {
  name        = "sg_elb_http"
  description = "Allow HTTP traffic to instances through Elastic Load Balancer"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "Allow HTTP through ELB Security Group"
  }
}

resource "aws_elb" "loadbalancer" {
  name = "worker-elb"
  security_groups = [
    aws_security_group.sg_elb_http.id
  ]
  availability_zones = var.availability_zones

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 10
    timeout = 3
    interval = 300
    target = "HTTP:80/"
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }

}

resource "aws_autoscaling_group" "asg_worker" {
  name = "${aws_launch_configuration.worker.name}-asg"
  availability_zones = var.availability_zones

  min_size             = var.asg_min_instances
  desired_capacity     = var.asg_desired_instances
  max_size             = var.asg_max_instances
  
  health_check_type    = "ELB"
  health_check_grace_period = 3000
  load_balancers = [
    aws_elb.loadbalancer.id
  ]

  launch_configuration = aws_launch_configuration.worker.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = var.tag-name-asg
    propagate_at_launch = true
  }

}

# Scaling UP policies and metrics
resource "aws_autoscaling_policy" "k3s_worker_policy_up" {
  name = "k3s_worker_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.asg_worker.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "k3s_worker_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg_worker.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.k3s_worker_policy_up.arn ]
}


# Scaling DOWN policies and metrics
resource "aws_autoscaling_policy" "k3s_worker_policy_down" {
  name = "k3s_worker_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.asg_worker.name
}

resource "aws_cloudwatch_metric_alarm" "k3s_worker_cpu_alarm_down" {
  alarm_name = "k3s_worker_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg_worker.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.k3s_worker_policy_down.arn ]
}