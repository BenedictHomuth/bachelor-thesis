resource "aws_elb" "loadbalancer" {
  name = var.name
  security_groups = var.security_groups
  availability_zones = var.availability_zones

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 3
    interval = 300
    target = var.health_check_target
  }

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }

}