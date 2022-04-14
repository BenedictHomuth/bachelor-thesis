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

resource "aws_launch_configuration" "worker" {
  name_prefix = var.lauch_config_name_prefix

  image_id = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile = var.iam_instance_profile

  security_groups = var.vpc_sg_ids
  associate_public_ip_address = true

  user_data = var.user_data

  lifecycle {
    create_before_destroy = true
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
  load_balancers = var.loadbalancer_id

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